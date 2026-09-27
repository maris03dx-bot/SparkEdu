import 'package:flutter/material.dart';

class QuizPlayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const QuizPlayScreen({
    super.key,
    required this.questions,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int currentQuestion = 0;
  int score = 0;
  bool answered = false;
  int? selectedOption;

  void checkAnswer(int index) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedOption = index;

      if (index ==
          widget.questions[currentQuestion]["correct"]) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestion < widget.questions.length - 1) {
      setState(() {
        currentQuestion++;
        answered = false;
        selectedOption = null;
      });
    } else {
      showResult();
    }
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Quiz Completed"),
        content: Text(
          "Your Score\n\n$score / ${widget.questions.length}",
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Question ${currentQuestion + 1}/${widget.questions.length}",
        ),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              question["question"],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            ...List.generate(
              question["options"].length,
              (index) {
                Color color = Colors.white;

                if (answered) {
                  if (index ==
                      question["correct"]) {
                    color = Colors.green.shade200;
                  } else if (index ==
                      selectedOption) {
                    color = Colors.red.shade200;
                  }
                }

                return Card(
                  color: color,
                  child: ListTile(
                    title:
                        Text(question["options"][index]),
                    onTap: () => checkAnswer(index),
                  ),
                );
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    answered ? nextQuestion : null,
                child: Text(
                  currentQuestion ==
                          widget.questions.length - 1
                      ? "Finish"
                      : "Next",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}