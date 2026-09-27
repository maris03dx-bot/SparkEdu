import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceDashboardScreen extends StatelessWidget {
  const AttendanceDashboardScreen({super.key});

  // ============================================================
  // GET CURRENT STUDENT REGISTER NUMBER
  // ============================================================

  Future<String?> getStudentId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final userQuery = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return null;
    }

    final data = userQuery.docs.first.data();

    final registerNo = data["registerNo"]?.toString().trim();

    if (registerNo != null && registerNo.isNotEmpty) {
      return registerNo;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF8F6FC),
        foregroundColor: const Color(0xFF211A2D),
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: getStudentId(),
        builder: (
          context,
          studentSnapshot,
        ) {
          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
            );
          }

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

          final studentId = studentSnapshot.data;

          if (studentId == null) {
            return const Center(
              child: Text(
                "Student Register No not found.",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("attendance")
                .where(
                  "studentId",
                  isEqualTo: studentId,
                )
                .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Error loading attendance:\n\n"
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C3AED),
                  ),
                );
              }

              final attendance =
                  snapshot.data?.docs ?? [];

              if (attendance.isEmpty) {
                return RefreshIndicator(
                  color: const Color(0xFF7C3AED),
                  onRefresh: () async {
                    await Future.delayed(
                      const Duration(
                        milliseconds: 500,
                      ),
                    );
                  },
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(context)
                                    .size
                                    .height *
                                0.17,
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration:
                            const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF7C3AED),
                          size: 45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No Attendance Yet",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your attendance will appear here after you attend a class.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ==================================================
              // CALCULATE ATTENDANCE
              // ==================================================

              final Map<String, int> total = {};
              final Map<String, int> present = {};

              for (final doc in attendance) {
                final data =
                    doc.data() as Map<String, dynamic>;

                final subject =
                    data["subject"]
                            ?.toString()
                            .trim() ??
                        "Unknown Subject";

                total[subject] =
                    (total[subject] ?? 0) + 1;

                final status =
                    data["status"]
                            ?.toString()
                            .trim()
                            .toLowerCase() ??
                        "";

                if (status == "present") {
                  present[subject] =
                      (present[subject] ?? 0) + 1;
                }
              }

              final subjects =
                  total.keys.toList();

              // ==================================================
              // OVERALL
              // ==================================================

              int overallPresent = 0;
              int overallTotal = 0;

              for (final subject in subjects) {
                overallPresent +=
                    present[subject] ?? 0;

                overallTotal +=
                    total[subject] ?? 0;
              }

              final double overall =
                  overallTotal == 0
                      ? 0.0
                      : (overallPresent /
                              overallTotal) *
                          100;

              // ==================================================
              // MAIN CONTENT
              // ==================================================

              return RefreshIndicator(
                color: const Color(0xFF7C3AED),
                onRefresh: () async {
                  await Future.delayed(
                    const Duration(
                      milliseconds: 500,
                    ),
                  );
                },
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    30,
                  ),
                  children: [
                    // ==========================================
                    // HEADER
                    // ==========================================

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(0xFFEDE9FE),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color:
                                  Color(0xFF7C3AED),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attendance Analytics",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Tap a subject to view details",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${overall.toStringAsFixed(0)}%",
                            style: TextStyle(
                              color:
                                  _getAttendanceColor(
                                overall,
                              ),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // TITLE
                    // ==========================================

                    const Text(
                      "Subject Attendance",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "Tap a subject to see its attendance percentage",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _InteractiveAttendanceChart(
                      subjects: subjects,
                      present: present,
                      total: total,
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // LEGEND
                    // ==========================================

                    Container(
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _legendItem(
                            color:
                                const Color(0xFF22C55E),
                            text: "75%+ Good",
                          ),
                          _legendItem(
                            color:
                                const Color(0xFFF59E0B),
                            text: "60–74% Improve",
                          ),
                          _legendItem(
                            color:
                                const Color(0xFFEF4444),
                            text: "<60% Low",
                          ),
                        ],
                      ),
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

  // ============================================================
  // STATIC ATTENDANCE COLOR
  // ============================================================

  static Color _getAttendanceColor(
    double percentage,
  ) {
    if (percentage >= 75) {
      return const Color(0xFF22C55E);
    }

    if (percentage >= 60) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFFEF4444);
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _legendItem({
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// INTERACTIVE ATTENDANCE CHART
// ==================================================================

class _InteractiveAttendanceChart extends StatefulWidget {
  final List<String> subjects;
  final Map<String, int> present;
  final Map<String, int> total;

  const _InteractiveAttendanceChart({
    required this.subjects,
    required this.present,
    required this.total,
  });

  @override
  State<_InteractiveAttendanceChart> createState() =>
      _InteractiveAttendanceChartState();
}

class _InteractiveAttendanceChartState
    extends State<_InteractiveAttendanceChart> {
  String? selectedSubject;

  // ============================================================
  // CHART CONSTANTS
  //
  // The percentage scale, grid and bars MUST use
  // exactly the same chart height.
  // ============================================================

  static const double chartHeight = 330;

  // ============================================================
  // SELECT SUBJECT
  // ============================================================

  void selectSubject(String subject) {
    setState(() {
      if (selectedSubject == subject) {
        selectedSubject = null;
      } else {
        selectedSubject = subject;
      }
    });
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color getAttendanceColor(
    double percentage,
  ) {
    if (percentage >= 75) {
      return const Color(0xFF22C55E);
    }

    if (percentage >= 60) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFFEF4444);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String getStatus(
    double percentage,
  ) {
    if (percentage >= 75) {
      return "Good Attendance";
    }

    if (percentage >= 60) {
      return "Needs Improvement";
    }

    return "Low Attendance";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ========================================================
        // CHART CARD
        // ========================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            12,
            20,
            12,
            10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.04,
                ),
                blurRadius: 12,
                offset: const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: SizedBox(
            height: chartHeight + 54,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // LEFT PERCENTAGE SCALE
                // ==================================================

                SizedBox(
                  width: 42,
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: const [
                      _ScaleText("100%"),
                      _ScaleText("90%"),
                      _ScaleText("80%"),
                      _ScaleText("70%"),
                      _ScaleText("60%"),
                      _ScaleText("50%"),
                      _ScaleText("40%"),
                      _ScaleText("30%"),
                      _ScaleText("20%"),
                      _ScaleText("10%"),
                      _ScaleText("0%"),
                    ],
                  ),
                ),

                // ==================================================
                // CHART + SUBJECT LABELS
                // ==================================================

                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: chartHeight,
                        child: Stack(
                          children: [
                            // ----------------------------------------
                            // GRID LINES
                            // ----------------------------------------

                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: List.generate(
                                  11,
                                  (index) {
                                    return Container(
                                      height: 1,
                                      width:
                                          double.infinity,
                                      color:
                                          Colors.grey.shade200,
                                    );
                                  },
                                ),
                              ),
                            ),

                            // ----------------------------------------
                            // BARS
                            // ----------------------------------------

                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(
                                  left: 10,
                                  right: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceEvenly,
                                  children:
                                      widget.subjects.map(
                                    (subject) {
                                      final totalClasses =
                                          widget.total[
                                                  subject] ??
                                              0;

                                      final presentClasses =
                                          widget.present[
                                                  subject] ??
                                              0;

                                      final percentage =
                                          totalClasses == 0
                                              ? 0.0
                                              : (presentClasses /
                                                      totalClasses) *
                                                  100;

                                      final color =
                                          getAttendanceColor(
                                        percentage,
                                      );

                                      final isSelected =
                                          selectedSubject ==
                                              subject;

                                      final barHeight =
                                          chartHeight *
                                              (percentage /
                                                  100);

                                      return Expanded(
                                        child:
                                            GestureDetector(
                                          behavior:
                                              HitTestBehavior
                                                  .opaque,
                                          onTap: () {
                                            selectSubject(
                                              subject,
                                            );
                                          },
                                          child: Align(
                                            alignment:
                                                Alignment
                                                    .bottomCenter,
                                            child:
                                                AnimatedContainer(
                                              duration:
                                                  const Duration(
                                                milliseconds:
                                                    450,
                                              ),
                                              curve:
                                                  Curves
                                                      .easeOutCubic,
                                              width:
                                                  isSelected
                                                      ? 40
                                                      : 30,
                                              height:
                                                  barHeight,
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    color,
                                                borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                  top:
                                                      Radius.circular(
                                                    10,
                                                  ),
                                                ),
                                                boxShadow:
                                                    isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color:
                                                                  color.withValues(
                                                                alpha:
                                                                    0.30,
                                                              ),
                                                              blurRadius:
                                                                  12,
                                                              offset:
                                                                  const Offset(
                                                                0,
                                                                -2,
                                                              ),
                                                            ),
                                                          ]
                                                        : null,
                                              ),
                                              child:
                                                  AnimatedSwitcher(
                                                duration:
                                                    const Duration(
                                                  milliseconds:
                                                      200,
                                                ),
                                                child:
                                                    isSelected
                                                        ? Center(
                                                            key:
                                                                const ValueKey(
                                                              "percentage",
                                                            ),
                                                            child:
                                                                RotatedBox(
                                                              quarterTurns:
                                                                  3,
                                                              child:
                                                                  Text(
                                                                "${percentage.toStringAsFixed(0)}%",
                                                                style:
                                                                    const TextStyle(
                                                                  color:
                                                                      Colors.white,
                                                                  fontSize:
                                                                      11,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : const SizedBox(
                                                            key:
                                                                ValueKey(
                                                              "empty",
                                                            ),
                                                          ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ============================================
                      // SUBJECT NAMES
                      // ============================================

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 46,
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children:
                              widget.subjects.map(
                            (subject) {
                              final totalClasses =
                                  widget.total[
                                          subject] ??
                                      0;

                              final presentClasses =
                                  widget.present[
                                          subject] ??
                                      0;

                              final percentage =
                                  totalClasses == 0
                                      ? 0.0
                                      : (presentClasses /
                                              totalClasses) *
                                          100;

                              final color =
                                  getAttendanceColor(
                                percentage,
                              );

                              final isSelected =
                                  selectedSubject ==
                                      subject;

                              return Expanded(
                                child: GestureDetector(
                                  behavior:
                                      HitTestBehavior.opaque,
                                  onTap: () {
                                    selectSubject(
                                      subject,
                                    );
                                  },
                                  child: Center(
                                    child:
                                        AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            250,
                                      ),
                                      curve:
                                          Curves
                                              .easeOutCubic,
                                      style:
                                          TextStyle(
                                        color:
                                            isSelected
                                                ? color
                                                : Colors.black87,
                                        fontSize: 10,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                      ),
                                      child: Text(
                                        subject,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ========================================================
        // SMOOTH DETAILS AREA
        // ========================================================

        AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 350),
          reverseDuration:
              const Duration(milliseconds: 250),
          switchInCurve:
              Curves.easeOutCubic,
          switchOutCurve:
              Curves.easeInCubic,
          transitionBuilder:
              (
            Widget child,
            Animation<double> animation,
          ) {
            final slideAnimation =
                Tween<Offset>(
              begin:
                  const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          child: selectedSubject == null
              ? const SizedBox(
                  key: ValueKey(
                    "nothing-selected",
                  ),
                )
              : _buildSelectedDetails(
                  selectedSubject!,
                ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTED DETAILS
  // ============================================================

  Widget _buildSelectedDetails(
    String subject,
  ) {
    final totalClasses =
        widget.total[subject] ?? 0;

    final presentClasses =
        widget.present[subject] ?? 0;

    final absentClasses =
        totalClasses - presentClasses;

    final percentage =
        totalClasses == 0
            ? 0.0
            : (presentClasses /
                    totalClasses) *
                100;

    final color =
        getAttendanceColor(
      percentage,
    );

    return Container(
      key: ValueKey(
        "details-$subject",
      ),
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 18,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: 0.35,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: 0.10,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ======================================================
          // SUBJECT + PERCENTAGE
          // ======================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: percentage,
                ),
                duration:
                    const Duration(
                  milliseconds: 450,
                ),
                curve:
                    Curves.easeOutCubic,
                builder: (
                  context,
                  value,
                  child,
                ) {
                  return Text(
                    "${value.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ======================================================
          // STATUS
          // ======================================================

          Row(
            children: [
              Icon(
                percentage >= 75
                    ? Icons
                        .check_circle_rounded
                    : percentage >= 60
                        ? Icons
                            .warning_rounded
                        : Icons
                            .error_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                getStatus(
                  percentage,
                ),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // DETAILS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon:
                      Icons.check_rounded,
                  label: "Present",
                  value:
                      "$presentClasses",
                  color:
                      const Color(
                    0xFF22C55E,
                  ),
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon:
                      Icons.close_rounded,
                  label: "Absent",
                  value:
                      "$absentClasses",
                  color:
                      const Color(
                    0xFFEF4444,
                  ),
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon: Icons
                      .calendar_today_rounded,
                  label: "Total",
                  value:
                      "$totalClasses",
                  color:
                      const Color(
                    0xFF6366F1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// SCALE TEXT
// ================================================================

class _ScaleText extends StatelessWidget {
  final String text;

  const _ScaleText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}