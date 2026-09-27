import 'package:flutter/material.dart';

class MentorEventsScreen extends StatelessWidget {
  const MentorEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Requests"),
      ),
      body: const Center(
        child: Text(
          "Event Requests will appear here.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}