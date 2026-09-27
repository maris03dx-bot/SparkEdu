import 'package:flutter/material.dart';

import 'associate_dean_students_screen.dart';
import 'associate_dean_teachers_screen.dart';
import 'associate_dean_mentors_screen.dart';
import 'associate_dean_announcements_screen.dart';
import 'associate_dean_reports_screen.dart';
import 'associate_dean_statistics_screen.dart';
import 'associate_dean_event_requests_screen.dart';
import 'associate_dean_classes_screen.dart';

import '../../utils/logout_helper.dart';

class AssociateDeanDashboard extends StatelessWidget {
  const AssociateDeanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Associate Dean Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              LogoutHelper.showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1,
          children: [
            // Statistics
            dashboardCard(
              context,
              "Statistics",
              Icons.dashboard,
              Colors.blue,
              const AssociateDeanStatisticsScreen(),
            ),

            // Students
            dashboardCard(
              context,
              "Students",
              Icons.school,
              Colors.green,
              const AssociateDeanStudentsScreen(),
            ),

            // Teachers
            dashboardCard(
              context,
              "Teachers",
              Icons.person,
              Colors.orange,
              const AssociateDeanTeachersScreen(),
            ),

            // Mentors
            dashboardCard(
              context,
              "Mentors",
              Icons.groups,
              Colors.purple,
              const AssociateDeanMentorsScreen(),
            ),

            // Manage Classes
            dashboardCard(
              context,
              "Manage Classes",
              Icons.class_,
              Colors.indigo,
              const AssociateDeanClassesScreen(),
            ),

            // Event Requests
            dashboardCard(
              context,
              "Event Requests",
              Icons.event,
              Colors.deepOrange,
              const AssociateDeanEventRequestsScreen(),
            ),

            // Announcements
            dashboardCard(
              context,
              "Announcements",
              Icons.campaign,
              Colors.red,
              const AssociateDeanAnnouncementsScreen(),
            ),

            // Reports
            dashboardCard(
              context,
              "Reports",
              Icons.bar_chart,
              Colors.teal,
              const AssociateDeanReportsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
                size: 35,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}