import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/chat_message_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/repository/chat_repository.dart';
import 'package:ocean_rent/services/chat/chat_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ChatService.instance);
});

/// Mensajes en tiempo real de una reserva concreta.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessageModel>, String>((ref, bookingId) {
      final authState = ref.watch(authStateChangesProvider);
      final repository = ref.watch(chatRepositoryProvider);

      if (bookingId.trim().isEmpty ||
          !authState.hasValue ||
          authState.value == null) {
        return const Stream.empty();
      }

      return repository
          .watchMessages(bookingId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });

/// Ultimo mensaje de una reserva, para mostrar la vista previa en la lista.
final lastChatMessageProvider = StreamProvider.autoDispose
    .family<ChatMessageModel?, String>((ref, bookingId) {
      final authState = ref.watch(authStateChangesProvider);
      final repository = ref.watch(chatRepositoryProvider);

      if (bookingId.trim().isEmpty ||
          !authState.hasValue ||
          authState.value == null) {
        return const Stream.empty();
      }

      return repository
          .watchLastMessage(bookingId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });

final chatNotifierProvider = ChangeNotifierProvider<ChatNotifier>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});

class ChatNotifier extends ChangeNotifier {
  ChatNotifier(this._chatRepository);

  final ChatRepository _chatRepository;

  bool _isSending = false;
  bool _isClosing = false;
  String? _errorMessage;

  bool get isSending => _isSending;

  bool get isClosing => _isClosing;

  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    if (_isSending) return false;

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      _errorMessage = 'El mensaje no puede estar vacío.';
      notifyListeners();
      return false;
    }

    if (trimmedText.length > 500) {
      _errorMessage = 'El mensaje no puede superar los 500 caracteres.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chatRepository.sendMessage(
        bookingId: bookingId,
        senderId: senderId,
        senderRole: senderRole,
        text: trimmedText,
      );
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> closeChat({
    required String bookingId,
    required String closedBy,
  }) async {
    if (_isClosing) return false;

    _isClosing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chatRepository.closeChat(bookingId: bookingId, closedBy: closedBy);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isClosing = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('permission-denied')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    return message.isEmpty ? 'No se pudo completar la operación.' : message;
  }
}
