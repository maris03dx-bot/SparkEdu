import 'package:flutter/material.dart';

class DeanTeacherDetailScreen extends StatelessWidget {
  final Map<String, dynamic> teacherData;

  const DeanTeacherDetailScreen({
    super.key,
    required this.teacherData,
  });

  Widget detailTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(
            icon,
            color: Colors.orange,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.orange,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              teacherData["name"] ?? "No Name",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            detailTile(
              Icons.email,
              "Email",
              teacherData["email"] ?? "N/A",
            ),

            detailTile(
              Icons.school,
              "Department",
              teacherData["department"] ?? "N/A",
            ),

            detailTile(
              Icons.menu_book,
              "Subject",
              teacherData["subject"] ?? "Not Assigned",
            ),

            detailTile(
              Icons.badge,
              "Role",
              teacherData["role"] ?? "Teacher",
            ),
          ],
        ),
      ),
    );
  }
}