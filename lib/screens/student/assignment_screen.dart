import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'submit_assignment_screen.dart';

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({super.key});

  // ============================================================
  // GET CURRENT STUDENT DATA
  // ============================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where(
            "uid",
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.data();
    } catch (e) {
      debugPrint("Error getting student profile: $e");
      return null;
    }
  }

  // ============================================================
  // CHECK WHETHER ASSIGNMENT BELONGS TO STUDENT
  // ============================================================

  bool assignmentMatchesStudent({
    required Map<String, dynamic> assignment,
    required String className,
    required String department,
    required String year,
    required String section,
  }) {
    // ------------------------------------------------------------
    // CLASS NAME IS PRIMARY
    // ------------------------------------------------------------

    final String assignmentClassName =
        assignment["className"]?.toString().trim() ?? "";

    if (assignmentClassName.isNotEmpty) {
      return className.isNotEmpty &&
          assignmentClassName.toLowerCase() ==
              className.toLowerCase();
    }

    // ------------------------------------------------------------
    // OLD FORMAT COMPATIBILITY
    // ------------------------------------------------------------

    final String assignmentDepartment =
        assignment["department"]?.toString().trim() ?? "";

    final String assignmentYear =
        assignment["year"]?.toString().trim() ?? "";

    final String assignmentSection =
        assignment["section"]?.toString().trim() ?? "";

    // If the old assignment has no targeting information,
    // preserve the previous behaviour and allow it.
    final bool hasOldTargeting =
        assignmentDepartment.isNotEmpty ||
        assignmentYear.isNotEmpty ||
        assignmentSection.isNotEmpty;

    if (!hasOldTargeting) {
      return true;
    }

    if (assignmentDepartment.isNotEmpty &&
        assignmentDepartment.toLowerCase() !=
            department.toLowerCase()) {
      return false;
    }

    if (assignmentYear.isNotEmpty &&
        assignmentYear.toLowerCase() !=
            year.toLowerCase()) {
      return false;
    }

    if (assignmentSection.isNotEmpty &&
        assignmentSection.toLowerCase() !=
            section.toLowerCase()) {
      return false;
    }

    return true;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // SCREEN WIDTH
    // ============================================================

    final double screenWidth =
        MediaQuery.of(context).size.width;

    final double titleSize =
        screenWidth < 360 ? 18 : 20;

    final double subjectSize =
        screenWidth < 360 ? 14 : 15;

    final double bodySize =
        screenWidth < 360 ? 13 : 14;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assignments"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ==========================================================
      // GET STUDENT
      // ==========================================================

      body: FutureBuilder<Map<String, dynamic>?>(
        future: getStudentData(),
        builder: (context, studentSnapshot) {
          // ========================================================
          // STUDENT LOADING
          // ========================================================

          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ========================================================
          // STUDENT ERROR
          // ========================================================

          if (studentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Unable to load student information.\n\n"
                  "${studentSnapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ========================================================
          // STUDENT NOT FOUND
          // ========================================================

          final student = studentSnapshot.data;

          if (student == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Student information not found.\n\n"
                  "Please contact your administrator.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }

          // ========================================================
          // STUDENT CLASS INFORMATION
          // ========================================================

          final String className =
              student["className"]?.toString().trim() ?? "";

          final String department =
              student["department"]?.toString().trim() ?? "";

          final String year =
              student["year"]?.toString().trim() ?? "";

          final String section =
              student["section"]?.toString().trim() ?? "";

          // ========================================================
          // ASSIGNMENTS
          // ========================================================

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("assignments")
                .orderBy("dueDate")
                .snapshots(),
            builder: (context, snapshot) {
              // ====================================================
              // ERROR
              // ====================================================

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Unable to load assignments.\n\n"
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }

              // ====================================================
              // LOADING
              // ====================================================

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // ====================================================
              // FILTER ASSIGNMENTS FOR CURRENT STUDENT
              // ====================================================

              final allAssignments =
                  snapshot.data?.docs ?? [];

              final assignments =
                  allAssignments.where((document) {
                final data = document.data();

                return assignmentMatchesStudent(
                  assignment: data,
                  className: className,
                  department: department,
                  year: year,
                  section: section,
                );
              }).toList();

              // ====================================================
              // NO DATA
              // ====================================================

              if (assignments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 75,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "No Assignments Available",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          className.isNotEmpty
                              ? "No assignments are currently "
                                  "available for $className."
                              : "No assignments are currently "
                                  "available for your class.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ====================================================
              // ASSIGNMENT LIST
              // ====================================================

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final document =
                      assignments[index];

                  final data = document.data();

                  // ==================================================
                  // SAFE DATA
                  // ==================================================

                  final String title =
                      data["title"]?.toString() ??
                          "Untitled Assignment";

                  final String subject =
                      data["subject"]?.toString() ??
                          "Subject";

                  final String description =
                      data["description"]?.toString() ??
                          "No description available.";

                  // ==================================================
                  // SAFE DUE DATE
                  // ==================================================

                  String dueText =
                      "Due date unavailable";

                  if (data["dueDate"] is Timestamp) {
                    final Timestamp due =
                        data["dueDate"] as Timestamp;

                    dueText =
                        "Due: ${DateFormat('dd MMM yyyy').format(due.toDate())}";
                  }

                  // ==================================================
                  // ASSIGNMENT CARD
                  // ==================================================

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(
                      bottom: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // ========================================
                          // TITLE
                          // ========================================

                          Text(
                            title,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ========================================
                          // SUBJECT
                          // ========================================

                          Text(
                            subject,
                            softWrap: true,
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: subjectSize,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ========================================
                          // CLASS NAME
                          // ========================================

                          if (data["className"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 8,
                              ),
                              child: Text(
                                "Class: ${data["className"]}",
                                softWrap: true,
                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),

                          // ========================================
                          // DESCRIPTION
                          // ========================================

                          Text(
                            description,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: bodySize,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // ========================================
                          // DUE DATE
                          // ========================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dueText,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // ========================================
                          // SUBMIT BUTTON
                          // ========================================

                          SizedBox(
                            width: double.infinity,
                            child:
                                ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SubmitAssignmentScreen(
                                      assignmentId:
                                          document.id,
                                      assignmentTitle:
                                          title,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.upload_file,
                              ),
                              label: const Text(
                                "Submit Assignment",
                              ),
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 13,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}