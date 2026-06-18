import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/repository/auth_repository.dart';
import 'package:ocean_rent/services/auth/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthRepository(authService);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authRepository);

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == UserRole.admin;

  bool get isCustomer => _currentUser?.role == UserRole.customer;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkCurrentSession() async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado al iniciar sesión.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
    required String nauticalLicenseType,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        surname: surname,
        birthDate: birthDate,
        nauticalLicenseType: nauticalLicenseType,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado al registrarte.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo enviar el correo de recuperacion.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authRepository.signInWithGoogle();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesión con Google.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (_) {
      _errorMessage = 'No se pudo cerrar la sesión.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'El correo electrónico no es válido.',
      'missing-email' => 'Introduce un correo electrónico.',
      'user-not-found' ||
      'invalid-credential' ||
      'wrong-password' => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ese correo ya esta registrado.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'too-many-requests' => 'Demasiados intentos. Intentalo mas tarde.',
      'account-exists-with-different-credential' =>
        'Ya existe una cuenta con ese correo usando otro metodo.',
      _ => e.message ?? 'Error de Firebase Auth.',
    };
  }
}
