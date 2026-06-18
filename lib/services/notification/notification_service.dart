import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ocean_rent/services/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Notificación recibida en segundo plano: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await saveTokenForCurrentUser();
      }
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _saveTokenForCurrentUser,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Notificación recibida con la app abierta: ${message.messageId}',
      );
      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Mensaje: ${message.notification?.body}');
    });

    await saveTokenForCurrentUser();
  }

  Future<void> saveTokenForCurrentUser() async {
    await _requestPermission();

    final token = await _messaging.getToken();

    if (token == null) {
      debugPrint('No se ha podido obtener el token FCM.');
      return;
    }

    await _saveTokenForCurrentUser(token);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();

    debugPrint('Permiso de notificaciones: ${settings.authorizationStatus}');
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = _auth.currentUser;

    if (user == null) {
      debugPrint('No hay usuario autenticado. Token FCM no guardado.');
      return;
    }

    try {
      final adminRef = _firestore.collection('admin').doc(user.uid);
      final adminDoc = await adminRef.get();

      if (adminDoc.exists) {
        await adminRef.set({
          'fcm_token': token,
          'fcm_token_updated_at': FieldValue.serverTimestamp(),
          'fcm_token_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        }, SetOptions(merge: true));

        debugPrint('Token FCM guardado en admin/${user.uid}');
        return;
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        debugPrint(
          'No existe perfil en admin ni users. Token FCM no guardado todavía.',
        );
        return;
      }

      await userRef.set({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
        'fcm_token_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      debugPrint('Token FCM guardado en users/${user.uid}');
    } on FirebaseException catch (error) {
      debugPrint(
        'Error de Firebase al guardar el token FCM: '
        '${error.code} - ${error.message}',
      );
    } catch (error) {
      debugPrint('Error inesperado al guardar el token FCM: $error');
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}
