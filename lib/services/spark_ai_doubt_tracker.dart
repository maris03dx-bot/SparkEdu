import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SparkAIDoubtTracker {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // SETTINGS
  // ============================================================

  static const int repeatedDoubtThreshold = 3;

  // ============================================================
  // SAVE STUDENT DOUBT
  // ============================================================

  static Future<void> saveDoubt({
    required String question,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
  }) async {
    final String cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      return;
    }

    try {
      // ==========================================================
      // CURRENT USER
      // ==========================================================

      final User? user = _auth.currentUser;

      if (user == null) {
        debugPrint("SparkAI Tracker: User not logged in.");
        return;
      }

      // ==========================================================
      // STUDENT PROFILE
      // ==========================================================

      final QuerySnapshot<Map<String, dynamic>> userQuery =
          await _firestore
              .collection("users")
              .where(
                "uid",
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      Map<String, dynamic> userData = {};

      if (userQuery.docs.isNotEmpty) {
        userData = userQuery.docs.first.data();
      }

      // ==========================================================
      // STUDENT INFORMATION
      // ==========================================================

      final String studentName =
          userData["name"]?.toString().trim().isNotEmpty == true
              ? userData["name"].toString().trim()
              : "Student";

      final String registerNo =
          userData["registerNo"]?.toString().trim() ?? "";

      final String department =
          userData["department"]?.toString().trim() ?? "";

      final String year =
          userData["year"]?.toString().trim() ?? "";

      final String section =
          userData["section"]?.toString().trim() ?? "";

      // ==========================================================
      // SUBJECT INFORMATION
      // ==========================================================

      final String cleanSubjectId =
          subjectId?.trim() ?? "";

      final String cleanSubjectName =
          subjectName?.trim() ?? "";

      final String cleanSubjectCode =
          subjectCode?.trim() ?? "";

      // ==========================================================
      // IMPORTANT
      //
      // A repeated doubt MUST belong to a subject.
      // Otherwise AI doubts from different subjects could
      // accidentally be counted together.
      // ==========================================================

      if (cleanSubjectId.isEmpty &&
          cleanSubjectName.isEmpty &&
          cleanSubjectCode.isEmpty) {
        debugPrint(
          "SparkAI Tracker: Subject information missing. "
          "Doubt will be saved, but repeated-doubt alert "
          "will not be generated.",
        );
      }

      // ==========================================================
      // NORMALIZE QUESTION
      // ==========================================================

      final String normalizedQuestion =
          _normalizeQuestion(cleanQuestion);

      // ==========================================================
      // SAVE DOUBT
      // ==========================================================

      final DocumentReference<Map<String, dynamic>>
          doubtReference =
          await _firestore
              .collection("spark_ai_doubts")
              .add({
        "question": cleanQuestion,
        "normalizedQuestion": normalizedQuestion,

        // Student
        "studentUid": user.uid,
        "studentName": studentName,
        "registerNo": registerNo,

        // Class
        "department": department,
        "year": year,
        "section": section,

        // Subject
        "subjectId": cleanSubjectId,
        "subjectName": cleanSubjectName,
        "subjectCode": cleanSubjectCode,

        // Time
        "createdAt": FieldValue.serverTimestamp(),
      });

      debugPrint("======================================");
      debugPrint("SparkAI doubt saved successfully.");
      debugPrint("Doubt ID: ${doubtReference.id}");
      debugPrint("Student: $studentName");
      debugPrint("Subject ID: $cleanSubjectId");
      debugPrint("Subject Name: $cleanSubjectName");
      debugPrint("Subject Code: $cleanSubjectCode");
      debugPrint("Question: $cleanQuestion");
      debugPrint("======================================");

      // ==========================================================
      // CHECK REPEATED DOUBT
      // ==========================================================

      await _checkForRepeatedDoubt(
        normalizedQuestion: normalizedQuestion,
        originalQuestion: cleanQuestion,
        currentStudentUid: user.uid,
        department: department,
        year: year,
        section: section,
        subjectId: cleanSubjectId,
        subjectName: cleanSubjectName,
        subjectCode: cleanSubjectCode,
      );
    } catch (e) {
      debugPrint("======================================");
      debugPrint("SparkAI doubt tracking error:");
      debugPrint("$e");
      debugPrint("======================================");
    }
  }

  // ============================================================
  // FIND SUBJECT TEACHER
  //
  // IMPORTANT:
  // We ONLY return a teacher when the subject actually matches.
  //
  // We DO NOT:
  // - choose the first teacher
  // - use department alone
  // - use document ID as UID
  // - randomly fallback to another teacher
  // ============================================================

  static Future<Map<String, dynamic>?>
      _findSubjectTeacher({
    required String department,
    required String subjectId,
    required String subjectName,
    required String subjectCode,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          teacherSnapshot =
          await _firestore
              .collection("users")
              .where(
                "role",
                isEqualTo: "Subject Teacher",
              )
              .get();

      if (teacherSnapshot.docs.isEmpty) {
        debugPrint(
          "SparkAI Tracker: No Subject Teacher accounts found.",
        );
        return null;
      }

      final String wantedDepartment =
          _normalizeValue(department);

      final String wantedSubjectId =
          _normalizeValue(subjectId);

      final String wantedSubjectName =
          _normalizeSubject(subjectName);

      final String wantedSubjectCode =
          _normalizeValue(subjectCode);

      // ==========================================================
      // PASS 1
      // EXACT SUBJECT ID + DEPARTMENT
      // ==========================================================

      if (wantedSubjectId.isNotEmpty) {
        for (final doc in teacherSnapshot.docs) {
          final Map<String, dynamic> data =
              doc.data();

          final String teacherUid =
              data["uid"]?.toString().trim() ?? "";

          if (teacherUid.isEmpty) {
            continue;
          }

          final String teacherDepartment =
              _normalizeValue(
            data["department"]?.toString() ?? "",
          );

          final String teacherSubjectId =
              _normalizeValue(
            data["subjectId"]?.toString() ?? "",
          );

          if (teacherDepartment ==
                  wantedDepartment &&
              teacherSubjectId ==
                  wantedSubjectId) {
            debugPrint(
              "Teacher matched by subjectId: "
              "${data["name"]}",
            );

            return data;
          }
        }
      }

      // ==========================================================
      // PASS 2
      // EXACT SUBJECT CODE + DEPARTMENT
      // ==========================================================

      if (wantedSubjectCode.isNotEmpty) {
        for (final doc in teacherSnapshot.docs) {
          final Map<String, dynamic> data =
              doc.data();

          final String teacherUid =
              data["uid"]?.toString().trim() ?? "";

          if (teacherUid.isEmpty) {
            continue;
          }

          final String teacherDepartment =
              _normalizeValue(
            data["department"]?.toString() ?? "",
          );

          final String teacherSubjectCode =
              _normalizeValue(
            data["subjectCode"]?.toString() ?? "",
          );

          if (teacherDepartment ==
                  wantedDepartment &&
              teacherSubjectCode ==
                  wantedSubjectCode) {
            debugPrint(
              "Teacher matched by subjectCode: "
              "${data["name"]}",
            );

            return data;
          }
        }
      }

      // ==========================================================
      // PASS 3
      // SUBJECT NAME + DEPARTMENT
      //
      // This is the important match for your current database:
      //
      // Dr.Kumar  -> Artificial Intelligence
      // Mr.Suresh -> Data Structures
      // ==========================================================

      if (wantedSubjectName.isNotEmpty) {
        for (final doc in teacherSnapshot.docs) {
          final Map<String, dynamic> data =
              doc.data();

          final String teacherUid =
              data["uid"]?.toString().trim() ?? "";

          if (teacherUid.isEmpty) {
            continue;
          }

          final String teacherDepartment =
              _normalizeValue(
            data["department"]?.toString() ?? "",
          );

          final String teacherSubject =
              _normalizeSubject(
            data["subject"]?.toString() ?? "",
          );

          if (teacherDepartment ==
                  wantedDepartment &&
              teacherSubject ==
                  wantedSubjectName) {
            debugPrint(
              "Teacher matched by subject name: "
              "${data["name"]}",
            );

            return data;
          }
        }
      }

      // ==========================================================
      // PASS 4
      // subjectName FIELD + DEPARTMENT
      // ==========================================================

      if (wantedSubjectName.isNotEmpty) {
        for (final doc in teacherSnapshot.docs) {
          final Map<String, dynamic> data =
              doc.data();

          final String teacherUid =
              data["uid"]?.toString().trim() ?? "";

          if (teacherUid.isEmpty) {
            continue;
          }

          final String teacherDepartment =
              _normalizeValue(
            data["department"]?.toString() ?? "",
          );

          final String teacherSubjectName =
              _normalizeSubject(
            data["subjectName"]?.toString() ?? "",
          );

          if (teacherDepartment ==
                  wantedDepartment &&
              teacherSubjectName ==
                  wantedSubjectName) {
            debugPrint(
              "Teacher matched by subjectName: "
              "${data["name"]}",
            );

            return data;
          }
        }
      }

      // ==========================================================
      // NO MATCH
      //
      // NEVER FALL BACK TO A RANDOM TEACHER.
      // ==========================================================

      debugPrint("======================================");
      debugPrint("SUBJECT TEACHER NOT FOUND");
      debugPrint("Department: $department");
      debugPrint("Subject ID: $subjectId");
      debugPrint("Subject Name: $subjectName");
      debugPrint("Subject Code: $subjectCode");
      debugPrint("======================================");

      return null;
    } catch (e) {
      debugPrint(
        "SparkAI Tracker: Error finding subject teacher: $e",
      );

      return null;
    }
  }

  // ============================================================
  // CHECK REPEATED DOUBT
  // ============================================================

  static Future<void> _checkForRepeatedDoubt({
    required String normalizedQuestion,
    required String originalQuestion,
    required String currentStudentUid,
    required String department,
    required String year,
    required String section,
    required String subjectId,
    required String subjectName,
    required String subjectCode,
  }) async {
    try {
      // ==========================================================
      // SUBJECT MUST EXIST
      // ==========================================================

      if (subjectId.trim().isEmpty &&
          subjectName.trim().isEmpty &&
          subjectCode.trim().isEmpty) {
        debugPrint(
          "Repeated doubt check skipped because "
          "subject information is missing.",
        );
        return;
      }

      // ==========================================================
      // FIND SAME QUESTION + SAME CLASS
      // ==========================================================

      Query<Map<String, dynamic>> doubtQuery =
          _firestore
              .collection("spark_ai_doubts")
              .where(
                "normalizedQuestion",
                isEqualTo: normalizedQuestion,
              )
              .where(
                "department",
                isEqualTo: department,
              )
              .where(
                "year",
                isEqualTo: year,
              )
              .where(
                "section",
                isEqualTo: section,
              );

      // ==========================================================
      // SUBJECT FILTER
      //
      // Prefer subjectId.
      // If unavailable, use subjectCode.
      // If unavailable, use subjectName.
      // ==========================================================

      if (subjectId.trim().isNotEmpty) {
        doubtQuery = doubtQuery.where(
          "subjectId",
          isEqualTo: subjectId.trim(),
        );
      } else if (subjectCode.trim().isNotEmpty) {
        doubtQuery = doubtQuery.where(
          "subjectCode",
          isEqualTo: subjectCode.trim(),
        );
      } else if (subjectName.trim().isNotEmpty) {
        doubtQuery = doubtQuery.where(
          "subjectName",
          isEqualTo: subjectName.trim(),
        );
      }

      final QuerySnapshot<Map<String, dynamic>>
          querySnapshot =
          await doubtQuery.get();

      // ==========================================================
      // UNIQUE STUDENTS
      // ==========================================================

      final Set<String> uniqueStudentUids = {};

      for (final document
          in querySnapshot.docs) {
        final Map<String, dynamic> data =
            document.data();

        final String studentUid =
            data["studentUid"]
                    ?.toString()
                    .trim() ??
                "";

        if (studentUid.isNotEmpty) {
          uniqueStudentUids.add(studentUid);
        }
      }

      final int uniqueStudentCount =
          uniqueStudentUids.length;

      debugPrint("======================================");
      debugPrint("REPEATED DOUBT CHECK");
      debugPrint("Question: $normalizedQuestion");
      debugPrint("Department: $department");
      debugPrint("Year: $year");
      debugPrint("Section: $section");
      debugPrint("Subject ID: $subjectId");
      debugPrint("Subject Name: $subjectName");
      debugPrint("Subject Code: $subjectCode");
      debugPrint("Unique students: $uniqueStudentCount");
      debugPrint("Required: $repeatedDoubtThreshold");
      debugPrint("======================================");

      // ==========================================================
      // THRESHOLD
      // ==========================================================

      if (uniqueStudentCount <
          repeatedDoubtThreshold) {
        return;
      }

      // ==========================================================
      // FIND THE CORRECT SUBJECT TEACHER
      // ==========================================================

      final Map<String, dynamic>? teacher =
          await _findSubjectTeacher(
        department: department,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectCode: subjectCode,
      );

      if (teacher == null) {
        debugPrint(
          "No exact subject teacher found. "
          "Alert will NOT be created.",
        );
        return;
      }

      // ==========================================================
      // GET TEACHER UID
      //
      // ONLY use the real uid field.
      //
      // NEVER use Firestore document ID as teacher UID.
      // ==========================================================

      final String teacherUid =
          teacher["uid"]?.toString().trim() ?? "";

      if (teacherUid.isEmpty) {
        debugPrint(
          "Teacher record has no UID. "
          "Alert will NOT be created.",
        );
        return;
      }

      final String teacherName =
          teacher["name"]
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? teacher["name"]
                  .toString()
                  .trim()
              : "Subject Teacher";

      // ==========================================================
      // DEBUG
      // ==========================================================

      debugPrint("======================================");
      debugPrint("TEACHER-SPECIFIC ALERT");
      debugPrint("Teacher: $teacherName");
      debugPrint("Teacher UID: $teacherUid");
      debugPrint("Subject: $subjectName");
      debugPrint("Subject Code: $subjectCode");
      debugPrint("======================================");

      // ==========================================================
      // CHECK EXISTING ALERT
      // ==========================================================

      Query<Map<String, dynamic>>
          existingAlertQuery =
          _firestore
              .collection(
                "spark_ai_doubt_alerts",
              )
              .where(
                "normalizedQuestion",
                isEqualTo: normalizedQuestion,
              )
              .where(
                "department",
                isEqualTo: department,
              )
              .where(
                "year",
                isEqualTo: year,
              )
              .where(
                "section",
                isEqualTo: section,
              )
              .where(
                "teacherUid",
                isEqualTo: teacherUid,
              )
              .where(
                "status",
                isEqualTo: "unread",
              );

      // ==========================================================
      // SUBJECT FILTER FOR EXISTING ALERT
      // ==========================================================

      if (subjectId.trim().isNotEmpty) {
        existingAlertQuery =
            existingAlertQuery.where(
          "subjectId",
          isEqualTo: subjectId.trim(),
        );
      } else if (subjectCode.trim().isNotEmpty) {
        existingAlertQuery =
            existingAlertQuery.where(
          "subjectCode",
          isEqualTo: subjectCode.trim(),
        );
      } else if (subjectName.trim().isNotEmpty) {
        existingAlertQuery =
            existingAlertQuery.where(
          "subjectName",
          isEqualTo: subjectName.trim(),
        );
      }

      final QuerySnapshot<Map<String, dynamic>>
          existingAlertSnapshot =
          await existingAlertQuery
              .limit(1)
              .get();

      if (existingAlertSnapshot.docs.isNotEmpty) {
        debugPrint(
          "Teacher-specific repeated doubt alert "
          "already exists.",
        );
        return;
      }

      // ==========================================================
      // SUBJECT DISPLAY NAME
      // ==========================================================

      final String subjectDisplayName =
          subjectName.trim().isNotEmpty
              ? subjectName.trim()
              : subjectCode.trim().isNotEmpty
                  ? subjectCode.trim()
                  : "this subject";

      // ==========================================================
      // CREATE TEACHER-SPECIFIC ALERT
      // ==========================================================

      await _firestore
          .collection(
            "spark_ai_doubt_alerts",
          )
          .add({
        // Question
        "question": originalQuestion,
        "normalizedQuestion": normalizedQuestion,

        // Students
        "studentCount": uniqueStudentCount,
        "studentUids":
            uniqueStudentUids.toList(),

        // Class
        "department": department,
        "year": year,
        "section": section,

        // Subject
        "subjectId": subjectId,
        "subjectName": subjectName,
        "subjectCode": subjectCode,

        // ========================================================
        // ⭐ CORRECT TEACHER
        // ========================================================

        "teacherUid": teacherUid,
        "teacherName": teacherName,

        // Message
        "message":
            "Many students are asking about "
            "\"$originalQuestion\" "
            "in $subjectDisplayName. "
            "Consider revisiting this topic in class.",

        // Status
        "status": "unread",

        // Action
        "action": "review_topic",

        // Time
        "createdAt":
            FieldValue.serverTimestamp(),
      });

      // ==========================================================
      // SUCCESS
      // ==========================================================

      debugPrint("======================================");
      debugPrint("🚨 REPEATED DOUBT DETECTED");
      debugPrint("Question: $originalQuestion");
      debugPrint("Subject: $subjectDisplayName");
      debugPrint("Students: $uniqueStudentCount");
      debugPrint(
        "Class: $department / $year / $section",
      );
      debugPrint("Teacher: $teacherName");
      debugPrint("Teacher UID: $teacherUid");
      debugPrint(
        "Teacher-specific alert created successfully.",
      );
      debugPrint("======================================");
    } catch (e) {
      debugPrint(
        "Repeated doubt detection error: $e",
      );
    }
  }

  // ============================================================
  // NORMALIZE QUESTION
  // ============================================================

  static String _normalizeQuestion(
    String question,
  ) {
    String result =
        question.toLowerCase();

    result = result.replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result.trim();
  }

  // ============================================================
  // NORMALIZE GENERAL VALUE
  // ============================================================

  static String _normalizeValue(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  // ============================================================
  // NORMALIZE SUBJECT
  //
  // Makes matching slightly more tolerant:
  //
  // "Artificial Intelligence"
  // "artificial intelligence"
  // "Artificial   Intelligence"
  //
  // are treated as the same.
  // ============================================================

  static String _normalizeSubject(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }
}