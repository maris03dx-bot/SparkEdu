import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
      ),
      body: const Center(
        child: Text(
          "Teacher Announcements 📢",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}