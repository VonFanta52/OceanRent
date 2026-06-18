import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/models/maintenance_block_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/repository/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(FirebaseFirestore.instance);
});

final bookingNotifierProvider = ChangeNotifierProvider<BookingNotifier>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repository);
});

final bookingsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((
  ref,
) {
  final authState = ref.watch(authStateChangesProvider);
  final repository = ref.watch(bookingRepositoryProvider);

  if (!authState.hasValue || authState.value == null) {
    return const Stream.empty();
  }

  return repository.watchBookings().handleError(
    (error, _) {},
    test: (e) => e.toString().contains('permission-denied'),
  );
});

final userBookingsStreamProvider = StreamProvider.autoDispose
    .family<List<BookingModel>, String>((ref, userId) {
      final authState = ref.watch(authStateChangesProvider);
      final repository = ref.watch(bookingRepositoryProvider);

      if (!authState.hasValue || authState.value == null) {
        return const Stream.empty();
      }

      return repository
          .watchBookingsByUser(userId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });

final maintenanceBlocksByBoatProvider = StreamProvider.autoDispose
    .family<List<MaintenanceBlockModel>, String>((ref, boatId) {
      final repository = ref.watch(bookingRepositoryProvider);

      if (boatId.trim().isEmpty) {
        return const Stream.empty();
      }

      return repository
          .watchMaintenanceBlocksByBoat(boatId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });

class BookingNotifier extends ChangeNotifier {
  BookingNotifier(this._bookingRepository);

  final BookingRepository _bookingRepository;

  bool _isLoading = false;
  String? _errorMessage;
  BookingModel? _currentBooking;
  Set<DateTime> _unavailableDates = {};

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  BookingModel? get currentBooking => _currentBooking;

  Set<DateTime> get unavailableDates => _unavailableDates;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loadUnavailableDates(String boatId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _unavailableDates = await _bookingRepository.getUnavailableDates(boatId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking({
    required String boatId,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required int crewCount,
    required double depositAmount,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentBooking = await _bookingRepository.createBooking(
        boatId: boatId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        crewCount: crewCount,
        depositAmount: depositAmount,
      );

      _unavailableDates = await _bookingRepository.getUnavailableDates(boatId);

      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmBooking(String bookingId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.confirmBooking(bookingId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(String bookingId, String currentUserId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.cancelBooking(bookingId, currentUserId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancelacion por parte del admin, sin restricciones de tiempo
  Future<bool> cancelBookingAsAdmin(String bookingId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.cancelBookingAsAdmin(bookingId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> releaseDeposit(String bookingId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.releaseDeposit(bookingId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> captureDeposit(String bookingId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.captureDeposit(bookingId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createMaintenanceBlock({
    required String boatId,
    required String createdBy,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.createMaintenanceBlock(
        boatId: boatId,
        createdBy: createdBy,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );

      _unavailableDates = await _bookingRepository.getUnavailableDates(boatId);

      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMaintenanceBlock({
    required String blockId,
    required String boatId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingRepository.deleteMaintenanceBlock(blockId);
      _unavailableDates = await _bookingRepository.getUnavailableDates(boatId);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isBoatAvailable({
    required String boatId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _bookingRepository.isBoatAvailable(
        boatId: boatId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  bool isDateUnavailable(DateTime date) {
    final normalizedDate = _startOfDay(date);

    return _unavailableDates.any(
      (unavailableDate) => _isSameDay(unavailableDate, normalizedDate),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime firstDate, DateTime secondDate) {
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
