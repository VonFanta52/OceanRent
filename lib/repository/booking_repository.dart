import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/models/maintenance_block_model.dart';

class BookingRepository {
  BookingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const List<String> _activeBookingStatuses = [
    BookingModel.statusPending,
    BookingModel.statusConfirmed,
  ];

  static const int _cancellationMinHours = 24;

  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _maintenanceBlocksCollection =>
      _firestore.collection('maintenance_blocks');

  CollectionReference<Map<String, dynamic>> get _bookingDateLocksCollection =>
      _firestore.collection('booking_date_locks');

  Stream<List<BookingModel>> watchBookings() {
    return _bookingsCollection.snapshots().map(_mapBookingSnapshot);
  }

  Stream<List<BookingModel>> watchBookingsByUser(String userId) {
    return _bookingsCollection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map(_mapBookingSnapshot);
  }

  List<BookingModel> _mapBookingSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();

    bookings.sort((a, b) {
      final firstDate = a.createdAt ?? a.startDate;
      final secondDate = b.createdAt ?? b.startDate;

      return secondDate.compareTo(firstDate);
    });

    return bookings;
  }

  Future<BookingModel> createBooking({
    required String boatId,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required int crewCount,
    required double depositAmount,
  }) async {
    final normalizedStartDate = _startOfDay(startDate);
    final normalizedEndDate = _startOfDay(endDate);

    if (normalizedEndDate.isBefore(normalizedStartDate)) {
      throw Exception('La fecha final no puede ser anterior a la inicial.');
    }

    if (crewCount <= 0) {
      throw Exception('El número de tripulantes debe ser mayor que 0.');
    }

    final hasBookingOverlap = await _hasActiveBookingOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    if (hasBookingOverlap) {
      throw Exception('El barco ya tiene una reserva en ese rango de fechas.');
    }

    final hasMaintenanceOverlap = await _hasMaintenanceOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    if (hasMaintenanceOverlap) {
      throw Exception(
        'El barco no está disponible por mantenimiento en ese rango de fechas.',
      );
    }

    final bookingRef = _bookingsCollection.doc();
    final selectedDates = _datesInRange(normalizedStartDate, normalizedEndDate);
    final calculatedDepositAmount = await _calculateDepositAmount(
      boatId: boatId,
      selectedDays: selectedDates.length,
      fallbackDepositAmount: depositAmount,
    );

    return _firestore.runTransaction<BookingModel>((transaction) async {
      final lockRefs = selectedDates
          .map((date) => _bookingDateLocksCollection.doc(_lockId(boatId, date)))
          .toList();

      final lockSnapshots = await Future.wait(lockRefs.map(transaction.get));

      final hasLockedDate = lockSnapshots.any((snapshot) => snapshot.exists);

      if (hasLockedDate) {
        throw Exception(
          'El barco acaba de ser reservado en alguna de las fechas seleccionadas.',
        );
      }

      final booking = BookingModel(
        id: bookingRef.id,
        boatId: boatId,
        userId: userId,
        startDate: normalizedStartDate,
        endDate: normalizedEndDate,
        crewCount: crewCount,
        status: BookingModel.statusPending,
        depositAmount: calculatedDepositAmount,
        depositPaymentIntentId: '',
        depositStatus: BookingModel.depositStatusHeld,
        rentalPaymentIntentId: '',
      );

      transaction.set(bookingRef, {...booking.toMap(), 'id': bookingRef.id});

      for (int i = 0; i < lockRefs.length; i++) {
        transaction.set(lockRefs[i], {
          'booking_id': bookingRef.id,
          'boat_id': boatId,
          'date': Timestamp.fromDate(selectedDates[i]),
          'date_key': _dateKey(selectedDates[i]),
          'status': BookingModel.statusPending,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return booking;
    });
  }

  Future<void> confirmBooking(String bookingId) async {
    final bookingRef = _bookingsCollection.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('La reserva no existe.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.status == BookingModel.statusCancelled) {
        throw Exception('No se puede confirmar una reserva cancelada.');
      }

      final selectedDates = _datesInRange(booking.startDate, booking.endDate);

      transaction.update(bookingRef, {
        'status': BookingModel.statusConfirmed,
        'updated_at': FieldValue.serverTimestamp(),
      });

      for (final date in selectedDates) {
        final lockRef = _bookingDateLocksCollection.doc(
          _lockId(booking.boatId, date),
        );

        transaction.set(lockRef, {
          'booking_id': booking.id,
          'boat_id': booking.boatId,
          'date': Timestamp.fromDate(date),
          'date_key': _dateKey(date),
          'status': BookingModel.statusConfirmed,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> cancelBooking(String bookingId, String currentUserId) async {
    final bookingRef = _bookingsCollection.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('La reserva no existe.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.userId != currentUserId) {
        throw Exception('No tienes permiso para cancelar esta reserva.');
      }

      if (booking.status == BookingModel.statusCancelled) {
        return;
      }

      final hoursUntilStart = booking.startDate
          .difference(DateTime.now())
          .inHours;

      if (hoursUntilStart < _cancellationMinHours) {
        throw Exception(
          'No se puede cancelar una reserva con menos de $_cancellationMinHours horas de antelación.',
        );
      }

      await _performCancellation(transaction, bookingRef, booking);
    });
  }

  /// Cancela una reserva como administrador, sin límite de antelación.
  Future<void> cancelBookingAsAdmin(String bookingId) async {
    final bookingRef = _bookingsCollection.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('La reserva no existe.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.status == BookingModel.statusCancelled) {
        return;
      }

      await _performCancellation(transaction, bookingRef, booking);
    });
  }

  Future<void> releaseDeposit(String bookingId) async {
    if (bookingId.trim().isEmpty) {
      throw Exception('No se pudo identificar la reserva.');
    }

    final bookingRef = _bookingsCollection.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('La reserva no existe.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.status == BookingModel.statusCancelled) {
        throw Exception(
          'No se puede devolver la fianza de una reserva cancelada.',
        );
      }

      if (booking.depositStatus == BookingModel.depositStatusReleased) {
        return;
      }

      if (booking.depositStatus != BookingModel.depositStatusHeld) {
        throw Exception('Esta fianza no esta retenida actualmente.');
      }

      transaction.update(bookingRef, {
        'deposit_status': BookingModel.depositStatusReleased,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> captureDeposit(String bookingId) async {
    if (bookingId.trim().isEmpty) {
      throw Exception('No se pudo identificar la reserva.');
    }

    final bookingRef = _bookingsCollection.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('La reserva no existe.');
      }

      final booking = BookingModel.fromFirestore(bookingSnapshot);

      if (booking.status == BookingModel.statusCancelled) {
        throw Exception(
          'No se puede cobrar la fianza de una reserva cancelada.',
        );
      }

      if (booking.depositStatus == BookingModel.depositStatusCaptured) {
        return;
      }

      if (booking.depositStatus != BookingModel.depositStatusHeld) {
        throw Exception('Esta fianza no esta retenida actualmente.');
      }

      transaction.update(bookingRef, {
        'deposit_status': BookingModel.depositStatusCaptured,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Lógica común de cancelación: actualiza el estado en Firestore
  /// y elimina los locks de fechas asociados.
  Future<void> _performCancellation(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> bookingRef,
    BookingModel booking,
  ) async {
    final selectedDates = _datesInRange(booking.startDate, booking.endDate);

    transaction.update(bookingRef, {
      'status': BookingModel.statusCancelled,
      'deposit_status': BookingModel.depositStatusReleased,
      'updated_at': FieldValue.serverTimestamp(),
    });

    for (final date in selectedDates) {
      final lockRef = _bookingDateLocksCollection.doc(
        _lockId(booking.boatId, date),
      );

      transaction.delete(lockRef);
    }
  }

  Future<void> createMaintenanceBlock({
    required String boatId,
    required String createdBy,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final normalizedStartDate = _startOfDay(startDate);
    final normalizedEndDate = _startOfDay(endDate);

    if (boatId.trim().isEmpty) {
      throw Exception('Selecciona un barco para bloquear fechas.');
    }

    if (createdBy.trim().isEmpty) {
      throw Exception('No se pudo identificar al administrador.');
    }

    if (normalizedEndDate.isBefore(normalizedStartDate)) {
      throw Exception('La fecha final no puede ser anterior a la inicial.');
    }

    final hasBookingOverlap = await _hasActiveBookingOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    if (hasBookingOverlap) {
      throw Exception(
        'No puedes bloquear fechas que ya tienen reservas activas.',
      );
    }

    final hasMaintenanceOverlap = await _hasMaintenanceOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    if (hasMaintenanceOverlap) {
      throw Exception(
        'Ya existe un bloqueo de mantenimiento en ese rango de fechas.',
      );
    }

    final maintenanceRef = _maintenanceBlocksCollection.doc();

    await maintenanceRef.set({
      'id': maintenanceRef.id,
      'boat_id': boatId,
      'start_date': Timestamp.fromDate(normalizedStartDate),
      'end_date': Timestamp.fromDate(normalizedEndDate),
      'reason': reason.trim().isEmpty ? 'Mantenimiento' : reason.trim(),
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MaintenanceBlockModel>> watchMaintenanceBlocksByBoat(
    String boatId,
  ) {
    return _maintenanceBlocksCollection
        .where('boat_id', isEqualTo: boatId)
        .snapshots()
        .map((snapshot) {
          final blocks = snapshot.docs
              .map(MaintenanceBlockModel.fromFirestore)
              .toList();

          blocks.sort((a, b) => a.startDate.compareTo(b.startDate));

          return blocks;
        });
  }

  Future<void> deleteMaintenanceBlock(String blockId) async {
    if (blockId.trim().isEmpty) {
      throw Exception('No se pudo identificar el bloqueo.');
    }

    await _maintenanceBlocksCollection.doc(blockId).delete();
  }

  Future<bool> isBoatAvailable({
    required String boatId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = _startOfDay(startDate);
    final normalizedEndDate = _startOfDay(endDate);

    final hasBookingOverlap = await _hasActiveBookingOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    if (hasBookingOverlap) {
      return false;
    }

    final hasMaintenanceOverlap = await _hasMaintenanceOverlap(
      boatId: boatId,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    return !hasMaintenanceOverlap;
  }

  Future<Set<DateTime>> getUnavailableDates(String boatId) async {
    final unavailableDates = <DateTime>{};

    final lockSnapshot = await _bookingDateLocksCollection
        .where('boat_id', isEqualTo: boatId)
        .get();

    for (final doc in lockSnapshot.docs) {
      final data = doc.data();
      final status = data['status'];

      if (!_activeBookingStatuses.contains(status)) {
        continue;
      }

      final date = _dateFromTimestamp(data['date']);

      if (date != null) {
        unavailableDates.add(date);
      }
    }

    final maintenanceSnapshot = await _maintenanceBlocksCollection
        .where('boat_id', isEqualTo: boatId)
        .get();

    for (final doc in maintenanceSnapshot.docs) {
      final data = doc.data();

      final startDate = _dateFromTimestamp(data['start_date']);
      final endDate = _dateFromTimestamp(data['end_date']);

      if (startDate == null || endDate == null) {
        continue;
      }

      unavailableDates.addAll(_datesInRange(startDate, endDate));
    }

    return unavailableDates;
  }

  Future<bool> _hasActiveBookingOverlap({
    required String boatId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _bookingDateLocksCollection
        .where('boat_id', isEqualTo: boatId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];

      if (!_activeBookingStatuses.contains(status)) {
        continue;
      }

      final lockedDate = _dateFromTimestamp(data['date']);

      if (lockedDate == null) {
        continue;
      }

      if (_rangesOverlap(
        startA: startDate,
        endA: endDate,
        startB: lockedDate,
        endB: lockedDate,
      )) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _hasMaintenanceOverlap({
    required String boatId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _maintenanceBlocksCollection
        .where('boat_id', isEqualTo: boatId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final maintenanceStartDate = _dateFromTimestamp(data['start_date']);
      final maintenanceEndDate = _dateFromTimestamp(data['end_date']);

      if (maintenanceStartDate == null || maintenanceEndDate == null) {
        continue;
      }

      if (_rangesOverlap(
        startA: startDate,
        endA: endDate,
        startB: maintenanceStartDate,
        endB: maintenanceEndDate,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _rangesOverlap({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    final normalizedStartA = _startOfDay(startA);
    final normalizedEndA = _startOfDay(endA);
    final normalizedStartB = _startOfDay(startB);
    final normalizedEndB = _startOfDay(endB);

    return !normalizedEndA.isBefore(normalizedStartB) &&
        !normalizedStartA.isAfter(normalizedEndB);
  }

  List<DateTime> _datesInRange(DateTime startDate, DateTime endDate) {
    final normalizedStartDate = _startOfDay(startDate);
    final normalizedEndDate = _startOfDay(endDate);

    final totalDays = normalizedEndDate.difference(normalizedStartDate).inDays;

    return List.generate(
      totalDays + 1,
      (index) => normalizedStartDate.add(Duration(days: index)),
    );
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<double> _calculateDepositAmount({
    required String boatId,
    required int selectedDays,
    required double fallbackDepositAmount,
  }) async {
    final boatSnapshot = await _firestore.collection('boats').doc(boatId).get();
    final boatData = boatSnapshot.data();
    final pricePerDay = (boatData?['price_per_day'] as num?)?.toDouble();

    if (pricePerDay == null || pricePerDay <= 0 || selectedDays <= 0) {
      if (fallbackDepositAmount > 0) {
        return fallbackDepositAmount;
      }

      throw Exception('No se pudo calcular la fianza de la reserva.');
    }

    final depositAmount = pricePerDay * selectedDays * 0.10;

    if (depositAmount <= 0) {
      return fallbackDepositAmount;
    }

    return double.parse(depositAmount.toStringAsFixed(2));
  }

  DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return _startOfDay(value.toDate());
    }

    return null;
  }

  String _lockId(String boatId, DateTime date) {
    return '${boatId}_${_dateKey(date)}';
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }
}
