import 'package:flutter/material.dart';

import '../../services/spark_ai_service.dart';

class AIAnswerEvaluatorScreen extends StatefulWidget {
  const AIAnswerEvaluatorScreen({
    super.key,
  });

  @override
  State<AIAnswerEvaluatorScreen> createState() =>
      _AIAnswerEvaluatorScreenState();
}

class _AIAnswerEvaluatorScreenState
    extends State<AIAnswerEvaluatorScreen> {
  final TextEditingController subjectController =
      TextEditingController();

  final TextEditingController questionController =
      TextEditingController();

  final TextEditingController marksController =
      TextEditingController();

  final TextEditingController expectedAnswerController =
      TextEditingController();

  final TextEditingController studentAnswerController =
      TextEditingController();

  bool isEvaluating = false;
  String evaluationResult = '';

  @override
  void dispose() {
    subjectController.dispose();
    questionController.dispose();
    marksController.dispose();
    expectedAnswerController.dispose();
    studentAnswerController.dispose();
    super.dispose();
  }

  Future<void> evaluateAnswer() async {
    FocusScope.of(context).unfocus();

    final subject = subjectController.text.trim();
    final question = questionController.text.trim();
    final marks = marksController.text.trim();
    final expectedAnswer =
        expectedAnswerController.text.trim();
    final studentAnswer =
        studentAnswerController.text.trim();

    if (subject.isEmpty ||
        question.isEmpty ||
        marks.isEmpty ||
        expectedAnswer.isEmpty ||
        studentAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields before evaluating.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isEvaluating = true;
      evaluationResult = '';
    });

    try {
      final prompt = '''
You are an AI answer evaluator for a college teacher.

Evaluate the student's answer carefully and fairly.

Subject:
$subject

Question:
$question

Maximum Marks:
$marks

Expected / Correct Answer:
$expectedAnswer

Student's Answer:
$studentAnswer

Evaluate the student's answer based on:
1. Correctness
2. Relevance
3. Important points included
4. Missing points
5. Conceptual understanding

Give the result in this exact plain-text structure:

MARKS:
Give the marks awarded out of $marks.

EVALUATION:
Give a short overall evaluation.

CORRECT POINTS:
List the important points the student answered correctly.

MISSING OR INCORRECT POINTS:
List important missing, incorrect, or unclear points.

TEACHER FEEDBACK:
Give practical feedback that a teacher can give to the student.

IMPROVED ANSWER:
Give a concise improved answer that contains the important points.

Do not use Markdown.
Do not use # symbols.
Do not use * symbols.
Do not use Markdown tables.
Use simple plain text and bullet points with •.
Be fair. Do not award marks only because the answer is long.
''';

      final result = await SparkAIService.askAI(
        prompt: prompt,
      );

      if (!mounted) return;

      setState(() {
        evaluationResult = result.trim();
        isEvaluating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isEvaluating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evaluation failed: $e',
          ),
        ),
      );
    }
  }

  void clearAll() {
    subjectController.clear();
    questionController.clear();
    marksController.clear();
    expectedAnswerController.clear();
    studentAnswerController.clear();

    setState(() {
      evaluationResult = '';
    });
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
            borderSide: const BorderSide(
              color: Color(0xFF7C3AED),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text(
          'AI Answer Evaluator',
        ),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF9333EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fact_check_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Evaluate Student Answers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 7,
                  ),
                  Text(
                    'Get marks, evaluation and meaningful feedback with SparkAI.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Question Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            buildInputField(
              controller: subjectController,
              label: 'Subject',
              hint: 'Example: Data Structures',
              icon: Icons.book_outlined,
            ),

            buildInputField(
              controller: questionController,
              label: 'Question',
              hint: 'Enter the question',
              icon: Icons.help_outline_rounded,
              maxLines: 4,
            ),

            buildInputField(
              controller: marksController,
              label: 'Maximum Marks',
              hint: 'Example: 10',
              icon: Icons.grade_outlined,
              keyboardType: TextInputType.number,
            ),

            buildInputField(
              controller: expectedAnswerController,
              label: 'Expected / Correct Answer',
              hint: 'Enter the important points or model answer',
              icon: Icons.check_circle_outline,
              maxLines: 6,
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Student Answer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            buildInputField(
              controller: studentAnswerController,
              label: 'Student Answer',
              hint: 'Paste or enter the student answer',
              icon: Icons.person_outline,
              maxLines: 10,
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // BUTTONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        isEvaluating ? null : clearAll,
                    icon: const Icon(
                      Icons.clear_rounded,
                    ),
                    label: const Text(
                      'Clear',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        isEvaluating
                            ? null
                            : evaluateAnswer,
                    icon: isEvaluating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome,
                          ),
                    label: Text(
                      isEvaluating
                          ? 'Evaluating...'
                          : 'Evaluate with SparkAI',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF7C3AED),
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // RESULT
            // ==================================================

            if (evaluationResult.isNotEmpty) ...[
              const SizedBox(
                height: 28,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    'SparkAI Evaluation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: SelectableText(
                  evaluationResult,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}