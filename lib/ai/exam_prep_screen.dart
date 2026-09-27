import 'package:flutter/material.dart';

class ExamPrepScreen extends StatelessWidget {
  const ExamPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Preparation"),
      ),
      body: const Center(
        child: Text(
          "Exam Preparation Screen",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}