import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'anonymous_doubt_screen.dart';

class AnonymousSubjectScreen extends StatelessWidget {
  const AnonymousSubjectScreen({super.key});

  // ==========================================================
  // GET LOGGED-IN STUDENT PROFILE
  // ==========================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    // IMPORTANT:
    // Your users documents use Auto-ID.
    // The Firebase Auth UID is stored in the "uid" field.
    final result = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Anonymous Doubts",
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: getStudentData(),
        builder: (context, studentSnapshot) {
          // ====================================================
          // LOADING STUDENT
          // ====================================================

          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (studentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading student:\n\n"
                  "${studentSnapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ====================================================
          // STUDENT NOT FOUND
          // ====================================================

          final student = studentSnapshot.data;

          if (student == null) {
            return const Center(
              child: Text(
                "Student information not found.",
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // ====================================================
          // STUDENT DETAILS
          // ====================================================

          final String department =
              student["department"]?.toString().trim() ?? "";

          final String year =
              student["year"]?.toString().trim() ?? "";

          final String section =
              student["section"]?.toString().trim() ?? "";

          // ====================================================
          // LOAD SAME SUBJECTS AS MY SUBJECTS SCREEN
          // ====================================================

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("subjects")
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
                .snapshots(),

            builder: (context, subjectSnapshot) {
              // ==================================================
              // LOADING
              // ==================================================

              if (subjectSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // ==================================================
              // ERROR
              // ==================================================

              if (subjectSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Error loading subjects:\n\n"
                      "${subjectSnapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final subjects =
                  subjectSnapshot.data?.docs ?? [];

              // ==================================================
              // NO SUBJECTS
              // ==================================================

              if (subjects.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 75,
                          color: Colors.grey.shade400,
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "No Subjects Found",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "$department • $year • Section $section",
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

              // ==================================================
              // SUBJECT LIST
              // ==================================================

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final data =
                      subjects[index].data()
                          as Map<String, dynamic>;

                  final String subjectName =
                      data["name"]?.toString().trim() ??
                          "Subject";

                  final String subjectCode =
                      data["code"]?.toString().trim() ??
                          "N/A";

                  final String teacher =
                      data["teacher"]?.toString().trim() ??
                          "Not Assigned";

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(14),

                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.visibility_off_rounded,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),

                      title: Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),

                          Text(
                            "Code: $subjectCode",
                          ),

                          const SizedBox(height: 3),

                          Text(
                            "Teacher: $teacher",
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            "Open anonymous group chat",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 17,
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AnonymousDoubtScreen(
                              subject: subjectName,
                            ),
                          ),
                        );
                      },
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