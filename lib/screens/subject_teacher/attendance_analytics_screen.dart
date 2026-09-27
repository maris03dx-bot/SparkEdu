import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Analytics"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("attendance_sessions")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Unable to load attendance sessions.\n\n"
                  "${sessionSnapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (sessionSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sessions =
              sessionSnapshot.data?.docs ?? [];

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("attendance")
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Unable to load attendance records.\n\n"
                      "${attendanceSnapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final attendance =
                  attendanceSnapshot.data?.docs ?? [];

              // ==================================================
              // BASIC ANALYTICS
              // ==================================================

              final int totalSessions =
                  sessions.length;

              // ==================================================
              // CLASS LIST
              // ==================================================

              final Set<String> uniqueClasses = {};

              for (final doc in sessions) {
                final data = doc.data();

                final sessionClassName =
                    data["className"]
                        ?.toString()
                        .trim();

                if (sessionClassName != null &&
                    sessionClassName.isNotEmpty) {
                  uniqueClasses.add(
                    sessionClassName,
                  );
                }
              }

              // ==================================================
              // UNIQUE STUDENTS
              // ==================================================

              final Set<String> uniqueStudents = {};

              for (final doc in attendance) {
                final data = doc.data();

                final studentId =
                    data["studentId"]
                        ?.toString()
                        .trim();

                if (studentId != null &&
                    studentId.isNotEmpty) {
                  uniqueStudents.add(
                    studentId,
                  );
                }
              }

              // ==================================================
              // VALID ATTENDANCE RECORDS
              // ==================================================

              int totalPresent = 0;
              int totalAbsent = 0;

              for (final doc in attendance) {
                final data = doc.data();

                final status =
                    data["status"]
                        ?.toString()
                        .trim()
                        .toLowerCase();

                if (status == "present") {
                  totalPresent++;
                } else if (status == "absent") {
                  totalAbsent++;
                }
              }

            

              // ==================================================
              // AVERAGE ATTENDANCE PER SESSION
              // ==================================================

              final double average =
                  totalSessions == 0
                      ? 0
                      : totalPresent /
                          totalSessions;

              // ==================================================
              // SESSION ANALYTICS
              // ==================================================

              final List<Map<String, dynamic>>
                  sessionAnalytics = [];

              for (final doc in sessions) {
                final data = doc.data();

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

                final sessionClassName =
                    data["className"]
                            ?.toString()
                            .trim() ??
                        "";

                final subject =
                    data["subject"]
                            ?.toString()
                            .trim() ??
                        "";

                int present = 0;
                int absent = 0;

                for (final attendanceDoc
                    in attendance) {
                  final attendanceData =
                      attendanceDoc.data();

                  final attendanceSessionId =
                      attendanceData[
                              "sessionId"]
                          ?.toString()
                          .trim();

                  if (attendanceSessionId !=
                      sessionId) {
                    continue;
                  }

                  final status =
                      attendanceData[
                              "status"]
                          ?.toString()
                          .trim()
                          .toLowerCase();

                  if (status == "present") {
                    present++;
                  } else if (status == "absent") {
                    absent++;
                  }
                }

                final int total =
                    present + absent;

                final double percentage =
                    total == 0
                        ? 0
                        : present /
                            total *
                            100;

                sessionAnalytics.add({
                  "sessionId":
                      sessionId,
                  "className":
                      sessionClassName,
                  "subject":
                      subject,
                  "present":
                      present,
                  "absent":
                      absent,
                  "total":
                      total,
                  "percentage":
                      percentage,
                });
              }

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Card(
                      elevation: 4,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.blue,
                              child: Icon(
                                Icons.analytics,
                                color:
                                    Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text(
                                    "Attendance Overview",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          21,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    "${uniqueClasses.length} class"
                                    "${uniqueClasses.length == 1 ? "" : "es"}"
                                    " • "
                                    "$totalSessions session"
                                    "${totalSessions == 1 ? "" : "s"}",
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // STATISTICS ROW 1
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Sessions",
                            totalSessions
                                .toString(),
                            Icons.qr_code,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _statCard(
                            "Classes",
                            uniqueClasses
                                .length
                                .toString(),
                            Icons.class_,
                            Colors.indigo,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // STATISTICS ROW 2
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Students",
                            uniqueStudents
                                .length
                                .toString(),
                            Icons.people,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _statCard(
                            "Present",
                            totalPresent
                                .toString(),
                            Icons.check_circle,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // STATISTICS ROW 3
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Absent",
                            totalAbsent
                                .toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _statCard(
                            "Avg / Session",
                            average
                                .toStringAsFixed(
                              1,
                            ),
                            Icons.analytics,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // CLASS LIST
                    // ==================================================

                    const Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        "Classes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (uniqueClasses.isEmpty)
                      const Card(
                        child: Padding(
                          padding:
                              EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              "No class information available.",
                            ),
                          ),
                        ),
                      )
                    else
                      ...uniqueClasses
                          .toList()
                          .map(
                        (className) {
                          final classSessions =
                              sessions.where(
                            (doc) {
                              final data =
                                  doc.data();

                              final value =
                                  data["className"]
                                      ?.toString()
                                      .trim();

                              return value != null &&
                                  value
                                      .toUpperCase() ==
                                      className
                                          .toUpperCase();
                            },
                          ).length;

                          return Card(
                            elevation: 3,
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 8,
                            ),
                            child: ListTile(
                              leading:
                                  const CircleAvatar(
                                backgroundColor:
                                    Colors.indigo,
                                child: Icon(
                                  Icons.class_,
                                  color:
                                      Colors.white,
                                ),
                              ),
                              title: Text(
                                className,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              subtitle: Text(
                                "$classSessions session"
                                "${classSessions == 1 ? "" : "s"}",
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // RECENT SESSIONS
                    // ==================================================

                    const Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        "Recent Attendance Sessions",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    if (sessions.isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            "No Attendance Sessions",
                            style:
                                TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                    ...sessionAnalytics.map(
                      (session) {
                        final present =
                            session["present"]
                                as int;

                        final absent =
                            session["absent"]
                                as int;

                        final total =
                            session["total"]
                                as int;

                        final percentage =
                            session["percentage"]
                                as double;

                        final sessionClassName =
                            session["className"]
                                as String;

                        final subject =
                            session["subject"]
                                as String;

                        return Card(
                          elevation: 4,
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(15),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor:
                                          Colors.blue,
                                      child:
                                          Icon(
                                        Icons
                                            .qr_code,
                                        color:
                                            Colors
                                                .white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            subject
                                                    .isEmpty
                                                ? "Attendance Session"
                                                : subject,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  17,
                                            ),
                                          ),
                                          if (sessionClassName
                                              .isNotEmpty)
                                            Text(
                                              "Class : "
                                              "$sessionClassName",
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.blue,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 15,
                                ),

                                // ==================================================
                                // SESSION STATISTICS
                                // ==================================================

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    _miniStat(
                                      "Total",
                                      total,
                                      Colors.blue,
                                    ),
                                    _miniStat(
                                      "Present",
                                      present,
                                      Colors.green,
                                    ),
                                    _miniStat(
                                      "Absent",
                                      absent,
                                      Colors.red,
                                    ),
                                    _miniStat(
                                      "Rate",
                                     "${percentage.toStringAsFixed(0)}%",
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

// ================================================================
// STAT CARD
// ================================================================

Widget _statCard(
  String title,
  String value,
  IconData icon,
  Color color,
) {
  return Card(
    elevation: 5,
    child: Padding(
      padding:
          const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 40,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
            textAlign:
                TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ================================================================
// MINI STAT
// ================================================================

Widget _miniStat(
  String title,
  dynamic value,
  Color color,
) {
  return Column(
    children: [
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(
        height: 3,
      ),
      Text(
        title,
        style:
            const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ],
  );
}