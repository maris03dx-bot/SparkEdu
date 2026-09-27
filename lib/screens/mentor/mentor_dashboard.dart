import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'mentor_students_screen.dart';
import 'mentor_chat_screen.dart';
import 'mentor_leave_screen.dart';
import 'mentor_reports_screen.dart';
import 'mentor_profile_screen.dart';
import 'mentor_event_requests_screen.dart';
import 'mentor_subjects_screen.dart';
import 'mentor_spark_ai_alerts_screen.dart';
import 'mentor_teachers_screen.dart';

import '../../utils/logout_helper.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  late final Stream<String> _mentorNameStream;

  @override
  void initState() {
    super.initState();
    _mentorNameStream = _createMentorNameStream();
  }

  Stream<String> _createMentorNameStream() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Stream<String>.value('Mentor');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .where(
          'uid',
          isEqualTo: currentUser.uid,
        )
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 'Mentor';
      }

      final data = snapshot.docs.first.data();
      final dynamic nameValue = data['name'];

      if (nameValue == null) {
        return 'Mentor';
      }

      final String name = nameValue.toString().trim();

      if (name.isEmpty) {
        return 'Mentor';
      }

      return name;
    });
  }

  void _openPage(Widget Function() pageBuilder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => pageBuilder(),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String title,
    required Color color,
    required Widget Function() pageBuilder,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          size: 28,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          _openPage(pageBuilder);
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return StreamBuilder<String>(
      stream: _mentorNameStream,
      builder: (context, snapshot) {
        final String mentorName = snapshot.data ?? 'Mentor';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome 👨‍🏫',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mentorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mentor Dashboard',
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'Logout',
            onPressed: () {
              LogoutHelper.showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildWelcomeCard(),

            const SizedBox(height: 30),

            _buildButton(
              icon: Icons.people,
              title: 'My Students',
              color: Colors.blue,
              pageBuilder: () => const MentorStudentsScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.menu_book,
              title: 'Manage Subjects',
              color: Colors.indigo,
              pageBuilder: () => const MentorSubjectsScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.person_add_alt_1,
              title: 'Subject Teacher Management',
              color: Colors.deepPurple,
              pageBuilder: () => const MentorTeachersScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.chat,
              title: 'Chat with Students',
              color: Colors.teal,
              pageBuilder: () => const MentorChatScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.notifications_active,
              title: 'SparkAI Doubt Alerts',
              color: Colors.redAccent,
              pageBuilder: () => const MentorSparkAIDoubtAlertsScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.event,
              title: 'Event Requests',
              color: Colors.orange,
              pageBuilder: () => const MentorEventRequestsScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.assignment,
              title: 'Leave Requests',
              color: Colors.green,
              pageBuilder: () => const MentorLeaveScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.bar_chart,
              title: 'Reports',
              color: Colors.purple,
              pageBuilder: () => const MentorReportsScreen(),
            ),

            const SizedBox(height: 15),

            _buildButton(
              icon: Icons.person,
              title: 'My Profile',
              color: Colors.teal,
              pageBuilder: () => const MentorProfileScreen(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}