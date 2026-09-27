import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all teachers
  Stream<QuerySnapshot> getTeachers() {
    return _firestore.collection('teachers').snapshots();
  }

  // Get all subjects
  Stream<QuerySnapshot> getSubjects() {
    return _firestore.collection('subjects').snapshots();
  }

  // Get all announcements
  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore.collection('announcements').snapshots();
  }

  // Get all users
  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }
}