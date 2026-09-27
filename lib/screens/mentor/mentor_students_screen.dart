import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'mentor_student_detail_screen.dart';

class MentorStudentsScreen extends StatelessWidget {
  const MentorStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Students"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: currentUser == null
          ? const _MessageView(
              icon: Icons.lock_outline,
              title: "Not signed in",
              message: "Please log in again to view your students.",
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where(
                    "mentorUid",
                    isEqualTo: currentUser.uid,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                // =================================================
                // ERROR
                // =================================================

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error loading students:\n\n"
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                // =================================================
                // LOADING
                // =================================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // =================================================
                // GET STUDENTS
                // =================================================

                final students = snapshot.data?.docs ?? [];

                // =================================================
                // FILTER STUDENTS
                // =================================================
                //
                // mentorUid is the primary assignment.
                // We also verify that the document is a Student.
                //
                // =================================================

                final assignedStudents = students.where((student) {
                  final data = student.data();

                  return data["role"]?.toString().trim() == "Student";
                }).toList();

                // =================================================
                // NO STUDENTS
                // =================================================

                if (assignedStudents.isEmpty) {
                  return const _MessageView(
                    icon: Icons.people_outline,
                    title: "No students assigned",
                    message:
                        "No students are currently assigned "
                        "to your mentor account.",
                  );
                }

                // =================================================
                // STUDENT LIST
                // =================================================

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: assignedStudents.length,

                  itemBuilder: (context, index) {
                    final student = assignedStudents[index];
                    final data = student.data();

                    // =================================================
                    // STUDENT NAME
                    // =================================================

                    final String name =
                        data["name"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["name"].toString().trim()
                            : "No Name";

                    // =================================================
                    // EMAIL
                    // =================================================

                    final String email =
                        data["email"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["email"].toString().trim()
                            : "No Email";

                    // =================================================
                    // REGISTER NUMBER
                    // =================================================

                    final String registerNo =
                        data["registerNo"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["registerNo"].toString().trim()
                            : "N/A";

                    // =================================================
                    // PARENT PHONE
                    // =================================================

                    final String parentPhone =
                        data["parentPhone"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["parentPhone"].toString().trim()
                            : "Not Added";

                    // =================================================
                    // DEPARTMENT
                    // =================================================

                    final String department =
                        data["department"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["department"].toString().trim()
                            : "N/A";

                    // =================================================
                    // YEAR
                    // =================================================

                    final String year =
                        data["year"]?.toString().trim().isNotEmpty == true
                            ? data["year"].toString().trim()
                            : "N/A";

                    // =================================================
                    // SECTION
                    // =================================================

                    final String section =
                        data["section"]?.toString().trim().isNotEmpty ==
                                true
                            ? data["section"].toString().trim()
                            : "N/A";

                    // =================================================
                    // INITIAL
                    // =================================================

                    final String initial =
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : "S";

                    // =================================================
                    // STUDENT CARD
                    // =================================================

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),

                        // =================================================
                        // PROFILE ICON
                        // =================================================

                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),

                        // =================================================
                        // NAME
                        // =================================================

                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // =================================================
                        // STUDENT DETAILS
                        // =================================================

                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Register Number
                              Row(
                                children: [
                                  const Icon(
                                    Icons.assignment_ind_outlined,
                                    size: 16,
                                    color: Colors.indigo,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Register No: $registerNo",
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Parent Phone
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color:
                                        parentPhone == "Not Added"
                                            ? Colors.grey
                                            : Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Parent: $parentPhone",
                                      style: TextStyle(
                                        color:
                                            parentPhone ==
                                                    "Not Added"
                                                ? Colors.grey
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Department / Year / Section
                              Row(
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "$department • "
                                      "$year Year • "
                                      "Section $section",
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Email
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // =================================================
                        // OPEN DETAILS
                        // =================================================

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MentorStudentDetailScreen(
                                studentData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ================================================================
// MESSAGE VIEW
// ================================================================

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.grey,
            ),

            const SizedBox(height: 15),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}