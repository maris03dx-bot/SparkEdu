import 'package:flutter/material.dart';

import '../services/study_planner_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() =>
      _StudyPlannerScreenState();
}

class _StudyPlannerScreenState
    extends State<StudyPlannerScreen> {

  final subjectController =
      TextEditingController();

  final examController =
      TextEditingController();

  final hoursController =
      TextEditingController();

  bool loading = false;

  String studyPlan = "";

  Future<void> generatePlan() async {

    if (subjectController.text.isEmpty ||
        examController.text.isEmpty ||
        hoursController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields.",
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    final result =
        await StudyPlannerService.generatePlan(
      subject: subjectController.text,
      examDate: examController.text,
      hours: hoursController.text,
    );

    setState(() {
      studyPlan = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("📅 AI Study Planner"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Subject",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                hintText: "Example: Data Structures",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Exam Date",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: examController,
              decoration: InputDecoration(
                hintText: "Example: 20 August",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Study Hours Per Day",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: hoursController,
              keyboardType:
                  TextInputType.number,
              decoration: InputDecoration(
                hintText: "Example: 3",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: loading ? null : generatePlan,
                icon: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  loading
                      ? "Generating..."
                      : "Generate Study Plan",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (studyPlan.isNotEmpty) ...[

              const Text(
                "📚 Your AI Study Plan",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.teal.shade50,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: Colors.teal,
    ),
  ),
  child: MarkdownBody(
    data: studyPlan,
    selectable: true,
    styleSheet: MarkdownStyleSheet(
      h1: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
      h2: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      p: const TextStyle(
        fontSize: 16,
        height: 1.6,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      listBullet: const TextStyle(
        fontSize: 16,
      ),
    ),
  ),
),
            ],

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}