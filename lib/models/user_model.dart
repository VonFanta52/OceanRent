import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, customer }

class NauticalLicenseStatus {
  static const String none = 'none';
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String rejected = 'rejected';

  const NauticalLicenseStatus._();
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final DateTime? birthDate;
  final UserRole role;
  final NauticalLicense? nauticalLicense;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.role,
    this.nauticalLicense,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final rawBirthDate = map['birth_date'];
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      birthDate: rawBirthDate is Timestamp ? rawBirthDate.toDate() : null,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.customer,
      nauticalLicense: map['nautical_license'] != null
          ? NauticalLicense.fromMap(map['nautical_license'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'surname': surname,
    if (birthDate != null) 'birth_date': Timestamp.fromDate(birthDate!),
    'role': role == UserRole.admin ? 'admin' : 'customer',
    if (nauticalLicense != null) 'nautical_license': nauticalLicense!.toMap(),
    'created_at': FieldValue.serverTimestamp(),
  };
}

class NauticalLicense {
  final String type;
  final String documentUrl;
  final String status;
  final String? rejectionReason;

  const NauticalLicense({
    required this.type,
    required this.documentUrl,
    required this.status,
    this.rejectionReason,
  });

  factory NauticalLicense.fromMap(Map<String, dynamic> map) {
    return NauticalLicense(
      type: map['type'] ?? 'none',
      documentUrl: map['document_url'] ?? '',
      status: map['status'] ?? NauticalLicenseStatus.none,
      rejectionReason: map['rejection_reason'],
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'document_url': documentUrl,
    'status': status,
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
  };
}
