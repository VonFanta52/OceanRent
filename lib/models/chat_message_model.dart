import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  static const String senderRoleAdmin = 'admin';
  static const String senderRoleCustomer = 'customer';

  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  bool get isFromAdmin => senderRole == senderRoleAdmin;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessageModel(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      senderRole: data['sender_role'] ?? senderRoleCustomer,
      text: data['text'] ?? '',
      createdAt: _nullableDateFromTimestamp(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': text,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _nullableDateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
