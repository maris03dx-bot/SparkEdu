import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AcademicDashboardScreen extends StatelessWidget {
  const AcademicDashboardScreen({super.key});

  static const Color primaryColor = Color(0xFF6B4FD3);
  static const Color darkPurple = Color(0xFF4D36A8);
  static const Color lightPurple = Color(0xFFF2EEFF);
  static const Color backgroundColor = Color(0xFFF7F7FB);

  Future<DocumentSnapshot<Map<String, dynamic>>> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No student is currently logged in.');
    }

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      throw Exception('Student profile not found.');
    }

    return result.docs.first;
  }

  DateTime? _getDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final date = _getDate(value);

    if (date == null) {
      return '--';
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatShortDate(dynamic value) {
    final date = _getDate(value);

    if (date == null) {
      return '--';
    }

    return DateFormat('dd MMM').format(date);
  }

  String _formatTime(dynamic value) {
    final date = _getDate(value);

    if (date == null) {
      return '';
    }

    return DateFormat('hh:mm a').format(date);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  String _firstAvailableString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  bool _isCompletedAssignment(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase().trim();

    return status == 'completed' ||
        status == 'submitted' ||
        status == 'done' ||
        status == 'closed';
  }

  bool _isExpiredAssignment(Map<String, dynamic> data) {
    final dueDate = _getDate(
      data['dueDate'] ?? data['deadline'] ?? data['dueAt'],
    );

    if (dueDate == null) {
      return false;
    }

    return dueDate.isBefore(DateTime.now()) &&
        !_isCompletedAssignment(data);
  }

  bool _isUpcomingAssignment(Map<String, dynamic> data) {
    if (_isCompletedAssignment(data)) {
      return false;
    }

    final dueDate = _getDate(
      data['dueDate'] ?? data['deadline'] ?? data['dueAt'],
    );

    if (dueDate == null) {
      return true;
    }

    return !dueDate.isBefore(DateTime.now());
  }

  bool _isUpcomingEvent(Map<String, dynamic> data) {
    final eventDate = _getDate(
      data['eventDate'] ??
          data['date'] ??
          data['startDate'] ??
          data['startAt'] ??
          data['createdAt'],
    );

    if (eventDate == null) {
      return true;
    }

    return !eventDate.isBefore(DateTime.now());
  }

  int _countAttendanceStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String wantedStatus,
  ) {
    int count = 0;

    for (final doc in documents) {
      final status = doc.data()['status']?.toString().toLowerCase().trim();

      if (status == wantedStatus) {
        count++;
      }
    }

    return count;
  }

  int _countValidAttendanceRecords(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    int count = 0;

    for (final doc in documents) {
      final status = doc.data()['status']?.toString().toLowerCase().trim();

      if (status == 'present' ||
          status == 'absent' ||
          status == 'late' ||
          status == 'leave') {
        count++;
      }
    }

    return count;
  }

  double _calculateAttendancePercentage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    if (documents.isEmpty) {
      return 0;
    }

    int present = 0;
    int total = 0;

    for (final doc in documents) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase().trim();

      if (status == null || status.isEmpty) {
        continue;
      }

      if (status == 'present' ||
          status == 'absent' ||
          status == 'late' ||
          status == 'leave') {
        total++;

        if (status == 'present' || status == 'late') {
          present++;
        }
      }
    }

    if (total == 0) {
      return 0;
    }

    return (present / total) * 100;
  }

  Color _attendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    }

    if (percentage >= 75) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String _attendanceStatus(double percentage, int attendanceCount) {
    if (attendanceCount == 0) {
      return 'No attendance data yet';
    }

    if (percentage >= 90) {
      return 'Excellent attendance';
    }

    if (percentage >= 75) {
      return 'Attendance needs attention';
    }

    return 'Attendance is at risk';
  }

  String _getAcademicPriority({
    required double attendance,
    required int pendingAssignments,
    required int overdueAssignments,
    required int upcomingEvents,
    required int pendingLeaves,
  }) {
    if (attendance > 0 && attendance < 75) {
      return 'Improve attendance';
    }

    if (overdueAssignments > 0) {
      return 'Complete overdue work';
    }

    if (pendingAssignments >= 3) {
      return 'Focus on assignments';
    }

    if (pendingLeaves > 0) {
      return 'Check leave requests';
    }

    if (upcomingEvents > 0) {
      return 'Stay updated with events';
    }

    return 'Maintain your learning rhythm';
  }

  String _getInsightMessage({
    required double attendance,
    required int pendingAssignments,
    required int overdueAssignments,
    required int upcomingEvents,
    required int pendingLeaves,
  }) {
    if (attendance > 0 && attendance < 75) {
      return 'Your attendance needs immediate attention. Try to attend upcoming classes regularly and avoid unnecessary absences.';
    }

    if (overdueAssignments > 0) {
      return 'You have overdue academic work. Complete the oldest pending task first to get back on track.';
    }

    if (pendingAssignments >= 3) {
      return 'You have several pending assignments. Create a small study plan and complete them one by one.';
    }

    if (attendance >= 90 && pendingAssignments == 0) {
      return 'Excellent work! Your attendance and academic workload look healthy. Keep maintaining this consistency.';
    }

    if (upcomingEvents > 0) {
      return 'Your academic schedule looks manageable. Keep an eye on upcoming events and continue your regular study routine.';
    }

    if (pendingLeaves > 0) {
      return 'You have a leave request awaiting attention. Check its current status when convenient.';
    }

    return 'Stay consistent with your classes, assignments and academic activities. Small daily progress creates strong results.';
  }

  int _calculateAcademicScore({
    required double attendance,
    required int pendingAssignments,
    required int overdueAssignments,
    required int upcomingEvents,
    required int pendingLeaves,
  }) {
    double score = 60;

    if (attendance >= 90) {
      score += 25;
    } else if (attendance >= 80) {
      score += 18;
    } else if (attendance >= 75) {
      score += 10;
    } else if (attendance > 0) {
      score -= 10;
    }

    if (pendingAssignments == 0) {
      score += 10;
    } else if (pendingAssignments <= 2) {
      score += 5;
    } else {
      score -= 5;
    }

    if (overdueAssignments > 0) {
      score -= overdueAssignments * 8;
    }

    if (upcomingEvents > 0) {
      score += 2;
    }

    if (pendingLeaves > 0) {
      score -= 2;
    }

    return score.clamp(0, 100).round();
  }

  String _scoreLabel(int score) {
    if (score >= 90) {
      return 'Excellent';
    }

    if (score >= 75) {
      return 'Good';
    }

    if (score >= 60) {
      return 'Needs Attention';
    }

    return 'Needs Improvement';
  }

  Color _scoreColor(int score) {
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return primaryColor;
    }

    if (score >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getStudentData(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (studentSnapshot.hasError) {
            return _ErrorView(
              message: studentSnapshot.error.toString(),
              onRetry: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AcademicDashboardScreen(),
                  ),
                );
              },
            );
          }

          if (!studentSnapshot.hasData) {
            return const _ErrorView(
              message: 'Unable to load student information.',
            );
          }

          final studentData = studentSnapshot.data!.data() ?? {};

          final studentName = _firstAvailableString(
            studentData,
            ['name', 'studentName', 'fullName', 'displayName'],
            fallback: 'Student',
          );

          final registerNumber = _firstAvailableString(
            studentData,
            ['registerNo', 'rollNo', 'registerNumber', 'rollNumber'],
            fallback: 'Not available',
          );

          final department = _firstAvailableString(
            studentData,
            ['department', 'dept'],
          );

          final year = _firstAvailableString(
            studentData,
            ['year'],
          );

          final section = _firstAvailableString(
            studentData,
            ['section'],
          );

          final studentId = _firstAvailableString(
            studentData,
            ['uid', 'studentId'],
            fallback: FirebaseAuth.instance.currentUser?.uid ?? '',
          );

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('studentId', isEqualTo: studentId)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              final attendanceDocs =
                  attendanceSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              final attendancePercentage =
                  _calculateAttendancePercentage(attendanceDocs);

              final presentCount =
                  _countAttendanceStatus(attendanceDocs, 'present');

              final absentCount =
                  _countAttendanceStatus(attendanceDocs, 'absent');

              final lateCount =
                  _countAttendanceStatus(attendanceDocs, 'late');

              final leaveAttendanceCount =
                  _countAttendanceStatus(attendanceDocs, 'leave');

              final validAttendanceCount =
                  _countValidAttendanceRecords(attendanceDocs);

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('assignments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, assignmentSnapshot) {
                  final assignmentDocs =
                      assignmentSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                  final assignments = assignmentDocs
                      .map((doc) => doc.data())
                      .toList();

                  final completedAssignments = assignments
                      .where(_isCompletedAssignment)
                      .length;

                  final pendingAssignments =
                      assignments.where(_isUpcomingAssignment).length;

                  final overdueAssignments =
                      assignments.where(_isExpiredAssignment).length;

                  final upcomingAssignmentList = assignments
                      .where(_isUpcomingAssignment)
                      .toList();

                  upcomingAssignmentList.sort((a, b) {
                    final aDate = _getDate(
                      a['dueDate'] ?? a['deadline'] ?? a['dueAt'],
                    );

                    final bDate = _getDate(
                      b['dueDate'] ?? b['deadline'] ?? b['dueAt'],
                    );

                    if (aDate == null && bDate == null) {
                      return 0;
                    }

                    if (aDate == null) {
                      return 1;
                    }

                    if (bDate == null) {
                      return -1;
                    }

                    return aDate.compareTo(bDate);
                  });

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, eventSnapshot) {
                      final eventDocs =
                          eventSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      final events = eventDocs
                          .map((doc) => doc.data())
                          .where(_isUpcomingEvent)
                          .toList();

                      events.sort((a, b) {
                        final aDate = _getDate(
                          a['eventDate'] ??
                              a['date'] ??
                              a['startDate'] ??
                              a['startAt'] ??
                              a['createdAt'],
                        );

                        final bDate = _getDate(
                          b['eventDate'] ??
                              b['date'] ??
                              b['startDate'] ??
                              b['startAt'] ??
                              b['createdAt'],
                        );

                        if (aDate == null && bDate == null) {
                          return 0;
                        }

                        if (aDate == null) {
                          return 1;
                        }

                        if (bDate == null) {
                          return -1;
                        }

                        return aDate.compareTo(bDate);
                      });

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('leave_requests')
                            .where(
                              'studentUid',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.uid,
                            )
                            .snapshots(),
                        builder: (context, leaveSnapshot) {
                          final leaveDocs =
                              leaveSnapshot.data?.docs ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                          final pendingLeaves = leaveDocs.where((doc) {
                            final status = doc
                                .data()['status']
                                ?.toString()
                                .toLowerCase()
                                .trim();

                            return status == 'pending';
                          }).length;

                          final approvedLeaves = leaveDocs.where((doc) {
                            final status = doc
                                .data()['status']
                                ?.toString()
                                .toLowerCase()
                                .trim();

                            return status == 'approved';
                          }).length;

                          final rejectedLeaves = leaveDocs.where((doc) {
                            final status = doc
                                .data()['status']
                                ?.toString()
                                .toLowerCase()
                                .trim();

                            return status == 'rejected';
                          }).length;

                          final academicScore = _calculateAcademicScore(
                            attendance: attendancePercentage,
                            pendingAssignments: pendingAssignments,
                            overdueAssignments: overdueAssignments,
                            upcomingEvents: events.length,
                            pendingLeaves: pendingLeaves,
                          );

                          final priority = _getAcademicPriority(
                            attendance: attendancePercentage,
                            pendingAssignments: pendingAssignments,
                            overdueAssignments: overdueAssignments,
                            upcomingEvents: events.length,
                            pendingLeaves: pendingLeaves,
                          );

                          final insightMessage = _getInsightMessage(
                            attendance: attendancePercentage,
                            pendingAssignments: pendingAssignments,
                            overdueAssignments: overdueAssignments,
                            upcomingEvents: events.length,
                            pendingLeaves: pendingLeaves,
                          );

                          return RefreshIndicator(
                            color: primaryColor,
                            onRefresh: () async {
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                            },
                            child: CustomScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: _buildHeader(
                                    studentName,
                                    registerNumber,
                                    department,
                                    year,
                                    section,
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    35,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildListDelegate(
                                      [
                                        _buildSparkAIInsightCard(
                                          academicScore: academicScore,
                                          priority: priority,
                                          message: insightMessage,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildSectionTitle(
                                          'Academic Overview',
                                          'A clear summary of your current academic activity',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildOverviewGrid(
                                          attendancePercentage:
                                              attendancePercentage,
                                          attendanceTotal:
                                              validAttendanceCount,
                                          presentCount: presentCount,
                                          absentCount: absentCount,
                                          lateCount: lateCount,
                                          leaveAttendanceCount:
                                              leaveAttendanceCount,
                                          pendingAssignments:
                                              pendingAssignments,
                                          overdueAssignments:
                                              overdueAssignments,
                                          completedAssignments:
                                              completedAssignments,
                                          upcomingEvents: events.length,
                                          pendingLeaves: pendingLeaves,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildAttendanceCard(
                                          attendancePercentage,
                                          validAttendanceCount,
                                          presentCount,
                                          absentCount,
                                          lateCount,
                                          leaveAttendanceCount,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildAssignmentsCard(
                                          assignments.length,
                                          completedAssignments,
                                          pendingAssignments,
                                          overdueAssignments,
                                          upcomingAssignmentList,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildEventsCard(events),
                                        const SizedBox(height: 22),
                                        _buildLeaveCard(
                                          leaveDocs.length,
                                          pendingLeaves,
                                          approvedLeaves,
                                          rejectedLeaves,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildSectionTitle(
                                          'Academic Focus',
                                          'Areas that currently need your attention',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFocusCard(
                                          attendancePercentage,
                                          pendingAssignments,
                                          overdueAssignments,
                                          events.length,
                                          pendingLeaves,
                                        ),
                                        const SizedBox(height: 22),
                                        _buildDailyAdviceCard(
                                          attendancePercentage,
                                          pendingAssignments,
                                          overdueAssignments,
                                          events.length,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

  Widget _buildHeader(
    String studentName,
    String registerNumber,
    String department,
    String year,
    String section,
  ) {
    final classParts = <String>[
      if (department.isNotEmpty) department,
      if (year.isNotEmpty) 'Year $year',
      if (section.isNotEmpty) 'Section $section',
    ];

    final classInfo =
        classParts.isEmpty ? 'Student Profile' : classParts.join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            darkPurple,
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'SparkAI Academic Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              '${_getGreeting()},',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              studentName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classInfo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register No: $registerNumber',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 12,
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

  Widget _buildSparkAIInsightCard({
    required int academicScore,
    required String priority,
    required String message,
  }) {
    final scoreColor = _scoreColor(academicScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: primaryColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SparkAI Insight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF252331),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your academic health at a glance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$academicScore',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Score',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _scoreLabel(academicScore),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Calculated from your current academic activity.',
                      style: TextStyle(
                        color: Color(0xFF777380),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FE),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF4B4858),
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: primaryColor,
                  size: 19,
                ),
                const SizedBox(width: 9),
                const Text(
                  'Current priority',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    priority,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF252331),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid({
    required double attendancePercentage,
    required int attendanceTotal,
    required int presentCount,
    required int absentCount,
    required int lateCount,
    required int leaveAttendanceCount,
    required int pendingAssignments,
    required int overdueAssignments,
    required int completedAssignments,
    required int upcomingEvents,
    required int pendingLeaves,
  }) {
    return Column(
      children: [
        _attendanceOverviewCard(
          attendancePercentage: attendancePercentage,
          attendanceTotal: attendanceTotal,
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          leaveAttendanceCount: leaveAttendanceCount,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _overviewCard(
              icon: Icons.assignment_rounded,
              title: 'Assignments',
              value: '$pendingAssignments',
              subtitle: overdueAssignments > 0
                  ? '$overdueAssignments overdue'
                  : '$completedAssignments completed',
              iconColor: overdueAssignments > 0
                  ? Colors.red
                  : primaryColor,
            ),
            _overviewCard(
              icon: Icons.event_rounded,
              title: 'Events',
              value: '$upcomingEvents',
              subtitle: upcomingEvents == 0
                  ? 'Nothing upcoming'
                  : 'Upcoming events',
              iconColor: Colors.orange,
            ),
            _overviewCard(
              icon: Icons.description_rounded,
              title: 'Leave',
              value: '$pendingLeaves',
              subtitle: pendingLeaves == 0
                  ? 'No pending requests'
                  : 'Awaiting review',
              iconColor: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _attendanceOverviewCard({
    required double attendancePercentage,
    required int attendanceTotal,
    required int presentCount,
    required int absentCount,
    required int lateCount,
    required int leaveAttendanceCount,
  }) {
    final color = _attendanceColor(attendancePercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        color: Color(0xFF302D3A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Current attendance details',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    attendancePercentage == 0
                        ? '--'
                        : '${attendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    attendanceTotal == 0
                        ? 'No records'
                        : '$attendanceTotal records',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: attendancePercentage == 0
                  ? 0
                  : (attendancePercentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _attendanceStatus(
              attendancePercentage,
              attendanceTotal,
            ),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _overviewAttendanceDetail(
                  icon: Icons.check_circle_rounded,
                  title: 'Present',
                  value: presentCount,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _overviewAttendanceDetail(
                  icon: Icons.cancel_rounded,
                  title: 'Absent',
                  value: absentCount,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _overviewAttendanceDetail(
                  icon: Icons.schedule_rounded,
                  title: 'Late',
                  value: lateCount,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _overviewAttendanceDetail(
                  icon: Icons.event_busy_rounded,
                  title: 'Leave',
                  value: leaveAttendanceCount,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewAttendanceDetail({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.045),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF252331),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF34313F),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    double attendancePercentage,
    int attendanceCount,
    int presentCount,
    int absentCount,
    int lateCount,
    int leaveCount,
  ) {
    final color = _attendanceColor(attendancePercentage);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.show_chart_rounded,
                color,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Detailed attendance breakdown',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                attendancePercentage == 0
                    ? '--'
                    : '${attendancePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: attendancePercentage == 0
                  ? 0
                  : (attendancePercentage / 100).clamp(0.0, 1.0),
              minHeight: 11,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _attendanceStatus(
              attendancePercentage,
              attendanceCount,
            ),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _attendanceMiniStat(
                  'Present',
                  '$presentCount',
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _attendanceMiniStat(
                  'Absent',
                  '$absentCount',
                  Colors.red,
                  Icons.cancel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _attendanceMiniStat(
                  'Late',
                  '$lateCount',
                  Colors.orange,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _attendanceMiniStat(
                  'Leave',
                  '$leaveCount',
                  Colors.teal,
                  Icons.event_busy_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'Total attendance records: $attendanceCount',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceMiniStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsCard(
    int total,
    int completed,
    int pending,
    int overdue,
    List<Map<String, dynamic>> upcomingAssignments,
  ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.assignment_rounded,
                primaryColor,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your current assignment workload',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _countBox(
                  'Total',
                  '$total',
                  Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _countBox(
                  'Pending',
                  '$pending',
                  primaryColor,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _countBox(
                  'Done',
                  '$completed',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _countBox(
                  'Overdue',
                  '$overdue',
                  overdue > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Upcoming Assignment Work',
            style: TextStyle(
              color: Color(0xFF302D3A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (upcomingAssignments.isEmpty)
            _emptySmallState(
              Icons.task_alt_rounded,
              'No pending assignments',
              'You are currently caught up.',
              Colors.green,
            )
          else
            Column(
              children: [
                for (final assignment
                    in upcomingAssignments.take(5)) ...[
                  _buildAssignmentItem(assignment),
                  if (assignment != upcomingAssignments.take(5).last)
                    Divider(
                      height: 18,
                      color: Colors.grey.shade200,
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(
    Map<String, dynamic> assignment,
  ) {
    final title = _firstAvailableString(
      assignment,
      ['title', 'assignmentTitle', 'name'],
      fallback: 'Assignment',
    );

    final subject = _firstAvailableString(
      assignment,
      ['subjectName', 'subject', 'subjectCode'],
      fallback: 'Academic work',
    );

    final dueDate = assignment['dueDate'] ??
        assignment['deadline'] ??
        assignment['dueAt'];

    final expired = _isExpiredAssignment(assignment);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(
            expired
                ? Icons.warning_rounded
                : Icons.assignment_rounded,
            expired ? Colors.red : primaryColor,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF292633),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 14,
                      color: expired ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dueDate == null
                          ? 'Due date not available'
                          : 'Due ${_formatDate(dueDate)}',
                      style: TextStyle(
                        color: expired ? Colors.red : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (expired)
            _statusChip(
              'OVERDUE',
              Colors.red,
            )
          else
            _statusChip(
              'PENDING',
              primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildEventsCard(
    List<Map<String, dynamic>> events,
  ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.event_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Academic events you should keep track of',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (events.isEmpty)
            _emptySmallState(
              Icons.event_available_rounded,
              'No upcoming events',
              'There are no upcoming events available right now.',
              Colors.orange,
            )
          else
            Column(
              children: [
                for (final event in events.take(6)) ...[
                  _buildEventItem(event),
                  if (event != events.take(6).last)
                    Divider(
                      height: 18,
                      color: Colors.grey.shade200,
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(
    Map<String, dynamic> event,
  ) {
    final title = _firstAvailableString(
      event,
      ['title', 'eventName', 'name'],
      fallback: 'Academic Event',
    );

    final description = _firstAvailableString(
      event,
      ['description', 'message', 'details'],
      fallback: 'Academic activity',
    );

    final eventDate = event['eventDate'] ??
        event['date'] ??
        event['startDate'] ??
        event['startAt'] ??
        event['createdAt'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.orange,
                size: 17,
              ),
              const SizedBox(height: 3),
              Text(
                _formatShortDate(eventDate),
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF292633),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              if (_formatTime(eventDate).isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(eventDate),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(
    int total,
    int pending,
    int approved,
    int rejected,
  ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.description_rounded,
                Colors.teal,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Current status of your leave requests',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _leaveStat(
                  'Total',
                  total,
                  Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _leaveStat(
                  'Pending',
                  pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _leaveStat(
                  'Approved',
                  approved,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _leaveStat(
                  'Rejected',
                  rejected,
                  Colors.red,
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$pending leave request${pending == 1 ? '' : 's'} awaiting review.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leaveStat(
    String title,
    int value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(
    double attendance,
    int pendingAssignments,
    int overdueAssignments,
    int upcomingEvents,
    int pendingLeaves,
  ) {
    final List<_FocusItem> items = [];

    if (attendance > 0 && attendance < 75) {
      items.add(
        const _FocusItem(
          icon: Icons.warning_rounded,
          title: 'Attendance',
          description:
              'Your attendance is below the safe level. Prioritize regular class attendance.',
          color: Colors.red,
        ),
      );
    } else if (attendance > 0 && attendance < 90) {
      items.add(
        const _FocusItem(
          icon: Icons.info_rounded,
          title: 'Attendance',
          description:
              'Try to keep your attendance above 90% for a healthier academic record.',
          color: Colors.orange,
        ),
      );
    }

    if (overdueAssignments > 0) {
      items.add(
        _FocusItem(
          icon: Icons.priority_high_rounded,
          title: 'Overdue work',
          description:
              '$overdueAssignments assignment${overdueAssignments == 1 ? '' : 's'} need immediate attention.',
          color: Colors.red,
        ),
      );
    } else if (pendingAssignments > 0) {
      items.add(
        _FocusItem(
          icon: Icons.assignment_late_rounded,
          title: 'Pending assignments',
          description:
              '$pendingAssignments assignment${pendingAssignments == 1 ? '' : 's'} currently need completion.',
          color: primaryColor,
        ),
      );
    }

    if (pendingLeaves > 0) {
      items.add(
        _FocusItem(
          icon: Icons.pending_actions_rounded,
          title: 'Leave request',
          description:
              '$pendingLeaves leave request${pendingLeaves == 1 ? '' : 's'} awaiting review.',
          color: Colors.teal,
        ),
      );
    }

    if (upcomingEvents > 0) {
      items.add(
        _FocusItem(
          icon: Icons.event_available_rounded,
          title: 'Upcoming events',
          description:
              '$upcomingEvents upcoming academic event${upcomingEvents == 1 ? '' : 's'} available.',
          color: Colors.orange,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _FocusItem(
          icon: Icons.check_circle_rounded,
          title: 'Everything looks good',
          description:
              'No major academic attention areas were detected right now.',
          color: Colors.green,
        ),
      );
    }

    return _sectionCard(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildFocusItem(items[i]),
            if (i != items.length - 1)
              Divider(
                height: 25,
                color: Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFocusItem(
    _FocusItem item,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(
          item.icon,
          item.color,
          size: 42,
          iconSize: 21,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF292633),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyAdviceCard(
    double attendance,
    int pendingAssignments,
    int overdueAssignments,
    int upcomingEvents,
  ) {
    String message;
    IconData icon;

    if (attendance > 0 && attendance < 75) {
      message =
          'Make attendance your first priority. Being present consistently will help protect your academic progress.';
      icon = Icons.school_rounded;
    } else if (overdueAssignments > 0) {
      message =
          'Start with your overdue assignment before taking on new academic work.';
      icon = Icons.edit_note_rounded;
    } else if (pendingAssignments > 0) {
      message =
          'Spend a focused study session completing one pending assignment today.';
      icon = Icons.timer_rounded;
    } else if (upcomingEvents > 0) {
      message =
          'Stay aware of your upcoming academic events while continuing your normal study routine.';
      icon = Icons.lightbulb_rounded;
    } else {
      message =
          'You are in a good position. Use some time today for revision, practice questions or learning something new.';
      icon = Icons.auto_awesome_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            lightPurple,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(
            icon,
            primaryColor,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Advice',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF4B4858),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.045),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color, {
    double size = 44,
    double iconSize = 23,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }

  Widget _countBox(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptySmallState(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 31,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FocusItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load academic insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4FD3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}