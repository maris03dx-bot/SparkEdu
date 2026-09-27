import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SparkAIWeakTopicScreen extends StatelessWidget {
  const SparkAIWeakTopicScreen({super.key});

  static final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth auth =
      FirebaseAuth.instance;

  // ==========================================================
  // FORMAT TIMESTAMP
  // ==========================================================

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return "Recently";
    }

    final DateTime date = timestamp.toDate();

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String year =
        date.year.toString();

    final String hour =
        date.hour.toString().padLeft(2, '0');

    final String minute =
        date.minute.toString().padLeft(2, '0');

    return "$day/$month/$year • $hour:$minute";
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color getStatusColor(String status) {
    switch (status) {
      case "resolved":
        return Colors.green;

      case "reviewed":
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  // ==========================================================
  // STATUS LABEL
  // ==========================================================

  String getStatusLabel(String status) {
    switch (status) {
      case "resolved":
        return "Resolved";

      case "reviewed":
        return "Reviewed";

      default:
        return "Needs Review";
    }
  }

  // ==========================================================
  // SHOW ALERT DETAILS
  // ==========================================================

  void showAlertDetails(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String question =
        data["question"]?.toString().trim() ??
            "Unknown question";

    final String subjectName =
        data["subjectName"]?.toString().trim() ??
            "";

    final String subjectCode =
        data["subjectCode"]?.toString().trim() ??
            "";

    final String department =
        data["department"]?.toString().trim() ??
            "";

    final String year =
        data["year"]?.toString().trim() ??
            "";

    final String section =
        data["section"]?.toString().trim() ??
            "";

    final String message =
        data["message"]?.toString().trim() ??
            "";

    final String status =
        data["status"]?.toString().trim() ??
            "unread";

    final int studentCount =
        data["studentCount"] is int
            ? data["studentCount"] as int
            : int.tryParse(
                  data["studentCount"]?.toString() ??
                      "",
                ) ??
                0;

    final Timestamp? timestamp =
        data["createdAt"] is Timestamp
            ? data["createdAt"] as Timestamp
            : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.red,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          "Weak Topic Alert",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // QUESTION
                  // ==================================================

                  const Text(
                    "Repeated Student Doubt",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // INFORMATION
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          icon:
                              Icons.people_alt_rounded,
                          color:
                              Colors.deepPurple,
                          title: "Students",
                          value:
                              "$studentCount",
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _InfoBox(
                          icon:
                              Icons.menu_book_rounded,
                          color: Colors.blue,
                          title: "Subject",
                          value:
                              subjectName.isEmpty
                                  ? "Not available"
                                  : subjectName,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // CLASS
                  // ==================================================

                  _DetailRow(
                    icon: Icons.school_rounded,
                    title: "Class",
                    value:
                        "$department • Year $year • Section $section",
                  ),

                  // ==================================================
                  // SUBJECT CODE
                  // ==================================================

                  if (subjectCode.isNotEmpty)
                    _DetailRow(
                      icon: Icons
                          .confirmation_number_rounded,
                      title: "Subject Code",
                      value: subjectCode,
                    ),

                  // ==================================================
                  // DETECTED
                  // ==================================================

                  _DetailRow(
                    icon:
                        Icons.access_time_rounded,
                    title: "Detected",
                    value:
                        formatTimestamp(timestamp),
                  ),

                  // ==================================================
                  // AI MESSAGE
                  // ==================================================

                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            Colors.orange.shade50,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.orange,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              message,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // ==================================================
                  // STATUS + BUTTON
                  // ==================================================

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(
                            status,
                          ).withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          getStatusLabel(status),
                          style: TextStyle(
                            color: getStatusColor(
                              status,
                            ),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const Spacer(),

                      if (status == "unread")
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await firestore
                                  .collection(
                                    "spark_ai_doubt_alerts",
                                  )
                                  .doc(document.id)
                                  .update({
                                "status": "reviewed",
                                "reviewedAt":
                                    FieldValue
                                        .serverTimestamp(),

                                // ==================================================
                                // STORE WHICH TEACHER REVIEWED IT
                                // ==================================================

                                "reviewedBy":
                                    auth.currentUser?.uid,
                              });

                              if (!sheetContext.mounted) {
                                return;
                              }

                              Navigator.pop(
                                sheetContext,
                              );

                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Weak topic marked as reviewed.",
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!sheetContext.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                sheetContext,
                              ).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      Colors.red,
                                  content: Text(
                                    "Unable to update:\n$e",
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.check_rounded,
                          ),
                          label: const Text(
                            "Mark Reviewed",
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // ALERT CARD
  // ==========================================================

  Widget buildAlertCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String question =
        data["question"]?.toString().trim() ??
            "Unknown question";

    final String subjectName =
        data["subjectName"]?.toString().trim() ??
            "";

    final String subjectCode =
        data["subjectCode"]?.toString().trim() ??
            "";

    final String department =
        data["department"]?.toString().trim() ??
            "";

    final String year =
        data["year"]?.toString().trim() ??
            "";

    final String section =
        data["section"]?.toString().trim() ??
            "";

    final String status =
        data["status"]?.toString().trim() ??
            "unread";

    final int studentCount =
        data["studentCount"] is int
            ? data["studentCount"] as int
            : int.tryParse(
                  data["studentCount"]?.toString() ??
                      "",
                ) ??
                0;

    final Timestamp? timestamp =
        data["createdAt"] is Timestamp
            ? data["createdAt"] as Timestamp
            : null;

    final bool isUnread =
        status == "unread";

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          showAlertDetails(
            context,
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
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isUnread
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: isUnread
                          ? Colors.red
                          : Colors.grey,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subjectName.isEmpty
                                    ? "Weak Topic"
                                    : subjectName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            if (isUnread)
                              Container(
                                width: 9,
                                height: 9,
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.red,
                                  shape:
                                      BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          subjectCode.isEmpty
                              ? "$department • $year • $section"
                              : "$subjectCode • $department • $year • $section",
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                question,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.deepPurple
                              .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 15,
                          color:
                              Colors.deepPurple,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          "$studentCount students",
                          style:
                              const TextStyle(
                            color:
                                Colors.deepPurple,
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (timestamp != null)
                    Expanded(
                      child: Text(
                        formatTimestamp(
                          timestamp,
                        ),
                        textAlign:
                            TextAlign.right,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  const SizedBox(width: 6),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 15,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .check_circle_outline_rounded,
                size: 52,
                color:
                    Colors.green.shade600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "No Weak Topics Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "SparkAI will show a learning alert here when multiple students ask the same question.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // CURRENT TEACHER
    // ==========================================================

    final User? currentUser =
        auth.currentUser;

    // ==========================================================
    // NOT LOGGED IN
    // ==========================================================

    if (currentUser == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFFFFF9FF),
        appBar: AppBar(
          title: const Text(
            "Weak Topic Detector",
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "Teacher account not found.",
          ),
        ),
      );
    }

    // ==========================================================
    // ⭐ IMPORTANT TEACHER-SPECIFIC QUERY
    //
    // ONLY alerts belonging to the currently logged-in
    // teacher are loaded.
    //
    // Example:
    //
    // Dr.Kumar:
    // yOFgV1Q7iwVMK2iCamj7DpY2Nug2
    //
    // Mr.Suresh:
    // HfhxhMZr70UdACeHlU6P7OYyXvf1
    // ==========================================================

    final String currentTeacherUid =
        currentUser.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9FF),

      appBar: AppBar(
        title: const Text(
          "Weak Topic Detector",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: firestore
            .collection(
              "spark_ai_doubt_alerts",
            )
            // ======================================================
            // ⭐⭐⭐ THE ACTUAL FIX ⭐⭐⭐
            // ======================================================
            .where(
              "teacherUid",
              isEqualTo: currentTeacherUid,
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons
                          .error_outline_rounded,
                      color: Colors.red,
                      size: 50,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      "Unable to load weak topics.",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      "${snapshot.error}",
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          // ========================================================
          // DOCUMENTS
          // ========================================================

          final List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
              documents =
              List<
                      QueryDocumentSnapshot<
                          Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? [],
          );

          // ========================================================
          // SORT LOCALLY
          //
          // We intentionally sort in Dart instead of using:
          //
          // orderBy("createdAt")
          //
          // This avoids requiring a Firestore composite index
          // for teacherUid + createdAt.
          // ========================================================

          documents.sort(
            (
              QueryDocumentSnapshot<
                      Map<String, dynamic>>
                  a,
              QueryDocumentSnapshot<
                      Map<String, dynamic>>
                  b,
            ) {
              final dynamic aTime =
                  a.data()["createdAt"];

              final dynamic bTime =
                  b.data()["createdAt"];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }

              if (aTime is Timestamp) {
                return -1;
              }

              if (bTime is Timestamp) {
                return 1;
              }

              return 0;
            },
          );

          // ========================================================
          // EMPTY
          // ========================================================

          if (documents.isEmpty) {
            return buildEmptyState();
          }

          // ========================================================
          // LIST
          // ========================================================

          return RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(
                  milliseconds: 300,
                ),
              );
            },

            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                30,
              ),

              itemCount:
                  documents.length,

              itemBuilder:
                  (context, index) {
                return buildAlertCard(
                  context,
                  documents[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// INFO BOX
// ============================================================

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.07),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: 20,
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 90,
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? "Not available"
                  : value,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}