import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_performance_screen.dart';

class MentorStudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const MentorStudentDetailScreen({
    super.key,
    required this.studentData,
  });

  String getValue(String key, String fallback) {
    final value = studentData[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = getValue("name", "Student");
    final email = getValue("email", "N/A");
    final department = getValue("department", "N/A");
    final year = getValue("year", "N/A");
    final section = getValue("section", "N/A");
    final registerNo = getValue("registerNo", "N/A");
    final parentPhone = getValue("parentPhone", "N/A");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Details"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // STUDENT HEADER
            // ====================================================

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : "S",
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Student • $department • "
                      "$year Year • Section $section",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Register No: $registerNo",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // STUDENT INFORMATION
            // ====================================================

            const Text(
              "Student Information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.badge,
                      "Register Number",
                      registerNo,
                    ),
                    _divider(),
                    _detailRow(
                      Icons.school,
                      "Department",
                      department,
                    ),
                    _divider(),
                    _detailRow(
                      Icons.calendar_month,
                      "Year",
                      year,
                    ),
                    _divider(),
                    _detailRow(
                      Icons.class_,
                      "Section",
                      section,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // CONTACT INFORMATION
            // ====================================================

            const Text(
              "Contact Information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.email,
                      "Student Email",
                      email,
                    ),
                    _divider(),
                    _detailRow(
                      Icons.phone,
                      "Parent Phone",
                      parentPhone,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ====================================================
            // STUDENT OVERVIEW
            // ====================================================

            const Text(
              "Academic Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Live information from the student's academic records.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 15),

            // ====================================================
            // LIVE ACADEMIC DATA
            // ====================================================

            _AcademicOverview(
              studentData: studentData,
            ),

            const SizedBox(height: 25),

            // ====================================================
            // PERFORMANCE
            // ====================================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.analytics,
                ),
                label: const Text(
                  "View Performance Dashboard",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentPerformanceScreen(
                        studentData: studentData,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  static Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 25,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  static Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Divider(
        height: 1,
      ),
    );
  }
}

// ================================================================
// ACADEMIC OVERVIEW
// ================================================================

class _AcademicOverview extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const _AcademicOverview({
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // REGISTER NO IS THE ONLY STUDENT IDENTIFIER
    // ------------------------------------------------------------

    final registerNo =
        studentData["registerNo"]?.toString().trim() ?? "";

    final department =
        studentData["department"]?.toString().trim() ?? "";

    final year =
        studentData["year"]?.toString().trim() ?? "";

    final section =
        studentData["section"]?.toString().trim() ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("attendance")
          .where(
            "studentId",
            isEqualTo: registerNo,
          )
          .snapshots(),
      builder: (context, attendanceSnapshot) {
        if (attendanceSnapshot.hasError) {
          return _errorCard(
            "Unable to load attendance information.",
          );
        }

        if (attendanceSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingOverview();
        }

        final attendanceDocs =
            attendanceSnapshot.data?.docs ?? [];

        int present = 0;
        int absent = 0;
        int leave = 0;

        for (final doc in attendanceDocs) {
          final data = doc.data();

          final status =
              data["status"]?.toString().trim().toLowerCase() ?? "";

          if (status == "present") {
            present++;
          } else if (status == "absent") {
            absent++;
          } else if (status == "leave" ||
              status == "on leave") {
            leave++;
          }
        }

        final totalAttendance =
            present + absent + leave;

        final double attendancePercentage =
            totalAttendance == 0
                ? 0
                : (present / totalAttendance) * 100;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("leave_requests")
              .where(
                "studentId",
                isEqualTo: registerNo,
              )
              .snapshots(),
          builder: (context, leaveSnapshot) {
            if (leaveSnapshot.hasError) {
              return _errorCard(
                "Unable to load leave information.",
              );
            }

            if (leaveSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingOverview();
            }

            final leaveDocs =
                leaveSnapshot.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("assignments")
                  .snapshots(),
              builder: (context, assignmentSnapshot) {
                if (assignmentSnapshot.hasError) {
                  return _errorCard(
                    "Unable to load assignment information.",
                  );
                }

                if (assignmentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _LoadingOverview();
                }

                final assignmentDocs =
                    assignmentSnapshot.data?.docs ?? [];

                final studentAssignments =
                    _filterAssignments(
                  assignmentDocs,
                  studentData,
                );

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("subjects")
                      .snapshots(),
                  builder: (context, subjectSnapshot) {
                    if (subjectSnapshot.hasError) {
                      return _errorCard(
                        "Unable to load subject information.",
                      );
                    }

                    if (subjectSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _LoadingOverview();
                    }

                    final subjectDocs =
                        subjectSnapshot.data?.docs ?? [];

                    final studentSubjects =
                        _filterSubjects(
                      subjectDocs,
                      department,
                      year,
                      section,
                    );

                    return Column(
                      children: [
                        // ==========================================
                        // ATTENDANCE
                        // ==========================================

                        SizedBox(
                          width: double.infinity,
                          child: _AttendanceCard(
                            present: present,
                            absent: absent,
                            leave: leave,
                            percentage: attendancePercentage,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==========================================
                        // OTHER OVERVIEW CARDS
                        // ==========================================

                        Row(
                          children: [
                            Expanded(
                              child: _OverviewCard(
                                title: "Assignments",
                                value:
                                    studentAssignments.length.toString(),
                                subtitle: "Available records",
                                icon: Icons.assignment_outlined,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OverviewCard(
                                title: "Leave",
                                value: leaveDocs.length.toString(),
                                subtitle: "Requests",
                                icon:
                                    Icons.event_available_outlined,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _OverviewCard(
                                title: "Subjects",
                                value:
                                    studentSubjects.length.toString(),
                                subtitle: "Class subjects",
                                icon:
                                    Icons.menu_book_outlined,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OverviewCard(
                                title: "Attendance Days",
                                value:
                                    totalAttendance.toString(),
                                subtitle: "Recorded",
                                icon:
                                    Icons.calendar_today_outlined,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ASSIGNMENT FILTER
  // ============================================================

  static List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterAssignments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, dynamic> studentData,
  ) {
    final registerNo =
        studentData["registerNo"]?.toString().trim() ?? "";

    final department =
        studentData["department"]?.toString().trim() ?? "";

    final year =
        studentData["year"]?.toString().trim() ?? "";

    final section =
        studentData["section"]?.toString().trim() ?? "";

    final result =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in docs) {
      final data = doc.data();

      final assignmentStudentId =
          data["studentId"]?.toString().trim() ?? "";

      final assignmentRegisterNo =
          data["registerNo"]?.toString().trim() ?? "";

      final assignmentDepartment =
          data["department"]?.toString().trim() ?? "";

      final assignmentYear =
          data["year"]?.toString().trim() ?? "";

      final assignmentSection =
          data["section"]?.toString().trim() ?? "";

      bool matches = false;

      // ----------------------------------------------------------
      // Direct student assignment using Register No.
      // ----------------------------------------------------------

      if (assignmentStudentId.isNotEmpty &&
          assignmentStudentId == registerNo) {
        matches = true;
      }

      // ----------------------------------------------------------
      // Direct register-number assignment.
      // ----------------------------------------------------------

      if (!matches &&
          assignmentRegisterNo.isNotEmpty &&
          assignmentRegisterNo == registerNo) {
        matches = true;
      }

      // ----------------------------------------------------------
      // Class-level assignment.
      // ----------------------------------------------------------

      if (!matches &&
          assignmentDepartment.isNotEmpty &&
          assignmentYear.isNotEmpty &&
          assignmentSection.isNotEmpty &&
          assignmentDepartment == department &&
          assignmentYear == year &&
          assignmentSection == section) {
        matches = true;
      }

      if (matches) {
        result.add(doc);
      }
    }

    return result;
  }

  // ============================================================
  // SUBJECT FILTER
  // ============================================================

  static List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterSubjects(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String department,
    String year,
    String section,
  ) {
    final result =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in docs) {
      final data = doc.data();

      final subjectDepartment =
          data["department"]?.toString().trim() ?? "";

      final subjectYear =
          data["year"]?.toString().trim() ?? "";

      final subjectSection =
          data["section"]?.toString().trim() ?? "";

      final departmentMatches =
          subjectDepartment.isEmpty ||
              subjectDepartment == department;

      final yearMatches =
          subjectYear.isEmpty ||
              subjectYear == year;

      final sectionMatches =
          subjectSection.isEmpty ||
              subjectSection == section;

      if (departmentMatches &&
          yearMatches &&
          sectionMatches) {
        result.add(doc);
      }
    }

    return result;
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  static Widget _errorCard(String message) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ATTENDANCE CARD
// ================================================================

class _AttendanceCard extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;
  final double percentage;

  const _AttendanceCard({
    required this.present,
    required this.absent,
    required this.leave,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Attendance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${percentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 9,
                backgroundColor:
                    Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _AttendanceItem(
                    label: "Present",
                    value: present,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _AttendanceItem(
                    label: "Absent",
                    value: absent,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _AttendanceItem(
                    label: "Leave",
                    value: leave,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ATTENDANCE ITEM
// ================================================================

class _AttendanceItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// OVERVIEW CARD
// ================================================================

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LOADING OVERVIEW
// ================================================================

class _LoadingOverview extends StatelessWidget {
  const _LoadingOverview();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}