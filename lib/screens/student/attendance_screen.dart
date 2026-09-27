import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  // ============================================================
  // GET CURRENT STUDENT REGISTER NO
  // ============================================================

  Future<String?> getStudentId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    // ------------------------------------------------------------
    // GET USER PROFILE
    // ------------------------------------------------------------

    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where(
            "uid",
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();

        final registerNo = data["registerNo"]?.toString().trim();

        if (registerNo != null && registerNo.isNotEmpty) {
          return registerNo;
        }
      }
    } catch (e) {
      debugPrint("Error getting student profile: $e");
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String?>(
        future: getStudentId(),
        builder: (context, studentSnapshot) {
          // ------------------------------------------------------
          // LOADING STUDENT
          // ------------------------------------------------------

          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (studentSnapshot.hasError) {
            return Center(
              child: Text(
                "Unable to get student information.\n"
                "${studentSnapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // ------------------------------------------------------
          // REGISTER NO NOT FOUND
          // ------------------------------------------------------

          final studentId = studentSnapshot.data;

          if (studentId == null || studentId.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Student Register No not found",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Please contact your administrator.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ------------------------------------------------------
          // LOAD ATTENDANCE
          // ------------------------------------------------------

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("attendance")
                .where(
                  "studentId",
                  isEqualTo: studentId,
                )
                .snapshots(),
            builder: (context, snapshot) {
              // --------------------------------------------------
              // FIRESTORE ERROR
              // --------------------------------------------------

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Error loading attendance:\n"
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // --------------------------------------------------
              // LOADING
              // --------------------------------------------------

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // --------------------------------------------------
              // NO DATA
              // --------------------------------------------------

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fact_check_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "No attendance available",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Register No: $studentId",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // --------------------------------------------------
              // GET DOCUMENTS
              // --------------------------------------------------

              final docs = snapshot.data!.docs;

              // --------------------------------------------------
              // OVERALL COUNTS
              // --------------------------------------------------

              final int totalClasses = docs.length;
              int totalPresent = 0;

              for (final doc in docs) {
                final data = doc.data();

                final status =
                    data["status"]?.toString().toLowerCase() ?? "";

                if (status == "present") {
                  totalPresent++;
                }
              }

              final int totalAbsent = totalClasses - totalPresent;

              final double overallPercentage = totalClasses == 0
                  ? 0
                  : (totalPresent / totalClasses) * 100;

              // --------------------------------------------------
              // OVERALL COLOR
              // --------------------------------------------------

              Color overallColor = Colors.green;

              if (overallPercentage < 75) {
                overallColor = Colors.red;
              } else if (overallPercentage < 90) {
                overallColor = Colors.orange;
              }

              // --------------------------------------------------
              // SUBJECT-WISE ATTENDANCE
              // --------------------------------------------------

              final Map<String, List<Map<String, dynamic>>> subjectData =
                  {};

              for (final doc in docs) {
                final data = doc.data();

                final subject =
                    data["subject"]?.toString() ?? "Unknown Subject";

                subjectData.putIfAbsent(
                  subject,
                  () => [],
                );

                subjectData[subject]!.add(data);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ==================================================
                    // OVERALL ATTENDANCE CARD
                    // ==================================================

                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fact_check,
                              color: overallColor,
                              size: 60,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Overall Attendance",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${overallPercentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 40,
                                color: overallColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$totalPresent Present  •  "
                              "$totalAbsent Absent",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "$totalClasses Total Classes",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 15),
                            LinearProgressIndicator(
                              value: overallPercentage / 100,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                              color: overallColor,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // SUBJECT-WISE
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Subject-wise Attendance",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // SUBJECT LIST
                    // ==================================================

                    Expanded(
                      child: ListView.builder(
                        itemCount: subjectData.length,
                        itemBuilder: (context, index) {
                          final subject =
                              subjectData.keys.elementAt(index);

                          final records = subjectData[subject]!;

                          int subjectPresent = 0;

                          for (final record in records) {
                            final status =
                                record["status"]?.toString().toLowerCase() ??
                                    "";

                            if (status == "present") {
                              subjectPresent++;
                            }
                          }

                          final int subjectTotal = records.length;

                          final int subjectAbsent =
                              subjectTotal - subjectPresent;

                          final double percentage = subjectTotal == 0
                              ? 0
                              : (subjectPresent / subjectTotal) * 100;

                          // ------------------------------------------
                          // COLOR
                          // ------------------------------------------

                          Color color = Colors.green;

                          if (percentage < 75) {
                            color = Colors.red;
                          } else if (percentage < 90) {
                            color = Colors.orange;
                          }

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // ----------------------------
                                      // CIRCLE
                                      // ----------------------------

                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: color,
                                        child: Text(
                                          "${percentage.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 15),

                                      // ----------------------------
                                      // SUBJECT
                                      // ----------------------------

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              subject,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "$subjectPresent Present  •  "
                                              "$subjectAbsent Absent",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ----------------------------
                                      // COUNT
                                      // ----------------------------

                                      Text(
                                        "$subjectPresent/$subjectTotal",
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // ------------------------------
                                  // PROGRESS BAR
                                  // ------------------------------

                                  LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(10),
                                    color: color,
                                    backgroundColor: Colors.grey.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}