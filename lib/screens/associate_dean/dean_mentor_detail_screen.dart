import 'package:flutter/material.dart';

class DeanMentorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> mentorData;

  const DeanMentorDetailScreen({
    super.key,
    required this.mentorData,
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
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            icon,
            color: Colors.purple,
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
        title: const Text("Mentor Profile"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.purple,
              child: Icon(
                Icons.groups,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              mentorData["name"] ?? "No Name",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            detailTile(
              Icons.email,
              "Email",
              mentorData["email"] ?? "N/A",
            ),

            detailTile(
              Icons.school,
              "Department",
              mentorData["department"] ?? "N/A",
            ),

            detailTile(
              Icons.people,
              "Role",
              mentorData["role"] ?? "Mentor",
            ),
          ],
        ),
      ),
    );
  }
}
