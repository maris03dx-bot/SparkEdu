import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique chat ID between two users
  String getChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0
        ? "${user1}_$user2"
        : "${user2}_$user1";
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
  }) async {
    final chatId = getChatId(senderId, receiverId);

    final newMessage = MessageModel(
      id: "",
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      message: message,
      isRead: false,
      sentAt: Timestamp.now(),
      messageType: "text",
    );

    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add(newMessage.toMap());

    await _firestore.collection("chats").doc(chatId).set({
      "participants": [senderId, receiverId],
      "lastMessage": message,
      "lastMessageTime": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Stream messages
  Stream<QuerySnapshot> getMessages(
    String senderId,
    String receiverId,
  ) {
    final chatId = getChatId(senderId, receiverId);

    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("sentAt")
        .snapshots();
  }

  // Mark a message as read
  Future<void> markAsRead(
    String senderId,
    String receiverId,
    String messageId,
  ) async {
    final chatId = getChatId(senderId, receiverId);

    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isRead": true,
    });
  }

  // Chat list for a user
  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _firestore
        .collection("chats")
        .where("participants", arrayContains: userId)
        .orderBy("lastMessageTime", descending: true)
        .snapshots();
  }
}