import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssociateDeanReportsScreen extends StatelessWidget {
  const AssociateDeanReportsScreen({super.key});

  Future<int> getCount(String collection) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).get();

    return snapshot.docs.length;
  }

  Widget reportCard(
    String title,
    IconData icon,
    Color color,
    Future<int> future,
  ) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        return Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: snapshot.connectionState ==
                    ConnectionState.waiting
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  )
                : Text(
                    "${snapshot.data ?? 0} Records",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("College Reports"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          reportCard(
            "Students",
            Icons.school,
            Colors.green,
            getCount("student"),
          ),

          reportCard(
            "Teachers",
            Icons.person,
            Colors.orange,
            getCount("teachers"),
          ),

          reportCard(
            "Subjects",
            Icons.menu_book,
            Colors.blue,
            getCount("subjects"),
          ),

          reportCard(
            "Assignments",
            Icons.assignment,
            Colors.indigo,
            getCount("assignments"),
          ),

          reportCard(
            "Assignment Submissions",
            Icons.upload_file,
            Colors.deepPurple,
            getCount("assignment_submissions"),
          ),

          reportCard(
            "Study Materials",
            Icons.folder,
            Colors.teal,
            getCount("study_materials"),
          ),

          reportCard(
            "Attendance",
            Icons.fact_check,
            Colors.blueGrey,
            getCount("attendance"),
          ),

          reportCard(
            "Attendance Sessions",
            Icons.qr_code,
            Colors.purple,
            getCount("attendance_sessions"),
          ),

          reportCard(
            "Leave Requests",
            Icons.event_available,
            Colors.red,
            getCount("leave_requests"),
          ),

          reportCard(
            "Announcements",
            Icons.campaign,
            Colors.deepOrange,
            getCount("announcements"),
          ),

          reportCard(
            "Events",
            Icons.event,
            Colors.pink,
            getCount("events"),
          ),

          reportCard(
            "Notifications",
            Icons.notifications,
            Colors.amber,
            getCount("notifications"),
          ),
        ],
      ),
    );
  }
}