import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class StudyAssistantScreen extends StatefulWidget {
  const StudyAssistantScreen({super.key});

  @override
  State<StudyAssistantScreen> createState() =>
      _StudyAssistantScreenState();
}

class _StudyAssistantScreenState
    extends State<StudyAssistantScreen> {
  final Gemini gemini = Gemini.instance;

  final TextEditingController notesController =
      TextEditingController();

  String result = "";

  bool loading = false;

  Future<void> askAI(String type) async {
    if (notesController.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      result = "";
    });

    String prompt = "";

    if (type == "summary") {
      prompt =
          "Summarize these study notes into easy bullet points:\n\n${notesController.text}";
    }

    if (type == "mcq") {
      prompt =
          "Generate 10 multiple choice questions with answers from these notes:\n\n${notesController.text}";
    }

    if (type == "explain") {
      prompt =
          "Explain these study notes in simple language for a beginner:\n\n${notesController.text}";
    }

    if (type == "important") {
      prompt =
          "Extract the most important exam points from these notes:\n\n${notesController.text}";
    }

    try {
      final response = await gemini.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      if (response != null &&
          response.output != null) {
        result = response.output!;
      } else {
        result = "No response from AI.";
      }
    } catch (e) {
      result = e.toString();
    }

    setState(() {
      loading = false;
    });
  }

  Widget actionButton(
    String title,
    IconData icon,
    String type,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        onPressed: () => askAI(type),
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 SparkAI Study Assistant"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: notesController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: "Paste your notes here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            actionButton(
              "Summarize Notes",
              Icons.summarize,
              "summary",
              Colors.blue,
            ),

            const SizedBox(height: 10),

            actionButton(
              "Generate MCQs",
              Icons.quiz,
              "mcq",
              Colors.green,
            ),

            const SizedBox(height: 10),

            actionButton(
              "Explain Simply",
              Icons.lightbulb,
              "explain",
              Colors.orange,
            ),

            const SizedBox(height: 10),

            actionButton(
              "Important Points",
              Icons.star,
              "important",
              Colors.red,
            ),

            const SizedBox(height: 25),

            if (loading)
              const CircularProgressIndicator(),

            if (!loading && result.isNotEmpty)
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    result,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}