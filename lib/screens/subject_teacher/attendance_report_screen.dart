import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'attendance_students_screen.dart';

class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("attendance_sessions")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Unable to load attendance reports.\n\n"
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sessions =
              snapshot.data?.docs ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                "No Attendance Sessions",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final doc = sessions[index];

              final data = doc.data();

              // ==================================================
              // SESSION ID
              // ==================================================

              final sessionId =
                  data["sessionId"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                      ? data["sessionId"]
                          .toString()
                          .trim()
                      : doc.id;

              // ==================================================
              // CLASS NAME
              // ==================================================

              final className =
                  data["className"]
                      ?.toString()
                      .trim();

              // ==================================================
              // COMPATIBILITY FIELDS
              // ==================================================

              final department =
                  data["department"]
                      ?.toString()
                      .trim();

              final year =
                  data["year"]
                      ?.toString()
                      .trim();

              final section =
                  data["section"]
                      ?.toString()
                      .trim();

              // ==================================================
              // SUBJECT
              // ==================================================

              final subject =
                  data["subject"]
                      ?.toString()
                      .trim() ??
                  "";

              // ==================================================
              // CREATED DATE
              // ==================================================

              final createdAt =
                  data["createdAt"];

              final Timestamp? created =
                  createdAt is Timestamp
                      ? createdAt
                      : null;

              return Card(
                elevation: 5,
                margin:
                    const EdgeInsets.only(
                  bottom: 15,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),

                  // ==================================================
                  // ICON
                  // ==================================================

                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        Colors.blue,
                    child: Icon(
                      Icons.qr_code,
                      color:
                          Colors.white,
                    ),
                  ),

                  // ==================================================
                  // SUBJECT
                  // ==================================================

                  title: Text(
                    subject.isEmpty
                        ? "Attendance Session"
                        : subject,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  // ==================================================
                  // INFORMATION
                  // ==================================================

                  subtitle:
                      Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        // ==================================================
                        // PRIMARY CLASS IDENTIFIER
                        // ==================================================

                        if (className != null &&
                            className.isNotEmpty)
                          Text(
                            "Class : $className",
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.blue,
                            ),
                          )
                        else
                          const Text(
                            "Class : Not available",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.red,
                            ),
                          ),

                        // ==================================================
                        // COMPATIBILITY INFORMATION
                        // ==================================================

                        if ((department != null &&
                                department
                                    .isNotEmpty) ||
                            (year != null &&
                                year.isNotEmpty) ||
                            (section != null &&
                                section
                                    .isNotEmpty))
                          Text(
                            [
                              if (department != null &&
                                  department
                                      .isNotEmpty)
                                department,
                              if (year != null &&
                                  year.isNotEmpty)
                                "$year Year",
                              if (section != null &&
                                  section.isNotEmpty)
                                "Section $section",
                            ].join(" • "),
                          ),

                        const SizedBox(
                          height: 5,
                        ),

                        // ==================================================
                        // CREATED DATE
                        // ==================================================

                        if (created != null)
                          Text(
                            DateFormat(
                              "dd MMM yyyy • hh:mm a",
                            ).format(
                              created.toDate(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // OPEN REPORT
                  // ==================================================

                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AttendanceStudentsScreen(
                          sessionId:
                              sessionId,
                          subject:
                              subject,
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