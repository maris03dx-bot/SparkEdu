import 'package:flutter/material.dart';

class DeanStudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const DeanStudentDetailScreen({
    super.key,
    required this.studentData,
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
          backgroundColor: Colors.indigo.shade100,
          child: Icon(
            icon,
            color: Colors.indigo,
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
        title: const Text("Student Profile"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.indigo,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              studentData["name"] ?? "No Name",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            detailTile(
              Icons.email,
              "Email",
              studentData["email"] ?? "N/A",
            ),

            detailTile(
              Icons.school,
              "Department",
              studentData["department"] ?? "N/A",
            ),

            detailTile(
              Icons.calendar_today,
              "Year",
              studentData["year"] ?? "N/A",
            ),

            detailTile(
              Icons.badge,
              "Register Number",
              studentData["registerNo"] ?? "N/A",
            ),

            detailTile(
              Icons.confirmation_number,
              "Roll Number",
              studentData["rollNo"] ?? "N/A",
            ),

            detailTile(
              Icons.person_outline,
              "Role",
              studentData["role"] ?? "Student",
            ),
          ],
        ),
      ),
    );
  }
}