import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AILessonPlanHistoryService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  static CollectionReference<Map<String, dynamic>>?
      _lessonPlanCollection() {
    final uid = currentUserId;

    if (uid == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ai_lesson_plans');
  }

  static Future<String> saveLessonPlan({
    required String topic,
    required String className,
    required int duration,
    required String difficulty,
    required String objectives,
    required String lessonPlan,
  }) async {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final planRef = collection.doc();

    await planRef.set({
      'topic': topic.trim(),
      'className': className.trim(),
      'duration': duration,
      'difficulty': difficulty.trim(),
      'objectives': objectives.trim(),
      'lessonPlan': lessonPlan.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return planRef.id;
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getLessonPlans() async {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      return [];
    }

    final snapshot = await collection
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      lessonPlanStream() {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      return const Stream.empty();
    }

    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?>
      getLessonPlan(String planId) async {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      return null;
    }

    final document =
        await collection.doc(planId).get();

    if (!document.exists) {
      return null;
    }

    return document;
  }

  static Future<void> deleteLessonPlan(
    String planId,
  ) async {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    await collection.doc(planId).delete();
  }

  static Future<void> deleteAllLessonPlans() async {
    final collection = _lessonPlanCollection();

    if (collection == null) {
      throw Exception('User is not logged in.');
    }

    final snapshot = await collection.get();

    for (final document in snapshot.docs) {
      await document.reference.delete();
    }
  }
}