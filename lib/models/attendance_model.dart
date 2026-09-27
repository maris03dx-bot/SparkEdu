import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String sessionId;
  final String subject;
  final String teacher;
  final String status;
  final Timestamp markedAt;

  AttendanceModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.sessionId,
    required this.subject,
    required this.teacher,
    required this.status,
    required this.markedAt,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AttendanceModel(
      id: doc.id,
      studentUid: data["studentUid"] ?? "",
      studentName: data["studentName"] ?? "",
      sessionId: data["sessionId"] ?? "",
      subject: data["subject"] ?? "",
      teacher: data["teacher"] ?? "",
      status: data["status"] ?? "Present",
      markedAt: data["markedAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "studentUid": studentUid,
      "studentName": studentName,
      "sessionId": sessionId,
      "subject": subject,
      "teacher": teacher,
      "status": status,
      "markedAt": markedAt,
    };
  }
}