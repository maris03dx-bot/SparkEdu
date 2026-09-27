import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFirestoreService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> saveMessage({
    required String role,
    required String text,
  }) async {
    await _firestore.collection("spark_ai_chat").add({
      "role": role,
      "text": text,
      "time": FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getMessages() {
    return _firestore
        .collection("spark_ai_chat")
        .orderBy("time")
        .snapshots();
  }
}