import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  static const String statusPending = 'pendiente';
  static const String statusConfirmed = 'confirmada';
  static const String statusCancelled = 'cancelada';

  static const String depositStatusHeld = 'held';
  static const String depositStatusReleased = 'released';
  static const String depositStatusCaptured = 'captured';

  static const String chatStatusOpen = 'open';
  static const String chatStatusClosed = 'closed';

  final String id;
  final String boatId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int crewCount;
  final String status;
  final double depositAmount;
  final String depositPaymentIntentId;
  final String depositStatus;
  final String rentalPaymentIntentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String chatStatus;
  final DateTime? chatClosedAt;
  final String chatClosedBy;

  const BookingModel({
    required this.id,
    required this.boatId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.crewCount,
    required this.status,
    required this.depositAmount,
    required this.depositPaymentIntentId,
    required this.depositStatus,
    required this.rentalPaymentIntentId,
    this.createdAt,
    this.updatedAt,
    this.chatStatus = chatStatusOpen,
    this.chatClosedAt,
    this.chatClosedBy = '',
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = _dateFromTimestamp(data['start_date'], 'start_date');
    final endDate = _dateFromTimestamp(data['end_date'], 'end_date');

    return BookingModel(
      id: doc.id,
      boatId: data['boat_id'] ?? '',
      userId: data['user_id'] ?? '',
      startDate: startDate,
      endDate: endDate,
      crewCount: data['crew_count'] ?? 1,
      status: data['status'] ?? statusPending,
      depositAmount: (data['deposit_amount'] ?? 0).toDouble(),
      depositPaymentIntentId: data['deposit_payment_intent_id'] ?? '',
      depositStatus: data['deposit_status'] ?? depositStatusHeld,
      rentalPaymentIntentId: data['rental_payment_intent_id'] ?? '',
      createdAt: _nullableDateFromTimestamp(data['created_at']),
      updatedAt: _nullableDateFromTimestamp(data['updated_at']),
      chatStatus: data['chat_status'] ?? chatStatusOpen,
      chatClosedAt: _nullableDateFromTimestamp(data['chat_closed_at']),
      chatClosedBy: data['chat_closed_by'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'boat_id': boatId,
      'user_id': userId,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'crew_count': crewCount,
      'status': status,
      'deposit_amount': depositAmount,
      'deposit_payment_intent_id': depositPaymentIntentId,
      'deposit_status': depositStatus,
      'rental_payment_intent_id': rentalPaymentIntentId,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      if (chatStatus != chatStatusOpen) 'chat_status': chatStatus,
      if (chatClosedAt != null)
        'chat_closed_at': Timestamp.fromDate(chatClosedAt!),
      if (chatClosedBy.isNotEmpty) 'chat_closed_by': chatClosedBy,
    };
  }

  bool get isChatClosed => chatStatus == chatStatusClosed;

  BookingModel copyWith({
    String? id,
    String? boatId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? crewCount,
    String? status,
    double? depositAmount,
    String? depositPaymentIntentId,
    String? depositStatus,
    String? rentalPaymentIntentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? chatStatus,
    DateTime? chatClosedAt,
    String? chatClosedBy,
  }) {
    return BookingModel(
      id: id ?? this.id,
      boatId: boatId ?? this.boatId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      crewCount: crewCount ?? this.crewCount,
      status: status ?? this.status,
      depositAmount: depositAmount ?? this.depositAmount,
      depositPaymentIntentId:
          depositPaymentIntentId ?? this.depositPaymentIntentId,
      depositStatus: depositStatus ?? this.depositStatus,
      rentalPaymentIntentId:
          rentalPaymentIntentId ?? this.rentalPaymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatStatus: chatStatus ?? this.chatStatus,
      chatClosedAt: chatClosedAt ?? this.chatClosedAt,
      chatClosedBy: chatClosedBy ?? this.chatClosedBy,
    );
  }

  static DateTime _dateFromTimestamp(dynamic value, String fieldName) {
    if (value is Timestamp) {
      return value.toDate();
    }

    throw StateError('Reserva $fieldName invalida.');
  }

  static DateTime? _nullableDateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
