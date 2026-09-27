import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceStudentsScreen extends StatefulWidget {
  final String sessionId;
  final String subject;

  const AttendanceStudentsScreen({
    super.key,
    required this.sessionId,
    required this.subject,
  });

  @override
  State<AttendanceStudentsScreen> createState() =>
      _AttendanceStudentsScreenState();
}

class _AttendanceStudentsScreenState
    extends State<AttendanceStudentsScreen> {
  bool loading = true;

  List<Map<String, dynamic>> allStudents = [];

  Map<String, Map<String, dynamic>> attendanceMap = {};

  String? className;
  String? department;
  String? year;
  String? section;

  String? sessionTeacher;
  String? sessionDate;
  String? sessionTime;
  String? sessionSubject;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  // ============================================================
  // LOAD ATTENDANCE
  // ============================================================

  Future<void> loadAttendance() async {
    try {
      // ========================================================
      // 1. GET ATTENDANCE SESSION
      // ========================================================

      final sessionDoc = await FirebaseFirestore.instance
          .collection("attendance_sessions")
          .doc(widget.sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception(
          "Attendance session not found.",
        );
      }

      final sessionData = sessionDoc.data();

      if (sessionData == null) {
        throw Exception(
          "Invalid attendance session.",
        );
      }

      // ========================================================
      // GET MAIN CLASS NAME
      // ========================================================

      className = sessionData["className"]
          ?.toString()
          .trim();

      // ========================================================
      // GET COMPATIBILITY FIELDS
      // ========================================================

      department = sessionData["department"]
          ?.toString()
          .trim();

      year = sessionData["year"]
          ?.toString()
          .trim();

      section = sessionData["section"]
          ?.toString()
          .trim();

      // ========================================================
      // GET SESSION INFORMATION
      // ========================================================

      sessionTeacher = sessionData["teacher"]
          ?.toString()
          .trim();

      sessionDate = sessionData["date"]
          ?.toString()
          .trim();

      sessionTime = sessionData["time"]
          ?.toString()
          .trim();

      sessionSubject = sessionData["subject"]
          ?.toString()
          .trim();

      // ========================================================
      // CLASS NAME IS REQUIRED
      // ========================================================

      if (className == null || className!.isEmpty) {
        throw Exception(
          "This attendance session does not have a Class Name.",
        );
      }

      // ========================================================
      // SUBJECT SAFETY CHECK
      // ========================================================

      if (sessionSubject != null &&
          sessionSubject!.isNotEmpty &&
          sessionSubject!.toUpperCase() !=
              widget.subject.trim().toUpperCase()) {
        throw Exception(
          "This attendance session does not match the selected subject.",
        );
      }

      // ========================================================
      // 2. GET STUDENTS
      // ========================================================
      //
      // Class Name is the primary matching field.
      //
      // Example:
      //
      // Session: 25CSEB2
      // Student: 25CSEB2
      //
      // Only students from 25CSEB2 are loaded.
      //
      // ========================================================

      final usersSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where(
            "role",
            isEqualTo: "Student",
          )
          .where(
            "className",
            isEqualTo: className,
          )
          .get();

      allStudents = [];

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();

        // ======================================================
        // VERIFY STUDENT CLASS
        // ======================================================

        final studentClassName = data["className"]
            ?.toString()
            .trim();

        if (studentClassName == null ||
            studentClassName.isEmpty) {
          continue;
        }

        if (studentClassName.toUpperCase() !=
            className!.toUpperCase()) {
          continue;
        }

        // ======================================================
        // REGISTER NO ONLY
        // ======================================================

        final registerNo = data["registerNo"]
            ?.toString()
            .trim();

        if (registerNo == null || registerNo.isEmpty) {
          continue;
        }

        allStudents.add({
          // Internal only.
          // Never displayed in the UI.
          "uid": data["uid"] ?? doc.id,

          "name": data["name"] ?? "Student",

          "studentId": registerNo,

          "className": studentClassName,

          "department":
              data["department"] ?? department,

          "year":
              data["year"] ?? year,

          "section":
              data["section"] ?? section,
        });
      }

      // ========================================================
      // SORT STUDENTS BY REGISTER NUMBER
      // ========================================================

      allStudents.sort(
        (a, b) => a["studentId"]
            .toString()
            .compareTo(
              b["studentId"].toString(),
            ),
      );

      // ========================================================
      // 3. GET ATTENDANCE RECORDS
      // ========================================================

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection("attendance")
          .where(
            "sessionId",
            isEqualTo: widget.sessionId,
          )
          .get();

      attendanceMap = {};

      for (final doc in attendanceSnapshot.docs) {
        final data = doc.data();

        final studentId = data["studentId"];

        if (studentId == null) {
          continue;
        }

        final attendanceClassName = data["className"]
            ?.toString()
            .trim();

        // ======================================================
        // CLASS SAFETY CHECK
        // ======================================================

        if (attendanceClassName != null &&
            attendanceClassName.isNotEmpty &&
            className != null &&
            attendanceClassName.toUpperCase() !=
                className!.toUpperCase()) {
          continue;
        }

        attendanceMap[
            studentId.toString()] = data;
      }

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // MARK STUDENT ABSENT MANUALLY
  // ============================================================

  Future<void> markAbsent(
    Map<String, dynamic> student,
  ) async {
    final studentId = student["studentId"]
        .toString()
        .trim();

    if (studentId.isEmpty) {
      return;
    }

    // ==========================================================
    // ALREADY HAS ATTENDANCE
    // ==========================================================

    if (attendanceMap.containsKey(studentId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance already recorded.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ==========================================================
    // VERIFY STUDENT CLASS
    // ==========================================================

    final studentClassName = student["className"]
        ?.toString()
        .trim();

    if (studentClassName == null ||
        studentClassName.isEmpty ||
        className == null ||
        studentClassName.toUpperCase() !=
            className!.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Student does not belong to this class.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final attendanceId =
          "${studentId}_${widget.sessionId}";

      await FirebaseFirestore.instance
          .collection("attendance")
          .doc(attendanceId)
          .set({
        "attendanceId": attendanceId,

        "sessionId": widget.sessionId,

        // ======================================================
        // STUDENT INFORMATION
        // ======================================================

        "studentId": studentId,

        "studentName":
            student["name"] ?? "Student",

        "studentUid":
            student["uid"],

        // ======================================================
        // MAIN CLASS FIELD
        // ======================================================

        "className":
            studentClassName,

        // ======================================================
        // COMPATIBILITY FIELDS
        // ======================================================

        "department":
            student["department"] ?? department,

        "year":
            student["year"] ?? year,

        "section":
            student["section"] ?? section,

        // ======================================================
        // SESSION INFORMATION
        // ======================================================

        "subject":
            sessionSubject ??
                widget.subject,

        "teacher":
            sessionTeacher ?? "",

        "date":
            sessionDate ?? "",

        "time":
            sessionTime ?? "",

        // ======================================================
        // ATTENDANCE STATUS
        // ======================================================

        "status": "Absent",

        "createdAt":
            Timestamp.now(),
      });

      await loadAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${student["name"]} marked Absent",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subject),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    int presentCount = 0;
    int absentCount = 0;

    // ============================================================
    // CALCULATE ATTENDANCE
    // ============================================================

    for (final student in allStudents) {
      final studentId = student["studentId"]
          .toString();

      final attendance =
          attendanceMap[studentId];

      if (attendance != null &&
          attendance["status"] == "Present") {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    final totalCount = allStudents.length;

    final percentage = totalCount == 0
        ? 0.0
        : (presentCount / totalCount * 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: loadAttendance,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            // ==================================================
            // ATTENDANCE SUMMARY
            // ==================================================

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      "Attendance Summary",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Text(
                      "${percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _summaryBox(
                          "Total",
                          totalCount,
                          Colors.blue,
                        ),
                        _summaryBox(
                          "Present",
                          presentCount,
                          Colors.green,
                        ),
                        _summaryBox(
                          "Absent",
                          absentCount,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // CLASS INFORMATION
            // ==================================================

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Class Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "Class Name : "
                      "${className ?? "Not available"}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Department : "
                      "${department ?? "Not available"}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Year : "
                      "${year ?? "Not available"}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Section : "
                      "${section ?? "Not available"}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // STUDENT LIST
            // ==================================================

            if (allStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "No students found for this class.",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            ...allStudents.map(
              (student) {
                final studentId =
                    student["studentId"].toString();

                final attendance =
                    attendanceMap[studentId];

                final bool isPresent =
                    attendance != null &&
                        attendance["status"] ==
                            "Present";

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isPresent
                              ? Colors.green
                              : Colors.red,
                      child: Icon(
                        isPresent
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                      ),
                    ),

                    title: Text(
                      student["name"].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Register No : "
                          "${student["studentId"]}",
                        ),

                        Text(
                          "Status : "
                          "${isPresent ? "Present" : "Absent"}",
                          style: TextStyle(
                            color: isPresent
                                ? Colors.green
                                : Colors.red,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    trailing: isPresent
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          )
                        : IconButton(
                            tooltip:
                                "Mark Absent",
                            icon: const Icon(
                              Icons.person_off,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              markAbsent(student);
                            },
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY BOX
  // ============================================================

  Widget _summaryBox(
    String title,
    int value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}