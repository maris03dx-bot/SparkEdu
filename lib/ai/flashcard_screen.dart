import 'package:flutter/material.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 AI Flashcards"),
      ),
      body: const Center(
        child: Text(
          "Flashcard Screen",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}