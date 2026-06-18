import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/chat_message_model.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String bookingId,
  ) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages');
  }

  Stream<List<ChatMessageModel>> watchMessages(String bookingId) {
    return _messagesCollection(bookingId).orderBy('created_at').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  Stream<ChatMessageModel?> watchLastMessage(String bookingId) {
    return _messagesCollection(bookingId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          return ChatMessageModel.fromFirestore(snapshot.docs.first);
        });
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final trimmedText = text.trim();

    if (bookingId.trim().isEmpty) {
      throw Exception('No se pudo identificar la conversación.');
    }

    if (trimmedText.isEmpty) {
      throw Exception('El mensaje no puede estar vacío.');
    }

    if (trimmedText.length > 500) {
      throw Exception('El mensaje no puede superar los 500 caracteres.');
    }

    await _messagesCollection(bookingId).add({
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': trimmedText,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeChat({
    required String bookingId,
    required String closedBy,
  }) async {
    if (bookingId.trim().isEmpty) {
      throw Exception('No se pudo identificar la conversación.');
    }

    if (closedBy.trim().isEmpty) {
      throw Exception('No se pudo identificar al usuario.');
    }

    await _firestore.collection('bookings').doc(bookingId).update({
      'chat_status': 'closed',
      'chat_closed_at': FieldValue.serverTimestamp(),
      'chat_closed_by': closedBy,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
