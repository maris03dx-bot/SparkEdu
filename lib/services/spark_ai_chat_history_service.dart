import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SparkAIChatHistoryService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ------------------------------------------------------------
  // CURRENT STUDENT UID
  // ------------------------------------------------------------

  static String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // ------------------------------------------------------------
  // CHAT COLLECTION
  // users/{uid}/spark_ai_chats
  // ------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>>? _chatCollection() {
    final uid = currentUserId;

    if (uid == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('spark_ai_chats');
  }

  // ------------------------------------------------------------
  // CREATE NEW CHAT
  // ------------------------------------------------------------

  static Future<String> createChat({
    required String title,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
  }) async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final chatRef = collection.doc();

    await chatRef.set({
      'title': title.trim().isEmpty ? 'New Chat' : title.trim(),
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  // ------------------------------------------------------------
  // ADD MESSAGE
  // users/{uid}/spark_ai_chats/{chatId}/messages
  // ------------------------------------------------------------

  static Future<String> addMessage({
    required String chatId,
    required String role,
    required String text,
  }) async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final chatRef = collection.doc(chatId);

    final messageRef = chatRef.collection('messages').doc();

    await messageRef.set({
      'role': role,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the chat's last activity time.
    await chatRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return messageRef.id;
  }

  // ------------------------------------------------------------
  // UPDATE CHAT TITLE
  // ------------------------------------------------------------

  static Future<void> updateChatTitle({
    required String chatId,
    required String title,
  }) async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    await collection.doc(chatId).update({
      'title': title.trim().isEmpty ? 'New Chat' : title.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // UPDATE CHAT SUBJECT
  // ------------------------------------------------------------

  static Future<void> updateChatSubject({
    required String chatId,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
  }) async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    await collection.doc(chatId).update({
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // GET ALL CHATS
  // ------------------------------------------------------------

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getChats() async {
    final collection = _chatCollection();

    if (collection == null) {
      return [];
    }

    final snapshot = await collection
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs;
  }

  // ------------------------------------------------------------
  // STREAM CHAT HISTORY
  // ------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>> chatStream() {
    final collection = _chatCollection();

    if (collection == null) {
      return const Stream.empty();
    }

    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET MESSAGES FROM A CHAT
  // ------------------------------------------------------------

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getMessages(String chatId) async {
    final collection = _chatCollection();

    if (collection == null) {
      return [];
    }

    final snapshot = await collection
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .get();

    return snapshot.docs;
  }

  // ------------------------------------------------------------
  // STREAM MESSAGES
  // ------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>> messageStream(
    String chatId,
  ) {
    final collection = _chatCollection();

    if (collection == null) {
      return const Stream.empty();
    }

    return collection
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  // ------------------------------------------------------------
  // DELETE ONE CHAT
  // ------------------------------------------------------------

  static Future<void> deleteChat(String chatId) async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final chatRef = collection.doc(chatId);

    // Delete all messages first.
    final messagesSnapshot =
        await chatRef.collection('messages').get();

    for (final message in messagesSnapshot.docs) {
      await message.reference.delete();
    }

    // Then delete the chat itself.
    await chatRef.delete();
  }

  // ------------------------------------------------------------
  // DELETE ALL CHAT HISTORY
  // ------------------------------------------------------------

  static Future<void> deleteAllChats() async {
    final collection = _chatCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final chatsSnapshot = await collection.get();

    for (final chat in chatsSnapshot.docs) {
      final messagesSnapshot =
          await chat.reference.collection('messages').get();

      for (final message in messagesSnapshot.docs) {
        await message.reference.delete();
      }

      await chat.reference.delete();
    }
  }
}