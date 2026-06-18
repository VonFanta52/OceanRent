import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de bloque de mantenimiento para un barco
class MaintenanceBlockModel {
  final String id;
  final String boatId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String createdBy;
  final DateTime? createdAt;

  const MaintenanceBlockModel({
    required this.id,
    required this.boatId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdBy,
    this.createdAt,
  });
  //
  factory MaintenanceBlockModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return MaintenanceBlockModel(
      id: (data['id'] as String?) ?? doc.id,
      boatId: (data['boat_id'] as String?) ?? '',
      startDate: _dateFromTimestamp(data['start_date']) ?? DateTime.now(),
      endDate: _dateFromTimestamp(data['end_date']) ?? DateTime.now(),
      reason: (data['reason'] as String?) ?? 'Mantenimiento',
      createdBy: (data['created_by'] as String?) ?? '',
      createdAt: _dateFromTimestamp(data['created_at']),
    );
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
