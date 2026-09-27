import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final bool isRead;
  final Timestamp sentAt;
  final String messageType;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.sentAt,
    required this.messageType,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      sentAt: data['sentAt'] ?? Timestamp.now(),
      messageType: data['messageType'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'sentAt': sentAt,
      'messageType': messageType,
    };
  }
}