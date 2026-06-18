import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/services/auth/firebase_auth_service.dart';

// Repositorio de autenticación que interactúa con FirebaseAuthService y Firestore para gestionar usuarios
class AuthRepository {
  AuthRepository(this._firebaseAuthService);

  final FirebaseAuthService _firebaseAuthService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _fetchUserModel(credential.user!.uid);
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
    required String nauticalLicenseType,
  }) async {
    final credential = await _firebaseAuthService
        .createUserWithEmailAndPassword(email: email, password: password);
    final normalizedLicenseType = _normalizeLicenseType(nauticalLicenseType);
    final licenseStatus = normalizedLicenseType == NauticalLicenseStatus.none
        ? NauticalLicenseStatus.verified
        : NauticalLicenseStatus.pending;

    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      name: name,
      surname: surname,
      birthDate: birthDate,
      role: UserRole.customer,
      nauticalLicense: NauticalLicense(
        type: normalizedLicenseType,
        documentUrl: '',
        status: licenseStatus,
        rejectionReason: '',
      ),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  Future<UserModel> signInWithGoogle() async {
    final credential = await _firebaseAuthService.signInWithGoogle();
    final uid = credential.user!.uid;

    final existingUser = await _fetchExistingUserModel(uid);

    if (existingUser != null) {
      return existingUser;
    }

    final user = UserModel(
      uid: uid,
      email: credential.user!.email ?? '',
      name: credential.user!.displayName ?? '',
      surname: '',
      birthDate: null,
      role: UserRole.customer,
      nauticalLicense: const NauticalLicense(
        type: 'none',
        documentUrl: '',
        status: 'verified',
        rejectionReason: '',
      ),
    );

    await _db.collection('users').doc(uid).set(user.toMap());

    return user;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuthService.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuthService.currentUser;
    if (firebaseUser == null) return null;

    return _fetchUserModel(firebaseUser.uid);
  }

  Future<void> signOut() => _firebaseAuthService.signOut();

  Future<UserModel> _fetchUserModel(String uid) async {
    final user = await _fetchExistingUserModel(uid);

    if (user == null) {
      throw Exception('Perfil no encontrado en Firestore.');
    }

    return user;
  }

  Future<UserModel?> _fetchExistingUserModel(String uid) async {
    final adminDoc = await _db.collection('admin').doc(uid).get();

    if (adminDoc.exists && adminDoc.data() != null) {
      final data = Map<String, dynamic>.from(adminDoc.data()!);
      data['role'] = 'admin';
      return UserModel.fromMap(data, uid);
    }

    final userDoc = await _db.collection('users').doc(uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = Map<String, dynamic>.from(userDoc.data()!);
      data['role'] = data['role'] ?? 'customer';
      return UserModel.fromMap(data, uid);
    }

    return null;
  }

  String _normalizeLicenseType(String value) {
    final normalizedValue = value.trim().toLowerCase();

    return switch (normalizedValue) {
      'pnb' => 'pnb',
      'per' => 'per',
      _ => NauticalLicenseStatus.none,
    };
  }
}
