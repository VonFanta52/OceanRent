import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<UserModel> getUser(String uid) async {
    final adminDoc = await _firestore.collection('admin').doc(uid).get();

    if (adminDoc.exists && adminDoc.data() != null) {
      final data = Map<String, dynamic>.from(adminDoc.data()!);
      data['role'] = 'admin';
      return UserModel.fromMap(data, uid);
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Usuario no encontrado: $uid');
    }

    final data = Map<String, dynamic>.from(userDoc.data()!);
    data['role'] = data['role'] ?? 'customer';

    return UserModel.fromMap(data, uid);
  }

  Stream<List<UserModel>> watchCustomersWithLicenses() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['role'] = data['role'] ?? 'customer';
            return UserModel.fromMap(data, doc.id);
          })
          .where((user) {
            final license = user.nauticalLicense;
            return license != null && license.type.toLowerCase() != 'none';
          })
          .toList();

      users.sort((a, b) {
        final statusCompare =
            _licenseStatusPriority(
              a.nauticalLicense?.status ?? 'none',
            ).compareTo(
              _licenseStatusPriority(b.nauticalLicense?.status ?? 'none'),
            );

        if (statusCompare != 0) return statusCompare;

        return '${a.name} ${a.surname}'.compareTo('${b.name} ${b.surname}');
      });

      return users;
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String surname,
  }) async {
    final profileRef = await _profileDocumentRef(uid);

    return profileRef.update({
      'name': name,
      'surname': surname,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNauticalLicense({
    required String uid,
    required String type,
    required String documentUrl,
    required String status,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'nautical_license.type': type,
      'nautical_license.document_url': documentUrl,
      'nautical_license.status': status,
      'nautical_license.rejection_reason': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNauticalLicenseStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) {
    final data = <String, dynamic>{
      'nautical_license.status': status,
      'nautical_license.rejection_reason': rejectionReason,
      'updated_at': FieldValue.serverTimestamp(),
    };

    return _firestore.collection('users').doc(uid).update(data);
  }

  Future<DocumentReference<Map<String, dynamic>>> _profileDocumentRef(
    String uid,
  ) async {
    final adminRef = _firestore.collection('admin').doc(uid);
    final adminDoc = await adminRef.get();

    if (adminDoc.exists) {
      return adminRef;
    }

    return _firestore.collection('users').doc(uid);
  }

  int _licenseStatusPriority(String status) {
    return switch (status) {
      NauticalLicenseStatus.pending => 0,
      NauticalLicenseStatus.rejected => 1,
      NauticalLicenseStatus.verified => 2,
      _ => 3,
    };
  }
}
