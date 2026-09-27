import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MentorSparkAIDoubtAlertsScreen extends StatefulWidget {
  const MentorSparkAIDoubtAlertsScreen({
    super.key,
  });

  @override
  State<MentorSparkAIDoubtAlertsScreen> createState() =>
      _MentorSparkAIDoubtAlertsScreenState();
}

class _MentorSparkAIDoubtAlertsScreenState
    extends State<MentorSparkAIDoubtAlertsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET REGISTER NUMBERS FROM STUDENT UIDs
  // ============================================================

  Future<List<String>> getStudentRegisterNumbers(
    List<dynamic> studentUids,
  ) async {
    final List<String> registerNumbers = [];

    for (final dynamic uidValue in studentUids) {
      final String uid = uidValue.toString().trim();

      if (uid.isEmpty) {
        continue;
      }

      try {
        final QuerySnapshot userQuery = await firestore
            .collection("users")
            .where(
              "uid",
              isEqualTo: uid,
            )
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final Map<String, dynamic> userData =
              userQuery.docs.first.data()
                  as Map<String, dynamic>;

          final String registerNo =
              userData["registerNo"]?.toString().trim() ?? "";

          if (registerNo.isNotEmpty) {
            registerNumbers.add(registerNo);
          }
        }
      } catch (e) {
        debugPrint(
          "Failed to get register number for student: $e",
        );
      }
    }

    return registerNumbers;
  }

  // ============================================================
  // MARK ALERT AS READ
  // ============================================================

  Future<void> markAsRead(
    DocumentSnapshot document,
  ) async {
    try {
      await firestore
          .collection("spark_ai_doubt_alerts")
          .doc(document.id)
          .update({
        "status": "read",
        "readAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Alert marked as read.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to mark alert as read: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SHOW ALERT DETAILS
  // ============================================================

  void showAlertDetails(
    DocumentSnapshot document,
  ) {
    final Map<String, dynamic> data =
        document.data() as Map<String, dynamic>;

    final String question =
        data["question"]?.toString() ??
            "Unknown question";

    final String department =
        data["department"]?.toString() ??
            "N/A";

    final String year =
        data["year"]?.toString() ??
            "N/A";

    final String section =
        data["section"]?.toString() ??
            "N/A";

    final String status =
        data["status"]?.toString() ??
            "unread";

    final int studentCount =
        _getStudentCount(data);

    final List<dynamic> studentUids =
        data["studentUids"] is List
            ? List<dynamic>.from(
                data["studentUids"],
              )
            : [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "SparkAI Doubt Alert",
                ),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // QUESTION
                // ==================================================

                const Text(
                  "Repeated Question",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // STUDENT COUNT
                // ==================================================

                _detailRow(
                  Icons.people,
                  "Students",
                  studentCount.toString(),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // DEPARTMENT
                // ==================================================

                _detailRow(
                  Icons.account_balance,
                  "Department",
                  department,
                ),

                const SizedBox(height: 10),

                // ==================================================
                // YEAR
                // ==================================================

                _detailRow(
                  Icons.school,
                  "Year",
                  year,
                ),

                const SizedBox(height: 10),

                // ==================================================
                // SECTION
                // ==================================================

                _detailRow(
                  Icons.groups,
                  "Section",
                  section,
                ),

                const SizedBox(height: 10),

                // ==================================================
                // STATUS
                // ==================================================

                _detailRow(
                  status == "unread"
                      ? Icons.mark_email_unread
                      : Icons.mark_email_read,
                  "Status",
                  status.toUpperCase(),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // STUDENT REGISTER NUMBERS
                // ==================================================

                if (studentUids.isNotEmpty) ...[
                  const Text(
                    "Students Who Asked",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 10),

                  FutureBuilder<List<String>>(
                    future: getStudentRegisterNumbers(
                      studentUids,
                    ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(
                              color: Colors.blue,
                            ),
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------

                      if (snapshot.hasError) {
                        return const Text(
                          "Unable to load student details.",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        );
                      }

                      final List<String>
                          registerNumbers =
                          snapshot.data ?? [];

                      // ------------------------------------------------
                      // NO REGISTER NUMBER
                      // ------------------------------------------------

                      if (registerNumbers.isEmpty) {
                        return const Text(
                          "Register numbers not available.",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // DISPLAY REGISTER NUMBERS
                      // ------------------------------------------------

                      return Column(
                        children:
                            registerNumbers.map(
                          (registerNo) {
                            return Container(
                              width:
                                  double.infinity,
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 8,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .blue
                                    .shade50,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                                border:
                                    Border.all(
                                  color: Colors
                                      .blue
                                      .shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .badge,
                                    size: 20,
                                    color: Colors
                                        .blue
                                        .shade700,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Text(
                                    "Register No: ",
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  Text(
                                    registerNo,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          actions: [
            // ========================================================
            // MARK AS READ
            // ========================================================

            if (status != "read")
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  await markAsRead(
                    document,
                  );
                },
                icon: const Icon(
                  Icons.mark_email_read,
                ),
                label: const Text(
                  "Mark as Read",
                ),
              ),

            // ========================================================
            // CLOSE
            // ========================================================

            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                "Close",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // GET STUDENT COUNT
  // ============================================================

  int _getStudentCount(
    Map<String, dynamic> data,
  ) {
    final dynamic count =
        data["studentCount"];

    if (count is int) {
      return count;
    }

    if (count is num) {
      return count.toInt();
    }

    final dynamic studentUids =
        data["studentUids"];

    if (studentUids is List) {
      return studentUids.length;
    }

    return 0;
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALERT CARD
  // ============================================================

  Widget buildAlertCard(
    DocumentSnapshot document,
  ) {
    final Map<String, dynamic> data =
        document.data() as Map<String, dynamic>;

    final String question =
        data["question"]?.toString() ??
            data["normalizedQuestion"]
                ?.toString() ??
            "Unknown question";

    final String department =
        data["department"]?.toString() ??
            "N/A";

    final String year =
        data["year"]?.toString() ??
            "N/A";

    final String section =
        data["section"]?.toString() ??
            "N/A";

    final String status =
        data["status"]?.toString() ??
            "unread";

    final int studentCount =
        _getStudentCount(data);

    final bool isUnread =
        status != "read";

    return Card(
      elevation:
          isUnread ? 5 : 2,

      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),

        side: isUnread
            ? BorderSide(
                color:
                    Colors.red.shade200,
                width: 1.5,
              )
            : BorderSide.none,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),

        onTap: () {
          showAlertDetails(
            document,
          );
        },

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TOP ROW
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration:
                        BoxDecoration(
                      color: isUnread
                          ? Colors.red.shade50
                          : Colors.grey.shade100,

                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.smart_toy,

                      color: isUnread
                          ? Colors.red
                          : Colors.grey,

                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "SparkAI Doubt",
                                style:
                                    TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),

                            if (isUnread)
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.red,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),

                                child:
                                    const Text(
                                  "UNREAD",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        10,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          question,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              const Divider(),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // STUDENT COUNT
              // ==================================================

              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 20,
                    color:
                        Colors.deepPurple,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    "$studentCount student"
                    "${studentCount == 1 ? '' : 's'} asked this",

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // ACADEMIC DETAILS
              // ==================================================

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: [
                  _infoChip(
                    Icons.account_balance,
                    department,
                  ),

                  _infoChip(
                    Icons.school,
                    year,
                  ),

                  _infoChip(
                    Icons.groups,
                    "Section $section",
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // VIEW DETAILS
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,

                children: [
                  TextButton.icon(
                    onPressed: () {
                      showAlertDetails(
                        document,
                      );
                    },

                    icon: const Icon(
                      Icons.visibility,
                      size: 18,
                    ),

                    label: const Text(
                      "View Details",
                    ),
                  ),

                  if (isUnread)
                    TextButton.icon(
                      onPressed: () {
                        markAsRead(
                          document,
                        );
                      },

                      icon: const Icon(
                        Icons.done,
                        size: 18,
                      ),

                      label: const Text(
                        "Mark Read",
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),

      decoration:
          BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 15,
            color:
                Colors.blue.shade700,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.blue.shade800,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.notifications_none,
              size: 90,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              "No SparkAI Doubt Alerts",
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "When multiple students ask "
              "SparkAI about the same topic, "
              "an alert will appear here.",

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SparkAI Doubt Alerts",
        ),

        centerTitle: true,

        backgroundColor:
            Colors.blue,

        foregroundColor:
            Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection(
              "spark_ai_doubt_alerts",
            )
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      "Unable to load alerts",

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      snapshot.error.toString(),

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
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
              child:
                  CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          // ====================================================
          // GET ALERTS
          // ====================================================

          final List<QueryDocumentSnapshot>
              alerts =
              snapshot.data?.docs ?? [];

          // ====================================================
          // EMPTY
          // ====================================================

          if (alerts.isEmpty) {
            return buildEmptyState();
          }

          // ====================================================
          // ALERT LIST
          // ====================================================

          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              15,
              12,
              25,
            ),

            itemCount:
                alerts.length,

            itemBuilder:
                (context, index) {
              return buildAlertCard(
                alerts[index],
              );
            },
          );
        },
      ),
    );
  }
}