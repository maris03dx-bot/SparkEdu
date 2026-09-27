import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'attendance_screen.dart';
import 'subjects_screen.dart';
import '../../utils/logout_helper.dart';
import 'assignment_screen.dart';

import '../communication/communication_home.dart';
import 'event_request_screen.dart';
import '../../ai/chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // ============================================================
  // GET STUDENT DATA
  // ============================================================

  Future<Map<String, dynamic>?> _getStudentData() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  // ============================================================
  // OPEN SPARKAI
  // ============================================================

  void _openSparkAI() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text('SparkEdu'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              LogoutHelper.showLogoutDialog(context);
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getStudentData(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (studentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading student data:\n'
                  '${studentSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final studentData = studentSnapshot.data ?? {};

          final user = currentUser;

          final studentUid = user?.uid ?? '';

          final studentName =
              studentData['name'] ??
              user?.displayName ??
              'Student';

          final rollNo =
              studentData['rollNo'] ??
              studentData['registerNo'] ??
              'N/A';

          final studentId = rollNo.toString();

          return _buildStudentDashboard(
            studentUid: studentUid,
            studentName: studentName.toString(),
            studentId: studentId,
            studentData: studentData,
          );
        },
      ),
    );
  }

  // ============================================================
  // STUDENT DASHBOARD
  // ============================================================

  Widget _buildStudentDashboard({
    required String studentUid,
    required String studentName,
    required String studentId,
    required Map<String, dynamic> studentData,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ========================================================
        // WELCOME CARD
        // ========================================================

        _buildWelcomeCard(
          studentName: studentName,
          studentId: studentId,
        ),

        const SizedBox(height: 18),

        // ========================================================
        // SPARKAI CARD
        // ========================================================

        _buildSparkAICard(
          studentUid: studentUid,
          studentId: studentId,
          studentName: studentName,
          studentData: studentData,
        ),

        const SizedBox(height: 18),

        // ========================================================
        // ATTENDANCE
        // ========================================================

        Card(
          elevation: 4,
          child: ListTile(
            leading: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            title: const Text(
              'Attendance',
            ),
            subtitle: const Text(
              'View your attendance',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AttendanceScreen(),
                ),
              );
            },
          ),
        ),

        // ========================================================
        // SUBJECTS
        // ========================================================

        Card(
          elevation: 4,
          child: ListTile(
            leading: const Icon(
              Icons.menu_book,
              color: Colors.orange,
            ),
            title: const Text(
              'My Subjects',
            ),
            subtitle: const Text(
              'View all subjects',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SubjectsScreen(),
                ),
              );
            },
          ),
        ),

        // ========================================================
        // ASSIGNMENTS
        // ========================================================

        Card(
          elevation: 4,
          child: ListTile(
            leading: const Icon(
              Icons.assignment,
              color: Colors.indigo,
            ),
            title: const Text(
              'Assignments',
            ),
            subtitle: const Text(
              'View and submit assignments',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AssignmentScreen(),
                ),
              );
            },
          ),
        ),

        // ========================================================
        // EVENT REQUEST
        // ========================================================

        Card(
          elevation: 4,
          child: ListTile(
            leading: const Icon(
              Icons.event,
              color: Colors.purple,
            ),
            title: const Text(
              'Request Event',
            ),
            subtitle: const Text(
              'Submit for Mentor Approval',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EventRequestScreen(),
                ),
              );
            },
          ),
        ),

        // ========================================================
        // COMMUNICATION
        // ========================================================

        Card(
          elevation: 4,
          child: ListTile(
            leading: const Icon(
              Icons.forum,
              color: Colors.red,
            ),
            title: const Text(
              'Communication',
            ),
            subtitle: const Text(
              'Direct Chat • Group Chat • Anonymous Doubts',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CommunicationHome(),
                ),
              );
            },
          ),
        ),

        // ========================================================
        // ANNOUNCEMENTS
        // ========================================================

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .snapshots(),
          builder: (context, snapshot) {
            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------

            if (snapshot.hasError) {
              return const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Error loading announcements',
                  ),
                ),
              );
            }

            // ----------------------------------------------------
            // LOADING
            // ----------------------------------------------------

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  title: Text(
                    'Loading announcements...',
                  ),
                ),
              );
            }

            // ----------------------------------------------------
            // ANNOUNCEMENTS
            // ----------------------------------------------------

            final announcements =
                snapshot.data?.docs ?? [];

            // ----------------------------------------------------
            // NO ANNOUNCEMENTS
            // ----------------------------------------------------

            if (announcements.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'No announcements',
                  ),
                  subtitle: Text(
                    'Nothing to display',
                  ),
                ),
              );
            }

            // ----------------------------------------------------
            // FIRST ANNOUNCEMENT
            // ----------------------------------------------------

            final announcement =
                announcements.first.data()
                    as Map<String, dynamic>;

            return Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Colors.blue,
                ),
                title: Text(
                  announcement['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  announcement['message']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard({
    required String studentName,
    required String studentId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff2196F3),
            Color(0xff1976D2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome 👋',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Roll No: $studentId',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Let's make today productive! 🚀",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SPARKAI CARD
  // ============================================================

  Widget _buildSparkAICard({
    required String studentUid,
    required String studentId,
    required String studentName,
    required Map<String, dynamic> studentData,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where(
            'studentId',
            isEqualTo: studentId,
          )
          .snapshots(),
      builder: (
        context,
        attendanceSnapshot,
      ) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .snapshots(),
          builder: (
            context,
            assignmentSnapshot,
          ) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .snapshots(),
              builder: (
                context,
                eventSnapshot,
              ) {
                return _buildSparkAIContent(
                  studentUid: studentUid,
                  studentId: studentId,
                  studentName: studentName,
                  studentData: studentData,
                  attendanceSnapshot:
                      attendanceSnapshot,
                  assignmentSnapshot:
                      assignmentSnapshot,
                  eventSnapshot:
                      eventSnapshot,
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SPARKAI CONTENT
  // ============================================================

  Widget _buildSparkAIContent({
    required String studentUid,
    required String studentId,
    required String studentName,
    required Map<String, dynamic> studentData,
    required AsyncSnapshot<QuerySnapshot>
        attendanceSnapshot,
    required AsyncSnapshot<QuerySnapshot>
        assignmentSnapshot,
    required AsyncSnapshot<QuerySnapshot>
        eventSnapshot,
  }) {
    // ==========================================================
    // ATTENDANCE
    // ==========================================================

    int presentCount = 0;
    int totalAttendance = 0;

    if (attendanceSnapshot.hasData) {
      for (final doc
          in attendanceSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final status = data['status']
            ?.toString()
            .toLowerCase()
            .trim();

        totalAttendance++;

        if (status == 'present') {
          presentCount++;
        }
      }
    }

    String attendanceText = 'Loading...';

    double attendancePercentage = 0;

    if (attendanceSnapshot.connectionState ==
        ConnectionState.waiting) {
      attendanceText = 'Loading...';
    } else if (totalAttendance == 0) {
      attendanceText = 'No data';
    } else {
      attendancePercentage =
          (presentCount / totalAttendance) * 100;

      attendanceText =
          '${attendancePercentage.toStringAsFixed(1)}%';
    }

    // ==========================================================
    // ASSIGNMENTS
    // ==========================================================

    int pendingAssignments = 0;

    DateTime? nearestAssignmentDate;

    if (assignmentSnapshot.hasData) {
      for (final doc
          in assignmentSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final dueDate = data['dueDate'];

        if (dueDate is Timestamp) {
          final date = dueDate.toDate();

          if (date.isAfter(DateTime.now())) {
            pendingAssignments++;

            if (nearestAssignmentDate == null ||
                date.isBefore(
                  nearestAssignmentDate,
                )) {
              nearestAssignmentDate = date;
            }
          }
        }
      }
    }

    // ==========================================================
    // EVENTS
    // ==========================================================

    int upcomingEvents = 0;

    if (eventSnapshot.hasData) {
      for (final doc
          in eventSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final eventDate =
            data['date'] ??
            data['eventDate'] ??
            data['startDate'];

        if (eventDate is Timestamp) {
          if (eventDate
              .toDate()
              .isAfter(DateTime.now())) {
            upcomingEvents++;
          }
        }
      }
    }

    // ==========================================================
    // SMART PRIORITY
    // ==========================================================

    String priorityTitle;
    String priorityMessage;
    IconData priorityIcon;
    Color priorityColor;

    if (attendancePercentage > 0 &&
        attendancePercentage < 75) {
      priorityTitle =
          'Attendance needs attention';

      priorityMessage =
          'Your attendance is $attendanceText. '
          'Try to attend upcoming classes regularly.';

      priorityIcon =
          Icons.warning_amber_rounded;

      priorityColor = Colors.red;
    } else if (nearestAssignmentDate != null) {
      final difference =
          nearestAssignmentDate
              .difference(DateTime.now())
              .inDays;

      priorityTitle =
          'Focus on your assignments';

      if (difference <= 0) {
        priorityMessage =
            'You have an assignment due soon. '
            'Complete it as early as possible.';
      } else if (difference == 1) {
        priorityMessage =
            'You have an assignment due tomorrow. '
            'Consider completing it today.';
      } else {
        priorityMessage =
            'You have $pendingAssignments pending '
            'assignment(s). Keep track of their due dates.';
      }

      priorityIcon =
          Icons.assignment_rounded;

      priorityColor = Colors.orange;
    } else if (upcomingEvents > 0) {
      priorityTitle =
          'Keep track of upcoming events';

      priorityMessage =
          'You have $upcomingEvents upcoming event(s). '
          'Keep your academic schedule organized.';

      priorityIcon =
          Icons.event_available_rounded;

      priorityColor = Colors.blue;
    } else {
      priorityTitle =
          'Keep learning consistently';

      priorityMessage =
          'You are currently up to date. '
          'Keep learning and stay consistent!';

      priorityIcon =
          Icons.auto_awesome_rounded;

      priorityColor = Colors.green;
    }

    // ==========================================================
    // CARD
    // ==========================================================

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4FD3)
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF6B4FD3),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SparkAI',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your personal learning assistant',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 7,
                        color: Colors.green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ====================================================
            // GREETING
            // ====================================================

            Text(
              'Hello, $studentName 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Here is a quick look at your academic priorities.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.5,
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // MINI STATS
            // ====================================================

            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.check_circle_outline,
                    title: 'Attendance',
                    value: attendanceText,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.assignment_outlined,
                    title: 'Assignments',
                    value:
                        pendingAssignments.toString(),
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.event_outlined,
                    title: 'Events',
                    value:
                        upcomingEvents.toString(),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ====================================================
            // PRIORITY
            // ====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: priorityColor
                    .withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: priorityColor
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    priorityIcon,
                    color: priorityColor,
                    size: 23,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          priorityTitle,
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          priorityMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 17),

            // ====================================================
            // ASK SPARKAI
            // ====================================================

            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton.icon(
                onPressed: _openSparkAI,
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                ),
                label: const Text(
                  'Ask SparkAI',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6B4FD3),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MINI STAT
  // ============================================================

  Widget _buildMiniStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}