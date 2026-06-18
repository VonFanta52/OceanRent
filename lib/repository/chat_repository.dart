import 'package:ocean_rent/models/chat_message_model.dart';
import 'package:ocean_rent/services/chat/chat_service.dart';

class ChatRepository {
  ChatRepository(this._chatService);
  final ChatService _chatService;
  Stream<List<ChatMessageModel>> watchMessages(String bookingId) {
    return _chatService.watchMessages(bookingId);
  }

  Stream<ChatMessageModel?> watchLastMessage(String bookingId) {
    return _chatService.watchLastMessage(bookingId);
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderRole,
    required String text,
  }) {
    return _chatService.sendMessage(
      bookingId: bookingId,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
    );
  }

  Future<void> closeChat({
    required String bookingId,
    required String closedBy,
  }) {
    return _chatService.closeChat(bookingId: bookingId, closedBy: closedBy);
  }
}
