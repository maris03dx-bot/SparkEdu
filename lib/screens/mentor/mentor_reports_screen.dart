import 'package:flutter/material.dart';

class MentorReportsScreen extends StatelessWidget {
  const MentorReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: const Center(
        child: Text(
          "Reports will appear here.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}