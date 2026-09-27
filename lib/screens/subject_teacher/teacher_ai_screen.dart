import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'spark_ai_weak_topic_screen.dart';
import 'ai_lesson_planner_screen.dart';
import 'question_paper_generator_screen.dart';
import 'ai_answer_evaluator_screen.dart';

class TeacherAIScreen extends StatelessWidget {
  const TeacherAIScreen({
    super.key,
  });

  // ==========================================================
  // FIREBASE
  // ==========================================================

  static final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth auth =
      FirebaseAuth.instance;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color backgroundColor = Color(0xFFFFF9FF);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color secondaryPurple = Color(0xFF9333EA);

  // ==========================================================
  // CURRENT TEACHER
  // ==========================================================

  String? get currentTeacherUid {
    return auth.currentUser?.uid;
  }

  // ==========================================================
  // AI TOOL CARD
  // ==========================================================

  Widget buildAITool({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool comingSoon = false,
  }) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          18,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // ==================================================
              // TITLE + SUBTITLE
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        if (comingSoon)
                          Container(
                            margin:
                                const EdgeInsets.only(
                              left: 8,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Color(0xFFF3F4F6),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              "Soon",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ==================================================
              // ARROW
              // ==================================================

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // QUICK ACTION
  // ==========================================================

  Widget buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FIRESTORE STAT CARD
  // ==========================================================

  Widget buildFirestoreStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required AsyncSnapshot<
            QuerySnapshot<Map<String, dynamic>>>
        snapshot,
  }) {
    String value = "0";

    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      value = "...";
    } else if (snapshot.hasError) {
      value = "—";
    } else {
      value =
          (snapshot.data?.docs.length ?? 0).toString();
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(
          13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FIXED STAT CARD
  // ==========================================================

  Widget buildFixedStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String title,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(
          13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // COMING SOON
  // ==========================================================

  void showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            "$title is coming soon.",
          ),
        ),
      );
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void openLessonPlanner(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AILessonPlannerScreen(),
      ),
    );
  }

  void openQuestionPaper(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const QuestionPaperGeneratorScreen(),
      ),
    );
  }

  void openAnswerEvaluator(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AIAnswerEvaluatorScreen(),
      ),
    );
  }

  void openWeakTopics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SparkAIWeakTopicScreen(),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final String? teacherUid =
        currentTeacherUid;

    // ==========================================================
    // WEAK TOPIC STREAM
    // ==========================================================

    Stream<QuerySnapshot<Map<String, dynamic>>>
        weakTopicStream;

    if (teacherUid == null ||
        teacherUid.trim().isEmpty) {
      weakTopicStream =
          const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    } else {
      weakTopicStream = firestore
          .collection(
            "spark_ai_doubt_alerts",
          )
          .where(
            "teacherUid",
            isEqualTo: teacherUid,
          )
          .snapshots();
    }

    return Scaffold(
      backgroundColor:
          backgroundColor,
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: weakTopicStream,
        builder: (
          context,
          snapshot,
        ) {
          return RefreshIndicator(
            color: primaryPurple,
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(
                  milliseconds: 300,
                ),
              );
            },
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                30,
              ),
              children: [
                // ==================================================
                // HERO HEADER
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        primaryPurple,
                        secondaryPurple,
                      ],
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            primaryPurple.withValues(
                          alpha: 0.20,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white
                                      .withValues(
                                alpha: 0.16,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .auto_awesome_rounded,
                              color:
                                  Colors.white,
                              size: 29,
                            ),
                          ),

                          const Spacer(),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white
                                      .withValues(
                                alpha: 0.15,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Icon(
                                  Icons
                                      .bolt_rounded,
                                  color:
                                      Colors.white,
                                  size: 15,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  "AI Workspace",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      const Text(
                        "Teach Smarter with SparkAI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.bold,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        "Your AI-powered teaching workspace for lessons, assessments, feedback and student insights.",
                        style: TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons
                                  .lightbulb_outline_rounded,
                              color:
                                  Colors.white,
                              size: 18,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                "Create smarter teaching content and discover where students need more support.",
                                style:
                                    TextStyle(
                                  color: Colors
                                      .white,
                                  fontSize:
                                      11.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==================================================
                // OVERVIEW
                // ==================================================

                buildSectionTitle(
                  title:
                      "Teaching Overview",
                  subtitle:
                      "A quick look at the AI insights currently available.",
                ),

                const SizedBox(
                  height: 14,
                ),

                Row(
                  children: [
                    buildFirestoreStatCard(
                      icon: Icons
                          .warning_amber_rounded,
                      color: Colors.red,
                      title:
                          "Weak Topic Alerts",
                      snapshot: snapshot,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    buildFixedStatCard(
                      icon: Icons
                          .auto_awesome_rounded,
                      color:
                          primaryPurple,
                      value: "7",
                      title: "AI Tools",
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(
                          13,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color: Colors
                                .grey
                                .shade200,
                          ),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor:
                                  Color(
                                0xFFEDE9FE,
                              ),
                              child: Icon(
                                Icons
                                    .tips_and_updates_rounded,
                                color:
                                    primaryPurple,
                                size: 20,
                              ),
                            ),
                            SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    "Smart Teaching",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        2,
                                  ),
                                  Text(
                                    "AI-assisted content creation",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                      fontSize:
                                          10.5,
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
                      width: 10,
                    ),

                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(
                          13,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color: Colors
                                .grey
                                .shade200,
                          ),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor:
                                  Color(
                                0xFFDCFCE7,
                              ),
                              child: Icon(
                                Icons
                                    .insights_rounded,
                                color:
                                    Colors
                                        .green,
                                size: 20,
                              ),
                            ),
                            SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    "Data Driven",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        2,
                                  ),
                                  Text(
                                    "Use student signals",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                      fontSize:
                                          10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                buildSectionTitle(
                  title: "Quick Actions",
                  subtitle:
                      "Jump directly to your most useful AI tools.",
                ),

                const SizedBox(
                  height: 14,
                ),

                Row(
                  children: [
                    buildQuickAction(
                      context: context,
                      icon: Icons
                          .menu_book_rounded,
                      color: Colors.blue,
                      title: "Lesson Plan",
                      onTap: () {
                        openLessonPlanner(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    buildQuickAction(
                      context: context,
                      icon: Icons.quiz_rounded,
                      color:
                          Colors.deepPurple,
                      title: "Question Paper",
                      onTap: () {
                        openQuestionPaper(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    buildQuickAction(
                      context: context,
                      icon: Icons
                          .fact_check_rounded,
                      color: Colors.green,
                      title: "Evaluate",
                      onTap: () {
                        openAnswerEvaluator(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    buildQuickAction(
                      context: context,
                      icon: Icons
                          .search_rounded,
                      color: Colors.red,
                      title: "Weak Topics",
                      onTap: () {
                        openWeakTopics(
                          context,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==================================================
                // AI TEACHING TOOLS
                // ==================================================

                buildSectionTitle(
                  title:
                      "AI Teaching Tools",
                  subtitle:
                      "Choose an AI tool for your teaching task.",
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // LESSON PLANNER
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons
                      .menu_book_rounded,
                  color: Colors.blue,
                  title:
                      "AI Lesson Planner",
                  subtitle:
                      "Generate a structured lesson plan from a topic, class level and teaching duration.",
                  onTap: () {
                    openLessonPlanner(
                      context,
                    );
                  },
                ),

                // ==================================================
                // QUESTION PAPER
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons.quiz_rounded,
                  color:
                      Colors.deepPurple,
                  title:
                      "Question Paper Generator",
                  subtitle:
                      "Create exam papers with marks, choices, sub-questions and your required pattern.",
                  onTap: () {
                    openQuestionPaper(
                      context,
                    );
                  },
                ),

                // ==================================================
                // ANSWER EVALUATOR
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons
                      .fact_check_rounded,
                  color: Colors.green,
                  title:
                      "AI Answer Evaluator",
                  subtitle:
                      "Analyze student answers and receive marks, corrections and teacher feedback.",
                  onTap: () {
                    openAnswerEvaluator(
                      context,
                    );
                  },
                ),

                // ==================================================
                // PERFORMANCE ANALYZER
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons
                      .analytics_rounded,
                  color: Colors.orange,
                  title:
                      "Student Performance Analyzer",
                  subtitle:
                      "Analyze attendance, assignments and assessment performance to identify students who need support.",
                  onTap: () {
                    showComingSoon(
                      context,
                      "Student Performance Analyzer",
                    );
                  },
                  comingSoon: true,
                ),

                // ==================================================
                // WEAK TOPICS
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons
                      .search_rounded,
                  color: Colors.red,
                  title:
                      "Weak Topic Detector",
                  subtitle:
                      "Identify repeated student doubts and topics that may need additional classroom support.",
                  onTap: () {
                    openWeakTopics(
                      context,
                    );
                  },
                ),

                // ==================================================
                // DOUBT SUMMARY
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons.forum_rounded,
                  color: Colors.pink,
                  title:
                      "Anonymous Doubt Summary",
                  subtitle:
                      "Summarize common student doubts and discover the concepts students are struggling with.",
                  onTap: () {
                    showComingSoon(
                      context,
                      "Anonymous Doubt Summary",
                    );
                  },
                  comingSoon: true,
                ),

                // ==================================================
                // ANNOUNCEMENT GENERATOR
                // ==================================================

                buildAITool(
                  context: context,
                  icon: Icons
                      .campaign_rounded,
                  color: Colors.teal,
                  title:
                      "AI Announcement Generator",
                  subtitle:
                      "Turn simple notes into clear, professional announcements for your students.",
                  onTap: () {
                    showComingSoon(
                      context,
                      "AI Announcement Generator",
                    );
                  },
                  comingSoon: true,
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // FOOTER
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                      BoxDecoration(
                    color: const Color(
                      0xFFF3E8FF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFE9D5FF,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                            const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons
                              .auto_awesome_rounded,
                          color:
                              primaryPurple,
                          size: 20,
                        ),
                      ),

                      const SizedBox(
                        width: 11,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              "SparkAI Teaching Workspace",
                              style:
                                  TextStyle(
                                color:
                                    primaryPurple,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              "More AI-powered teaching insights will be added here as SparkEdu grows.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    11.5,
                                height:
                                    1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}