import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'assignment_list_screen.dart';
import 'teacher_direct_chat_screen.dart';
import 'anonymous_doubts_teacher_screen.dart';
import 'manage_announcements_screen.dart';
import 'teacher_study_materials_screen.dart';
import 'generate_qr_screen.dart';
import 'teacher_ai_screen.dart';

import '../communication/anonymous_video_call_screen.dart';
import '../communication/group_chat_screen.dart';

import '../../utils/logout_helper.dart';

class SubjectTeacherDashboard extends StatefulWidget {
  const SubjectTeacherDashboard({
    super.key,
  });

  @override
  State<SubjectTeacherDashboard> createState() =>
      _SubjectTeacherDashboardState();
}

class _SubjectTeacherDashboardState
    extends State<SubjectTeacherDashboard> {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  int currentIndex = 0;

  // ==========================================================
  // TEACHER DATA
  // ==========================================================

 String teacherUid = "";
 String teacherName = "Subject Teacher";
 String teacherDepartment = "";
 String teacherEmail = "";
 String teacherSubject = "";

  bool isLoadingTeacher = true;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadTeacherData();
  }

  // ==========================================================
  // LOAD TEACHER DATA
  // ==========================================================

  Future<void> loadTeacherData() async {
    final User? user = auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        teacherUid = "";
        teacherName = "Subject Teacher";
        teacherDepartment = "";
        teacherEmail = "";
        isLoadingTeacher = false;
      });

      return;
    }

    try {
      teacherUid = user.uid;

      final QuerySnapshot<Map<String, dynamic>> query =
          await firestore
              .collection("users")
              .where(
                "uid",
                isEqualTo: user.uid,
              )
              .where(
                "role",
                isEqualTo: "Subject Teacher",
              )
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          teacherUid = user.uid;
          teacherName = "Subject Teacher";
          teacherDepartment = "";
          teacherEmail = user.email ?? "";
          isLoadingTeacher = false;
        });

        return;
      }

      final Map<String, dynamic> data =
          query.docs.first.data();

      final String name =
          data["name"]?.toString().trim().isNotEmpty == true
              ? data["name"].toString().trim()
              : "Subject Teacher";

      final String department =
    data["department"]?.toString().trim() ?? "";

final String subject =
    data["subject"]?.toString().trim() ?? "";

final String email =
    data["email"]?.toString().trim().isNotEmpty == true
        ? data["email"].toString().trim()
        : user.email ?? "";

      if (!mounted) return;

      setState(() {
        teacherUid = user.uid;
        teacherName = name;
        teacherDepartment = department;
        teacherSubject = subject;
        teacherEmail = email;
        isLoadingTeacher = false;
      });
    } catch (e) {
      debugPrint(
        "Error loading teacher profile: $e",
      );

      if (!mounted) return;

      setState(() {
        teacherUid = user.uid;
        teacherName = "Subject Teacher";
        teacherDepartment = "";
        teacherEmail = user.email ?? "";
        isLoadingTeacher = false;
      });
    }
  }

  // ==========================================================
  // TEACHER INITIALS
  // ==========================================================

  String getTeacherInitials() {
    final String name = teacherName.trim();

    if (name.isEmpty ||
        name == "Subject Teacher") {
      return "T";
    }

    final List<String> parts =
        name.split(RegExp(r"\s+"));

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return "${parts.first[0]}${parts.last[0]}"
        .toUpperCase();
  }

  // ==========================================================
  // PAGE TITLE
  // ==========================================================

  String getPageTitle() {
    switch (currentIndex) {
      case 0:
        return "Home";

      case 1:
        return "Chat";

      case 2:
        return "SparkAI";

      case 3:
        return "Profile";

      default:
        return "Home";
    }
  }

  // ==========================================================
  // HOME DASHBOARD CARD
  // ==========================================================

  Widget buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HOME SECTION HEADER
  // ==========================================================

  Widget buildSectionHeader({
    required String title,
    required String subtitle,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QUICK ACTION
  // ==========================================================

  Widget buildQuickAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CHAT OPTION CARD
  // ==========================================================

  Widget buildChatCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 9,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor:
              color.withValues(
            alpha: 0.12,
          ),
          child: Icon(
            icon,
            color: color,
            size: 27,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================================
  // SPARKAI LEARNING ALERTS
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
    getSparkAILearningAlertsStream() {
  if (teacherUid.trim().isEmpty) {
    return firestore
        .collection("spark_ai_doubt_alerts")
        .where(
          "teacherUid",
          isEqualTo: "__NO_TEACHER__",
        )
        .where(
          "status",
          isEqualTo: "unread",
        )
        .snapshots();
  }

  return firestore
      .collection("spark_ai_doubt_alerts")
      .where(
        "teacherUid",
        isEqualTo: teacherUid,
      )
      .where(
        "status",
        isEqualTo: "unread",
      )
      .snapshots();
}

  // ==========================================================
  // LEARNING ALERT CARD
  // ==========================================================

  Widget buildSparkAILearningAlertCard() {
    if (isLoadingTeacher) {
      return const SizedBox();
    }

    if (teacherDepartment.trim().isEmpty ||
        teacherSubject.trim().isEmpty) {
      return const SizedBox();
}

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream:
          getSparkAILearningAlertsStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          debugPrint(
            "SparkAI learning alert error: "
            "${snapshot.error}",
          );

          return const SizedBox();
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),
            padding:
                const EdgeInsets.all(
              16,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                Text(
                  "Loading SparkAI alerts...",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            documents =
            snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return const SizedBox();
        }

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 16,
          ),
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Color(0xFFFFF3E0),
                Color(0xFFFFE0B2),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  Colors.orange.shade300,
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            onTap: () {
              showSparkAILearningAlerts(
                documents,
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.all(
                17,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.orange,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .notifications_active_rounded,
                      color:
                          Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child:
                                  Text(
                                "SparkAI Learning Alerts",
                                style:
                                    TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    9,
                                vertical:
                                    4,
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
                                  Text(
                                "${documents.length}",
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          documents.length == 1
                              ? "Students are repeatedly asking about a topic."
                              : "${documents.length} repeated-doubt alerts need your attention.",
                          style:
                              const TextStyle(
                            fontSize:
                                13,
                            color:
                                Colors.black54,
                            height:
                                1.4,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Row(
                          children: [
                            Text(
                              "Tap to review",
                              style:
                                  TextStyle(
                                color:
                                    Colors.deepOrange,
                                fontSize:
                                    13,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                              color:
                                  Colors.deepOrange,
                              size:
                                  18,
                            ),
                          ],
                        ),
                      ],
                    ),
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
  // SHOW LEARNING ALERTS
  // ==========================================================

  Future<void> showSparkAILearningAlerts(
    List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        documents,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (
        sheetContext,
      ) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.sizeOf(
                      context,
                    ).height *
                    0.82,
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.orange,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .auto_awesome,
                          color:
                              Colors.white,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              "SparkAI Learning Alerts",
                              style:
                                  TextStyle(
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height:
                                  3,
                            ),
                            Text(
                              "Repeated student doubts",
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                // ==================================================
                // ALERT LIST
                // ==================================================

                Expanded(
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      14,
                      16,
                      30,
                    ),
                    itemCount:
                        documents.length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final QueryDocumentSnapshot<
                              Map<String, dynamic>>
                          document =
                          documents[index];

                      final Map<String, dynamic>
                          data =
                          document.data();

                      return buildLearningAlertItem(
                        sheetContext:
                            sheetContext,
                        document:
                            document,
                        data:
                            data,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // LEARNING ALERT ITEM
  // ==========================================================

  Widget buildLearningAlertItem({
    required BuildContext sheetContext,
    required QueryDocumentSnapshot<
        Map<String, dynamic>> document,
    required Map<String, dynamic> data,
  }) {
    final String question =
        data["question"]
                ?.toString()
                .trim() ??
            "Student question";

    final String subjectName =
        data["subjectName"]
                ?.toString()
                .trim() ??
            "";

    final String subjectCode =
        data["subjectCode"]
                ?.toString()
                .trim() ??
            "";

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

    final String message =
        data["message"]
                ?.toString()
                .trim() ??
            "";

    final int studentCount =
        data["studentCount"] is int
            ? data["studentCount"] as int
            : int.tryParse(
                  data["studentCount"]
                          ?.toString() ??
                      "",
                ) ??
                0;

    final String subjectDisplay =
        subjectName.isNotEmpty
            ? subjectCode.isNotEmpty
                ? "$subjectName ($subjectCode)"
                : subjectName
            : subjectCode.isNotEmpty
                ? subjectCode
                : "Subject";

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // SUBJECT
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: Colors.orange
                        .withValues(
                      alpha: 0.12,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .menu_book_rounded,
                    color:
                        Colors.orange,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        subjectDisplay,
                        style:
                            const TextStyle(
                          fontSize:
                              16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        "$department • $year • Section $section",
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // QUESTION
            // ==================================================

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    "Repeated question",
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    "\"$question\"",
                    style:
                        const TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.w600,
                      height:
                          1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // STUDENT COUNT
            // ==================================================

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        10,
                    vertical:
                        7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                      Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .groups_rounded,
                        size:
                            18,
                        color:
                            Colors.red.shade700,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        "$studentCount students",
                        style:
                            TextStyle(
                          color:
                              Colors.red.shade700,
                          fontWeight:
                              FontWeight.bold,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ==================================================
            // ALERT MESSAGE
            // ==================================================

            if (message.isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              Text(
                message,
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                  fontSize:
                      13,
                  height:
                      1.4,
                ),
              ),
            ],

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // REVIEW BUTTON
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                icon:
                    const Icon(
                  Icons
                      .check_circle_outline,
                  size:
                      19,
                ),
                label:
                    const Text(
                  "Mark as Reviewed",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                onPressed:
                    () async {
                  try {
                    await firestore
                        .collection(
                          "spark_ai_doubt_alerts",
                        )
                        .doc(
                          document.id,
                        )
                        .update({
                      "status":
                          "reviewed",
                      "reviewedAt":
                          FieldValue
                              .serverTimestamp(),
                      "reviewedBy":
                          teacherUid,
                    });

                    if (!sheetContext
                        .mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      sheetContext,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                            Text(
                          "Learning alert marked as reviewed.",
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!sheetContext
                        .mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      sheetContext,
                    ).showSnackBar(
                      SnackBar(
                        backgroundColor:
                            Colors.red,
                        content:
                            Text(
                          "Could not update alert: $e",
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // START TEACHER VIDEO CALL
  // ==========================================================

  Future<void> startTeacherVideoCall() async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await firestore
              .collection("subjects")
              .get();

      if (!mounted) return;

      final subjects = snapshot.docs;

      if (subjects.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "No subjects available.",
            ),
          ),
        );

        return;
      }

      final String? selectedSubject =
          await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                20,
              ),
              children: [
                const Text(
                  "Start Anonymous Video Call",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  "Select the subject for the live call.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                ...subjects.map((doc) {
                  final Map<String, dynamic>
                      data =
                      doc.data();

                  final String subjectName =
                      data["name"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? data["name"]
                              .toString()
                              .trim()
                          : "Subject";

                  final String subjectCode =
                      data["code"]
                              ?.toString()
                              .trim() ??
                          "";

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            Colors.red,
                        child: Icon(
                          Icons
                              .videocam_rounded,
                          color:
                              Colors.white,
                        ),
                      ),
                      title: Text(
                        subjectName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        subjectCode.isEmpty
                            ? "Anonymous subject call"
                            : subjectCode,
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                          subjectName,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );

      if (!mounted ||
          selectedSubject == null ||
          selectedSubject.trim().isEmpty) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AnonymousVideoCallScreen(
            subject: selectedSubject,
            isTeacher: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to load subjects:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // LIVE DASHBOARD STATISTICS
  // ==========================================================

  Widget buildLiveStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    snapshot.connectionState == ConnectionState.waiting
                        ? const SizedBox(
                            height: 22,
                            width: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // LATEST ATTENDANCE STATISTIC
  // ==========================================================

  Widget buildLatestAttendanceStatCard({
    required double width,
  }) {
    final String queryTeacherUid =
        teacherUid.trim().isEmpty ? "__NO_TEACHER__" : teacherUid.trim();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('attendance_sessions')
          .where('teacherUid', isEqualTo: queryTeacherUid)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        QueryDocumentSnapshot<Map<String, dynamic>>? latestSession;
        Timestamp? latestCreatedAt;

        for (final document in sessionSnapshot.data?.docs ?? []) {
          final Map<String, dynamic> data = document.data();

          if (data['active'] == true) continue;

          final dynamic createdAtValue = data['createdAt'];
          if (createdAtValue is! Timestamp) continue;

          if (latestCreatedAt == null ||
              createdAtValue.compareTo(latestCreatedAt) > 0) {
            latestCreatedAt = createdAtValue;
            latestSession = document;
          }
        }

        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCompactAttendanceCard(
            width: width,
            percentageText: '...',
            subjectText: 'Loading attendance',
            presentText: 'P --',
            absentText: 'A --',
          );
        }

        if (sessionSnapshot.hasError || latestSession == null) {
          return _buildCompactAttendanceCard(
            width: width,
            percentageText: '--',
            subjectText: 'No completed session',
            presentText: 'P --',
            absentText: 'A --',
          );
        }

        final Map<String, dynamic> sessionData = latestSession.data();
        final String sessionId =
            sessionData['sessionId']?.toString().trim().isNotEmpty == true
                ? sessionData['sessionId'].toString().trim()
                : latestSession.id;

        final String subject =
            sessionData['subject']?.toString().trim().isNotEmpty == true
                ? sessionData['subject'].toString().trim()
                : 'Attendance';

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('attendance')
              .where('sessionId', isEqualTo: sessionId)
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildCompactAttendanceCard(
                width: width,
                percentageText: '...',
                subjectText: subject,
                presentText: 'P --',
                absentText: 'A --',
              );
            }

            int present = 0;
            int absent = 0;

            for (final document in attendanceSnapshot.data?.docs ?? []) {
              final String status =
                  document.data()['status']?.toString().trim().toLowerCase() ??
                      '';

              if (status == 'present') {
                present++;
              } else if (status == 'absent') {
                absent++;
              }
            }

            final int total = present + absent;
            final double percentage =
                total == 0 ? 0 : (present / total) * 100;

            return _buildCompactAttendanceCard(
              width: width,
              percentageText:
                  total == 0 ? '--' : '${percentage.toStringAsFixed(0)}%',
              subjectText: subject,
              presentText: 'P $present',
              absentText: 'A $absent',
            );
          },
        );
      },
    );
  }

  Widget _buildCompactAttendanceCard({
    required double width,
    required String percentageText,
    required String subjectText,
    required String presentText,
    required String absentText,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: Colors.orange,
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percentageText,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attendance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subjectText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  presentText,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  absentText,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(
          title: 'Live Overview',
          subtitle: 'Teaching workspace summary',
          icon: Icons.insights_rounded,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 600;
            const double spacing = 10;
            final int columns = wide ? 4 : 2;
            final double cardWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: buildLiveStatCard(
                    title: 'Assignments',
                    icon: Icons.assignment_rounded,
                    color: Colors.indigo,
                    stream: firestore.collection('assignments').snapshots(),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: buildLiveStatCard(
                    title: 'QR Sessions',
                    icon: Icons.qr_code_2_rounded,
                    color: Colors.green,
                    stream: firestore
                        .collection('attendance_sessions')
                        .snapshots(),
                  ),
                ),
                buildLatestAttendanceStatCard(
                  width: cardWidth,
                ),
                SizedBox(
                  width: cardWidth,
                  child: buildLiveStatCard(
                    title: 'AI Alerts',
                    icon: Icons.psychology_rounded,
                    color: Colors.purple,
                    stream: getSparkAILearningAlertsStream(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================================
  // HOME PAGE
  // ==========================================================

  Widget buildHomePage() {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 380;
    final double horizontalPadding = screenWidth < 600 ? 16 : 24;
    final double gridSpacing = 12;

    return RefreshIndicator(
      onRefresh: loadTeacherData,
      color: Colors.blue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          32,
        ),
        children: [
          // ==================================================
          // PROFESSIONAL TEACHER HEADER
          // ==================================================

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 17 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: compact ? 23 : 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        isLoadingTeacher ? '...' : getTeacherInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good day, Teacher 👋',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isLoadingTeacher ? 'Loading...' : teacherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 21 : 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                if (teacherDepartment.isNotEmpty ||
                    teacherSubject.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (teacherDepartment.isNotEmpty)
                        _buildHeaderChip(
                          Icons.account_balance_rounded,
                          teacherDepartment,
                        ),
                      if (teacherSubject.isNotEmpty)
                        _buildHeaderChip(
                          Icons.menu_book_rounded,
                          teacherSubject,
                        ),
                    ],
                  ),

                const SizedBox(height: 14),

                const Text(
                  'Manage your teaching activities, communicate with students, and use SparkAI to support learning.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ==================================================
          // LIVE DASHBOARD STATISTICS
          // ==================================================

          buildDashboardStatistics(),

          // ==================================================
          // SPARKAI LEARNING ALERTS
          // ==================================================

          buildSparkAILearningAlertCard(),

          // ==================================================
          // QUICK ACTIONS
          // ==================================================

          buildSectionHeader(
            title: 'Quick Actions',
            subtitle: 'Frequently used teaching tools',
            icon: Icons.flash_on_rounded,
          ),

          GridView.count(
            crossAxisCount: screenWidth >= 600 ? 4 : 2,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            childAspectRatio: screenWidth >= 600 ? 1.05 : 1.12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              buildQuickAction(
                icon: Icons.qr_code_2_rounded,
                color: Colors.green,
                title: 'Generate QR',
                subtitle: 'Start attendance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GenerateQRScreen(),
                    ),
                  );
                },
              ),
              buildQuickAction(
                icon: Icons.assignment_rounded,
                color: Colors.indigo,
                title: 'Assignments',
                subtitle: 'Manage work',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssignmentListScreen(),
                    ),
                  );
                },
              ),
              buildQuickAction(
                icon: Icons.campaign_rounded,
                color: Colors.orange,
                title: 'Announcements',
                subtitle: 'Share updates',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageAnnouncementsScreen(),
                    ),
                  );
                },
              ),
              buildQuickAction(
                icon: Icons.folder_rounded,
                color: Colors.teal,
                title: 'Materials',
                subtitle: 'Manage resources',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherStudyMaterialsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================================================
          // TEACHING WORKSPACE
          // ==================================================

          buildSectionHeader(
            title: 'Teaching Workspace',
            subtitle: 'Access your main classroom tools',
            icon: Icons.dashboard_customize_rounded,
          ),

          buildDashboardCard(
            context: context,
            icon: Icons.assignment_rounded,
            color: Colors.indigo,
            title: 'Assignments',
            subtitle: 'View and manage student assignments',
            screen: const AssignmentListScreen(),
          ),
          const SizedBox(height: 10),
          buildDashboardCard(
            context: context,
            icon: Icons.campaign_rounded,
            color: Colors.orange,
            title: 'Announcements',
            subtitle: 'Manage announcements for students',
            screen: const ManageAnnouncementsScreen(),
          ),
          const SizedBox(height: 10),
          buildDashboardCard(
            context: context,
            icon: Icons.folder_rounded,
            color: Colors.teal,
            title: 'Study Materials',
            subtitle: 'Upload and manage learning materials',
            screen: const TeacherStudyMaterialsScreen(),
          ),
          const SizedBox(height: 10),
          buildDashboardCard(
            context: context,
            icon: Icons.qr_code_2_rounded,
            color: Colors.green,
            title: 'Attendance',
            subtitle: 'Start QR attendance for your class',
            screen: const GenerateQRScreen(),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // CONNECTED TOOLS
          // ==================================================

          buildSectionHeader(
            title: 'More Tools',
            subtitle: 'Communication and intelligent teaching support',
            icon: Icons.apps_rounded,
          ),

          Row(
            children: [
              Expanded(
                child: buildQuickAction(
                  icon: Icons.chat_rounded,
                  color: Colors.blue,
                  title: 'Student Chat',
                  subtitle: 'Open Chat',
                  onTap: () {
                    setState(() {
                      currentIndex = 1;
                    });
                  },
                ),
              ),
            SizedBox(width: gridSpacing),
              Expanded(
                child: buildQuickAction(
                  icon: Icons.auto_awesome_rounded,
                  color: Colors.deepPurple,
                  title: 'Teacher AI',
                  subtitle: 'Open SparkAI',
                  onTap: () {
                    setState(() {
                      currentIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHAT PAGE
  // ==========================================================

  Widget buildChatPage() {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30,
      ),
      children: [
        const Text(
          "Chat",
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          "Communicate with students in different ways.",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // DIRECT CHAT
        // ======================================================

        buildChatCard(
          context: context,
          icon:
              Icons.chat_rounded,
          color:
              Colors.blue,
          title:
              "Direct Chat",
          subtitle:
              "Private conversations with students",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const TeacherDirectChatScreen(),
              ),
            );
          },
        ),

        // ======================================================
        // ANONYMOUS DOUBTS
        // ======================================================

        buildChatCard(
          context: context,
          icon:
              Icons.visibility_off_rounded,
          color:
              Colors.red,
          title:
              "Anonymous Doubts",
          subtitle:
              "Answer student doubts while protecting identity",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AnonymousDoubtsTeacherScreen(),
              ),
            );
          },
        ),

        // ======================================================
        // SUBJECT GROUP CHAT
        // ======================================================

        buildChatCard(
          context: context,
          icon:
              Icons.groups_rounded,
          color:
              Colors.indigo,
          title:
              "Subject Group Chat",
          subtitle:
              "Communicate with students in subject groups",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const GroupChatScreen(),
              ),
            );
          },
        ),

        // ======================================================
        // ANONYMOUS VIDEO CALL
        // ======================================================

        buildChatCard(
          context: context,
          icon:
              Icons.videocam_rounded,
          color:
              Colors.red,
          title:
              "Anonymous Video Call",
          subtitle:
              "Start a live video call for a subject",
          onTap:
              startTeacherVideoCall,
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE PAGE
  // ==========================================================

  Widget buildProfilePage() {
    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [
        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // PROFILE IMAGE / INITIALS
        // ======================================================

        CircleAvatar(
          radius: 50,
          backgroundColor:
              Colors.blue,
          child: Text(
            getTeacherInitials(),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // ======================================================
        // NAME
        // ======================================================

        Center(
          child: Text(
            teacherName,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        // ======================================================
        // ROLE
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const Icon(
              Icons.school,
              color:
                  Colors.blue,
            ),
            title:
                const Text(
              "Role",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                const Text(
              "Subject Teacher",
            ),
          ),
        ),

        // ======================================================
        // DEPARTMENT
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const Icon(
              Icons.business,
              color:
                  Colors.orange,
            ),
            title:
                const Text(
              "Department",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                Text(
              teacherDepartment
                      .isNotEmpty
                  ? teacherDepartment
                  : "Not available",
            ),
          ),
        ),

        // ======================================================
        // EMAIL
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const Icon(
              Icons.email,
              color:
                  Colors.red,
            ),
            title:
                const Text(
              "Email",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                Text(
              teacherEmail
                      .isNotEmpty
                  ? teacherEmail
                  : "Not available",
            ),
          ),
        ),

        // ======================================================
        // UID
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const Icon(
              Icons.fingerprint,
              color:
                  Colors.purple,
            ),
            title:
                const Text(
              "Teacher ID",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                Text(
              teacherUid.isNotEmpty
                  ? teacherUid
                  : "Not available",
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ======================================================
        // LOGOUT
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const Icon(
                  Icons.logout,
                  color:
                      Colors.red,
                ),
            title:
                const Text(
              "Logout",
              style:
                  TextStyle(
                color:
                    Colors.red,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            trailing:
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                ),
            onTap: () {
              LogoutHelper
                  .showLogoutDialog(
                context,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget buildBody() {
    switch (currentIndex) {
      case 0:
        return buildHomePage();

      case 1:
        return buildChatPage();

      case 2:
        return const TeacherAIScreen();

      case 3:
        return buildProfilePage();

      default:
        return buildHomePage();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9FF),

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: Text(
          getPageTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: buildBody(),

      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: Colors.blue.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_rounded),
            label: "Chat",
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: "SparkAI",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}