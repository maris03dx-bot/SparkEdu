import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================
  // MARK ATTENDANCE
  // ==========================
  Future<void> markAttendance({
    required String studentUid,
    required String studentName,
    required String sessionId,
    required String subject,
    required String teacher,
  }) async {
    await _firestore.collection("attendance_records").add({
      "studentUid": studentUid,
      "studentName": studentName,
      "sessionId": sessionId,
      "subject": subject,
      "teacher": teacher,
      "status": "Present",
      "markedAt": Timestamp.now(),
    });
  }

  // ==========================
  // CHECK IF ALREADY MARKED
  // ==========================
  Future<bool> alreadyMarked({
    required String studentUid,
    required String sessionId,
  }) async {
    final snapshot = await _firestore
        .collection("attendance_records")
        .where("studentUid", isEqualTo: studentUid)
        .where("sessionId", isEqualTo: sessionId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ==========================
  // STUDENT HISTORY
  // ==========================
  Stream<QuerySnapshot> getStudentAttendance(String studentUid) {
    return _firestore
        .collection("attendance_records")
        .where("studentUid", isEqualTo: studentUid)
        .orderBy("markedAt", descending: true)
        .snapshots();
  }

  // ==========================
  // SESSION ATTENDANCE
  // ==========================
  Stream<QuerySnapshot> getSessionAttendance(String sessionId) {
    return _firestore
        .collection("attendance_records")
        .where("sessionId", isEqualTo: sessionId)
        .snapshots();
  }

  // ==========================
  // ACTIVE SESSION
  // ==========================
  Stream<QuerySnapshot> getActiveSessions() {
    return _firestore
        .collection("attendance_sessions")
        .where("active", isEqualTo: true)
        .snapshots();
  }

  // ==========================
  // END SESSION
  // ==========================
  Future<void> endSession(String sessionId) async {
    await _firestore
        .collection("attendance_sessions")
        .doc(sessionId)
        .update({
      "active": false,
    });
  }
}