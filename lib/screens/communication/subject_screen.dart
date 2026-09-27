import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'group_discussion_screen.dart';

class SubjectScreen extends StatelessWidget {
  SubjectScreen({super.key});

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Subject",
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("subjects")
            .orderBy("name")
            .snapshots(),

        builder: (context, snapshot) {
          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  "Error loading subjects:\n\n"
                  "${snapshot.error}",
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final subjects =
              snapshot.data?.docs ?? [];

          // ======================================================
          // EMPTY
          // ======================================================

          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .menu_book_outlined,
                      size: 80,
                      color:
                          Colors.grey.shade400,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      "No subjects available",
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      "Subjects added by the Mentor "
                      "will appear here.",
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // SUBJECT LIST
          // ======================================================

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount:
                subjects.length,
            itemBuilder:
                (context, index) {
              final document =
                  subjects[index];

              final data =
                  document.data()
                          as Map<String, dynamic>? ??
                      {};

              final String name =
                  data["name"]
                          ?.toString()
                          .trim() ??
                      "Unnamed Subject";

              final String code =
                  data["code"]
                          ?.toString()
                          .trim() ??
                      "";

              final String teacher =
                  data["teacher"]
                          ?.toString()
                          .trim() ??
                      "Teacher not assigned";

              final String department =
                  data["department"]
                          ?.toString()
                          .trim() ??
                      "";

              final String year =
                  data["year"]
                          ?.toString()
                          .trim() ??
                      "";

              final String section =
                  data["section"]
                          ?.toString()
                          .trim() ??
                      "";

              return Card(
                elevation: 3,
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),

                  // =================================================
                  // ICON
                  // =================================================

                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Colors.blue.shade100,
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),

                  // =================================================
                  // SUBJECT
                  // =================================================

                  title: Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  // =================================================
                  // DETAILS
                  // =================================================

                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        if (code.isNotEmpty)
                          Text(
                            code,
                            style:
                                TextStyle(
                              color: Colors
                                  .blue
                                  .shade700,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          "Teacher: $teacher",
                        ),

                        if (department
                                .isNotEmpty ||
                            year.isNotEmpty ||
                            section
                                .isNotEmpty)
                          const SizedBox(
                            height: 3,
                          ),

                        if (department
                                .isNotEmpty ||
                            year.isNotEmpty ||
                            section
                                .isNotEmpty)
                          Text(
                            "$department"
                            "${year.isNotEmpty ? " • $year" : ""}"
                            "${section.isNotEmpty ? " • Section $section" : ""}",
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize:
                                  12,
                            ),
                          ),

                        const SizedBox(
                          height: 5,
                        ),

                        const Text(
                          "Tap to open discussion",
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),

                  // =================================================
                  // OPEN CHAT
                  // =================================================

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupDiscussionScreen(
                          subjectName:
                              name,
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