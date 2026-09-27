import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  // ============================================================
  // GET CURRENT STUDENT
  // ============================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Subjects"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getStudentData(),
        builder: (context, studentSnapshot) {
          // ======================================================
          // STUDENT LOADING
          // ======================================================

          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ======================================================
          // STUDENT ERROR
          // ======================================================

          if (studentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading student information:\n\n"
                  "${studentSnapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ======================================================
          // STUDENT NOT FOUND
          // ======================================================

          final student = studentSnapshot.data;

          if (student == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Student information not found.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }

          // ======================================================
          // STUDENT DETAILS
          // ======================================================

          final String department =
              student["department"]?.toString().trim() ?? "";

          final String year =
              student["year"]?.toString().trim() ?? "";

          final String section =
              student["section"]?.toString().trim() ?? "";

          final String className =
              student["className"]?.toString().trim() ?? "";

          // ======================================================
          // SUBJECT STREAM
          //
          // Class Name is now the primary class identifier.
          //
          // Existing subject documents using only
          // department/year/section are still supported.
          // ======================================================

          final bool hasClassName = className.isNotEmpty;

          final Stream<QuerySnapshot<Map<String, dynamic>>> subjectStream;

          if (hasClassName) {
            subjectStream = FirebaseFirestore.instance
                .collection("subjects")
                .where(
                  "className",
                  isEqualTo: className,
                )
                .snapshots();
          } else {
            subjectStream = FirebaseFirestore.instance
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
                .snapshots();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: subjectStream,
            builder: (context, subjectSnapshot) {
              // ==================================================
              // SUBJECT ERROR
              // ==================================================

              if (subjectSnapshot.hasError) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Error loading subjects:\n\n"
                      "${subjectSnapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }

              // ==================================================
              // SUBJECT LOADING
              // ==================================================

              if (subjectSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final subjects = subjectSnapshot.data?.docs ?? [];

              // ==================================================
              // NO SUBJECTS
              // ==================================================

              if (subjects.isEmpty) {
                final String classDescription = hasClassName
                    ? "for class $className"
                    : "for $department • $year • Section $section";

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "No Subjects Found",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No subjects are currently available "
                          "$classDescription.",
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
              // RESPONSIVE SUBJECT LIST
              // ==================================================

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double screenWidth = constraints.maxWidth;

                  final bool smallScreen = screenWidth < 360;

                  final double horizontalPadding =
                      smallScreen ? 10 : 15;

                  final double cardPadding = smallScreen ? 10 : 14;

                  final double titleSize = smallScreen ? 16 : 18;

                  final double iconRadius = smallScreen ? 24 : 28;

                  final double iconSize = smallScreen ? 26 : 30;

                  return ListView.builder(
                    padding: EdgeInsets.all(
                      horizontalPadding,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final document = subjects[index];

                      final data = document.data();

                      final String name =
                          data["name"]?.toString().trim() ?? "Subject";

                      final String code =
                          data["code"]?.toString().trim() ?? "N/A";

                      final String teacher =
                          data["teacher"]?.toString().trim() ??
                              "Not Assigned";

                      final String subjectDepartment =
                          data["department"]?.toString().trim() ??
                              department;

                      final String subjectYear =
                          data["year"]?.toString().trim() ?? year;

                      final String subjectSection =
                          data["section"]?.toString().trim() ?? section;

                      final String subjectClassName =
                          data["className"]?.toString().trim() ??
                              className;

                      // ==========================================
                      // SUBJECT CARD
                      // ==========================================

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            cardPadding,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // ==================================
                              // SUBJECT ICON
                              // ==================================

                              CircleAvatar(
                                radius: iconRadius,
                                backgroundColor:
                                    Colors.orange.shade100,
                                child: Icon(
                                  Icons.menu_book,
                                  color: Colors.orange,
                                  size: iconSize,
                                ),
                              ),

                              SizedBox(
                                width: smallScreen ? 10 : 14,
                              ),

                              // ==================================
                              // SUBJECT INFORMATION
                              // ==================================

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // ----------------------------
                                    // SUBJECT NAME
                                    // ----------------------------

                                    Text(
                                      name,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: titleSize,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // ----------------------------
                                    // CODE
                                    // ----------------------------

                                    Text(
                                      "Code: $code",
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // ----------------------------
                                    // TEACHER
                                    // ----------------------------

                                    Text(
                                      "Teacher: $teacher",
                                      softWrap: true,
                                    ),

                                    const SizedBox(height: 4),

                                    // ----------------------------
                                    // CLASS NAME
                                    // ----------------------------

                                    if (subjectClassName.isNotEmpty)
                                      Text(
                                        "Class: $subjectClassName",
                                        softWrap: true,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                    if (subjectClassName.isNotEmpty)
                                      const SizedBox(height: 3),

                                    // ----------------------------
                                    // COMPATIBILITY CLASS DETAILS
                                    // ----------------------------

                                    Text(
                                      "$subjectDepartment • "
                                      "$subjectYear Year • "
                                      "Section $subjectSection",
                                      softWrap: true,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
          );
        },
      ),
    );
  }
}