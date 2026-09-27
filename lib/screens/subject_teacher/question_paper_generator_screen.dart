import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/spark_ai_service.dart';

class QuestionPaperGeneratorScreen extends StatefulWidget {
  const QuestionPaperGeneratorScreen({
    super.key,
  });

  @override
  State<QuestionPaperGeneratorScreen> createState() =>
      _QuestionPaperGeneratorScreenState();
}

// ============================================================
// QUESTION TYPE
// ============================================================

enum QuestionType {
  mcq,
  shortAnswer,
  longAnswer,
  essay,
}

// ============================================================
// SUB QUESTION MODEL
// ============================================================

class SubQuestionConfig {
  String label;
  int marks;

  SubQuestionConfig({
    required this.label,
    required this.marks,
  });
}

// ============================================================
// QUESTION CONFIG
// ============================================================

class QuestionConfig {
  int number;
  int marks;
  bool hasChoice;
  QuestionType type;
  List<SubQuestionConfig> subQuestions;

  QuestionConfig({
    required this.number,
    required this.marks,
    this.hasChoice = false,
    this.type = QuestionType.longAnswer,
    List<SubQuestionConfig>? subQuestions,
  }) : subQuestions = subQuestions ?? [];
}

// ============================================================
// SECTION CONFIG
// ============================================================

class SectionConfig {
  String name;
  List<QuestionConfig> questions;

  SectionConfig({
    required this.name,
    List<QuestionConfig>? questions,
  }) : questions = questions ?? [];
}

// ============================================================
// SCREEN
// ============================================================

class _QuestionPaperGeneratorScreenState
    extends State<QuestionPaperGeneratorScreen> {
  final TextEditingController subjectController =
      TextEditingController();

  final TextEditingController topicController =
      TextEditingController();

  final TextEditingController durationController =
      TextEditingController(
    text: '3 Hours',
  );

  final TextEditingController instructionsController =
      TextEditingController();

  String selectedYear = 'I Year';

  String selectedDifficulty = 'Mixed';

  bool isGenerating = false;

  String generatedPaper = '';

  final List<SectionConfig> sections = [];

  @override
  void initState() {
    super.initState();

    sections.add(
      SectionConfig(
        name: 'Section A',
        questions: [
          QuestionConfig(
            number: 1,
            marks: 2,
            type: QuestionType.shortAnswer,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    subjectController.dispose();
    topicController.dispose();
    durationController.dispose();
    instructionsController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  User? get currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  // ==========================================================
  // QUESTION TYPE TEXT
  // ==========================================================

  String questionTypeText(
    QuestionType type,
  ) {
    switch (type) {
      case QuestionType.mcq:
        return 'MCQ';

      case QuestionType.shortAnswer:
        return 'Short Answer';

      case QuestionType.longAnswer:
        return 'Long Answer';

      case QuestionType.essay:
        return 'Essay';
    }
  }

  // ==========================================================
  // SECTION TOTAL
  // ==========================================================

  int sectionTotal(
    SectionConfig section,
  ) {
    int total = 0;

    for (final question in section.questions) {
      total += question.marks;
    }

    return total;
  }

  // ==========================================================
  // TOTAL MARKS
  // ==========================================================

  int get totalMarks {
    int total = 0;

    for (final section in sections) {
      total += sectionTotal(section);
    }

    return total;
  }

  // ==========================================================
  // ADD SECTION
  // ==========================================================

  void addSection() {
    setState(() {
      sections.add(
        SectionConfig(
          name: 'Section ${String.fromCharCode(65 + sections.length)}',
        ),
      );
    });
  }

  // ==========================================================
  // DELETE SECTION
  // ==========================================================

  void deleteSection(
    int sectionIndex,
  ) {
    if (sections.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least one section is required.',
          ),
        ),
      );

      return;
    }

    setState(() {
      sections.removeAt(sectionIndex);
      renumberQuestions();
    });
  }

  // ==========================================================
  // ADD QUESTION
  // ==========================================================

  void addQuestion(
    int sectionIndex,
  ) {
    final section = sections[sectionIndex];

    int nextNumber = 1;

    if (section.questions.isNotEmpty) {
      nextNumber =
          section.questions.last.number + 1;
    }

    setState(() {
      section.questions.add(
        QuestionConfig(
          number: nextNumber,
          marks: 2,
          type: QuestionType.shortAnswer,
        ),
      );

      renumberQuestions();
    });
  }

  // ==========================================================
  // DELETE QUESTION
  // ==========================================================

  void deleteQuestion(
    int sectionIndex,
    int questionIndex,
  ) {
    final section = sections[sectionIndex];

    if (section.questions.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Keep at least one question in this section.',
          ),
        ),
      );

      return;
    }

    setState(() {
      section.questions.removeAt(questionIndex);
      renumberQuestions();
    });
  }

  // ==========================================================
  // ADD SUB QUESTION
  // ==========================================================

  void addSubQuestion(
    int sectionIndex,
    int questionIndex,
  ) {
    final question =
        sections[sectionIndex].questions[questionIndex];

    final int subNumber =
        question.subQuestions.length + 1;

    setState(() {
      question.subQuestions.add(
        SubQuestionConfig(
          label: question.hasChoice
              ? '${question.number}(b)-${subNumber == 1 ? 'I' : 'II'}'
              : '${question.number}(a)-$subNumber',
          marks: subNumber == 1 ? 8 : 7,
        ),
      );
    });
  }

  // ==========================================================
  // DELETE SUB QUESTION
  // ==========================================================

  void deleteSubQuestion(
    int sectionIndex,
    int questionIndex,
    int subQuestionIndex,
  ) {
    final question =
        sections[sectionIndex].questions[questionIndex];

    setState(() {
      question.subQuestions.removeAt(
        subQuestionIndex,
      );
    });
  }

  // ==========================================================
  // RENUMBER QUESTIONS
  // ==========================================================

  void renumberQuestions() {
    int number = 1;

    for (final section in sections) {
      for (final question in section.questions) {
        question.number = number;

        for (
          int i = 0;
          i < question.subQuestions.length;
          i++
        ) {
          final sub = question.subQuestions[i];

          if (question.hasChoice) {
            if (i == 0) {
              sub.label =
                  '${question.number}(b)-I';
            } else if (i == 1) {
              sub.label =
                  '${question.number}(b)-II';
            } else {
              sub.label =
                  '${question.number}(b)-${i + 1}';
            }
          } else {
            sub.label =
                '${question.number}(a)-${i + 1}';
          }
        }

        number++;
      }
    }
  }

  // ==========================================================
  // GENERATE QUESTION PAPER
  // ==========================================================

  Future<void> generateQuestionPaper() async {
    FocusScope.of(context).unfocus();

    if (subjectController.text.trim().isEmpty) {
      showError(
        'Please enter the subject.',
      );

      return;
    }

    if (topicController.text.trim().isEmpty) {
      showError(
        'Please enter the topic or units.',
      );

      return;
    }

    if (sections.isEmpty) {
      showError(
        'Please add at least one section.',
      );

      return;
    }

    for (final section in sections) {
      if (section.questions.isEmpty) {
        showError(
          '${section.name} does not contain any questions.',
        );

        return;
      }

      for (final question in section.questions) {
        if (question.marks <= 0) {
          showError(
            'Every question must have valid marks.',
          );

          return;
        }

        if (question.subQuestions.isNotEmpty) {
          final int subTotal =
              question.subQuestions.fold(
            0,
            (sum, item) => sum + item.marks,
          );

          if (subTotal != question.marks) {
            showError(
              'Sub-question marks for Question ${question.number} must total ${question.marks} marks.',
            );

            return;
          }
        }
      }
    }

    renumberQuestions();

    final String structure =
        buildPaperStructure();

    final String prompt = """
Create a complete college-level question paper.

IMPORTANT:
The question paper must strictly follow the exact structure provided below.

Do not change:
• Number of questions
• Question numbering
• Marks
• Internal choice structure
• Sub-question structure
• Section structure

Do not add extra questions.

Do not remove questions.

Do not change the total marks.

Do not show or mention this instruction to the teacher.

SUBJECT:
${subjectController.text.trim()}

TOPIC / UNITS:
${topicController.text.trim()}

YEAR:
$selectedYear

DIFFICULTY:
$selectedDifficulty

EXAM DURATION:
${durationController.text.trim()}

TOTAL MARKS:
$totalMarks

QUESTION PAPER STRUCTURE:
$structure

ADDITIONAL INSTRUCTIONS:
${instructionsController.text.trim().isEmpty ? 'None' : instructionsController.text.trim()}

QUESTION GENERATION RULES:

1. Generate academically appropriate questions for the selected subject and topics.

2. Match every question to its specified marks.

3. A 2-mark question must be suitable for 2 marks.

4. A 5-mark question must require an appropriate level of explanation.

5. A 10-mark or 15-mark question must be sufficiently detailed and suitable for the specified marks.

6. Match the selected year and difficulty level.

7. Avoid duplicate or nearly duplicate questions.

8. Cover different concepts from the supplied topic or units.

9. For MCQs:
   • Provide four options.
   • Clearly identify options as A, B, C and D.
   • Do not provide the answer key unless specifically requested.

10. For internal choices:
   • Follow exactly the specified numbering.
   • Example:
     11(a) Question
     OR
     11(b) Question

11. For sub-questions:
   • Preserve the exact numbering.
   • Example:
     12(b)-I Question ........ (8 marks)
     12(b)-II Question ....... (7 marks)

12. Do not create Markdown headings.

13. Do not use # symbols.

14. Do not use ** bold formatting.

15. Use clean plain text.

16. Start directly with the question paper.

OUTPUT FORMAT:

QUESTION PAPER

Subject: ...
Year: ...
Duration: ...
Maximum Marks: ...

General Instructions

1. ...
2. ...

SECTION A

1. Question ................................ (2)
2. Question ................................ (2)

SECTION B

11. (a) Question ........................... (15)
    OR
    (b) Question ........................... (15)

12. (a) Question ........................... (15)
    OR
    (b) Question ........................... (15)

        12(b)-I Question .................. (8)
        12(b)-II Question ................. (7)

Follow the supplied structure exactly.
""";

    setState(() {
      isGenerating = true;
      generatedPaper = '';
    });

    try {
      final String answer =
          await SparkAIService.askAI(
        prompt: prompt,
      );

      if (!mounted) {
        return;
      }

      final String paper = answer.trim();

      setState(() {
        generatedPaper = paper;
        isGenerating = false;
      });

      // Save automatically after successful generation.
      await saveQuestionPaperToHistory(
        paper,
      );
    } on SparkAIException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isGenerating = false;
      });

      showError(
        e.message,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isGenerating = false;
      });

      showError(
        'Could not generate the question paper. Please try again.',
      );
    }
  }

  // ==========================================================
  // SAVE QUESTION PAPER HISTORY
  // ==========================================================

  Future<void> saveQuestionPaperToHistory(
    String paper,
  ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    if (paper.trim().isEmpty) {
      return;
    }

    try {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('question_paper_history');

      await collection.add({
        'subject': subjectController.text.trim(),
        'topic': topicController.text.trim(),
        'year': selectedYear,
        'difficulty': selectedDifficulty,
        'duration': durationController.text.trim(),
        'totalMarks': totalMarks,
        'paper': paper.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        showError(
          'Question paper generated, but history could not be saved.',
        );
      }
    }
  }

  // ==========================================================
  // BUILD PAPER STRUCTURE
  // ==========================================================

  String buildPaperStructure() {
    final StringBuffer buffer =
        StringBuffer();

    for (
      int sectionIndex = 0;
      sectionIndex < sections.length;
      sectionIndex++
    ) {
      final section =
          sections[sectionIndex];

      buffer.writeln(
        '${section.name}:',
      );

      for (
        int questionIndex = 0;
        questionIndex <
            section.questions.length;
        questionIndex++
      ) {
        final question =
            section.questions[questionIndex];

        buffer.writeln(
          'Question ${question.number}: ${question.marks} marks',
        );

        buffer.writeln(
          'Type: ${questionTypeText(question.type)}',
        );

        buffer.writeln(
          'Internal choice: ${question.hasChoice ? "Yes" : "No"}',
        );

        if (question.hasChoice) {
          buffer.writeln(
            'Choice format: ${question.number}(a) OR ${question.number}(b)',
          );
        }

        if (question.subQuestions.isNotEmpty) {
          buffer.writeln(
            'Sub-questions:',
          );

          for (
            final sub in question.subQuestions
          ) {
            buffer.writeln(
              '  ${sub.label}: ${sub.marks} marks',
            );
          }
        }

        buffer.writeln();
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void showError(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void clearAll() {
    setState(() {
      subjectController.clear();
      topicController.clear();
      durationController.text =
          '3 Hours';
      instructionsController.clear();

      selectedYear = 'I Year';
      selectedDifficulty = 'Mixed';

      generatedPaper = '';

      sections.clear();

      sections.add(
        SectionConfig(
          name: 'Section A',
          questions: [
            QuestionConfig(
              number: 1,
              marks: 2,
              type: QuestionType.shortAnswer,
            ),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // COPY PAPER
  // ==========================================================

  Future<void> copyPaper(
    String paper,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: paper,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Question paper copied to clipboard.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // QUESTION CARD
  // ==========================================================

  Widget buildQuestionCard({
    required int sectionIndex,
    required int questionIndex,
  }) {
    final section =
        sections[sectionIndex];

    final question =
        section.questions[questionIndex];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Colors.deepPurple.shade50,
                child: Text(
                  '${question.number}',
                  style: TextStyle(
                    color:
                        Colors.deepPurple.shade700,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Question ${question.number}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    'Delete question',
                onPressed: () {
                  deleteQuestion(
                    sectionIndex,
                    questionIndex,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          TextFormField(
            initialValue:
                question.marks.toString(),
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Marks for this question',
              prefixIcon:
                  Icon(Icons.grade_outlined),
              border:
                  OutlineInputBorder(),
            ),
            onChanged: (value) {
              final int? marks =
                  int.tryParse(value);

              if (marks != null &&
                  marks > 0) {
                question.marks = marks;
              }
            },
          ),

          const SizedBox(
            height: 12,
          ),

          DropdownButtonFormField<
              QuestionType>(
            initialValue:
                question.type,
            decoration:
                const InputDecoration(
              labelText:
                  'Question type',
              prefixIcon:
                  Icon(Icons.quiz_outlined),
              border:
                  OutlineInputBorder(),
            ),
            items: QuestionType.values
                .map(
                  (type) =>
                      DropdownMenuItem<
                          QuestionType>(
                    value: type,
                    child: Text(
                      questionTypeText(
                        type,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                question.type = value;
              });
            },
          ),

          const SizedBox(
            height: 4,
          ),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            title: const Text(
              'Internal Choice',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            subtitle: Text(
              question.hasChoice
                  ? '${question.number}(a) OR ${question.number}(b)'
                  : 'No internal choice',
            ),
            value:
                question.hasChoice,
            onChanged: (value) {
              setState(() {
                question.hasChoice =
                    value;

                if (!value) {
                  question.subQuestions
                      .clear();
                }
              });
            },
          ),

          if (question.subQuestions
              .isNotEmpty) ...[
            const Divider(
              height: 24,
            ),
            const Text(
              'Sub-Questions',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            ...List.generate(
              question.subQuestions.length,
              (subIndex) {
                final sub =
                    question.subQuestions[
                        subIndex];

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child:
                            TextFormField(
                          initialValue:
                              sub.label,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Label',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) {
                            sub.label =
                                value;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            TextFormField(
                          initialValue:
                              sub.marks
                                  .toString(),
                          keyboardType:
                              TextInputType
                                  .number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Marks',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) {
                            final int?
                                marks =
                                int.tryParse(
                              value,
                            );

                            if (marks !=
                                    null &&
                                marks >
                                    0) {
                              sub.marks =
                                  marks;
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          deleteSubQuestion(
                            sectionIndex,
                            questionIndex,
                            subIndex,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .remove_circle_outline,
                          color:
                              Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          if (question.hasChoice) ...[
            const SizedBox(
              height: 4,
            ),
            OutlinedButton.icon(
              onPressed: () {
                addSubQuestion(
                  sectionIndex,
                  questionIndex,
                );
              },
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Add Sub-Question',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION CARD
  // ==========================================================

  Widget buildSectionCard(
    int sectionIndex,
  ) {
    final section =
        sections[sectionIndex];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.view_agenda_outlined,
                  color: Colors.deepPurple,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        section.name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 17,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Section Name',
                      border:
                          OutlineInputBorder(),
                    ),
                    onChanged:
                        (value) {
                      section.name =
                          value.trim().isEmpty
                              ? 'Section'
                              : value;
                    },
                  ),
                ),
                IconButton(
                  tooltip:
                      'Delete section',
                  onPressed: () {
                    deleteSection(
                      sectionIndex,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color:
                    Colors.deepPurple.shade50,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                    size: 20,
                    color:
                        Colors.deepPurple,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Section Total: ${sectionTotal(section)} marks',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            ...List.generate(
              section.questions.length,
              (questionIndex) {
                return buildQuestionCard(
                  sectionIndex:
                      sectionIndex,
                  questionIndex:
                      questionIndex,
                );
              },
            ),

            OutlinedButton.icon(
              onPressed: () {
                addQuestion(
                  sectionIndex,
                );
              },
              icon: const Icon(
                Icons.add_circle_outline,
              ),
              label: const Text(
                'Add Question',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // GENERATED PAPER
  // ==========================================================

  Widget buildGeneratedPaper() {
    if (generatedPaper.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        top: 22,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color:
                      Colors.deepPurple,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Expanded(
                  child: Text(
                    'Generated Question Paper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  onPressed: () {
                    copyPaper(
                      generatedPaper,
                    );
                  },
                  icon: const Icon(
                    Icons.copy_outlined,
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            SelectableText(
              generatedPaper,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OPEN HISTORY
  // ==========================================================

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const QuestionPaperHistoryScreen(),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text(
          'Question Paper Generator',
        ),
        backgroundColor:
            Colors.deepPurple,
        foregroundColor:
            Colors.white,
        actions: [
          IconButton(
            tooltip: 'Question Paper Library',
            onPressed: isGenerating
                ? null
                : openHistory,
            icon: const Icon(
              Icons.library_books_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: isGenerating
                ? null
                : clearAll,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF6D28D9),
                      Color(0xFF9333EA),
                    ],
                    begin:
                        Alignment.topLeft,
                    end: Alignment
                        .bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.quiz_rounded,
                      color:
                          Colors.white,
                      size: 38,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'AI Question Paper Generator',
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Design your exact examination pattern and let SparkAI generate the questions.',
                      style: TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Exam Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    subjectController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Subject',
                  hintText:
                      'Example: Data Structures',
                  prefixIcon:
                      Icon(
                    Icons
                        .menu_book_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    topicController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Topic / Units',
                  hintText:
                      'Example: Unit 1, Unit 2, Linked Lists, Trees',
                  prefixIcon:
                      Icon(
                    Icons.topic_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          selectedYear,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Year',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        'I Year',
                        'II Year',
                        'III Year',
                        'IV Year',
                      ]
                          .map(
                            (
                              value,
                            ) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  value,
                              child:
                                  Text(
                                value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          selectedYear =
                              value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          selectedDifficulty,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Difficulty',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        'Easy',
                        'Medium',
                        'Hard',
                        'Mixed',
                      ]
                          .map(
                            (
                              value,
                            ) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  value,
                              child:
                                  Text(
                                value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          selectedDifficulty =
                              value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    durationController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Exam Duration',
                  hintText:
                      'Example: 3 Hours',
                  prefixIcon:
                      Icon(
                    Icons
                        .schedule_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Question Paper Structure',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .deepPurple
                          .shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      'Total: $totalMarks marks',
                      style:
                          const TextStyle(
                        color: Colors
                            .deepPurple,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Configure each section, question, mark and internal choice.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              ...List.generate(
                sections.length,
                (index) {
                  return buildSectionCard(
                    index,
                  );
                },
              ),

              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      addSection,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Add Section',
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              TextField(
                controller:
                    instructionsController,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Additional Instructions (Optional)',
                  hintText:
                      'Example: Follow Bloom\'s taxonomy and cover all units.',
                  prefixIcon:
                      Icon(
                    Icons
                        .notes_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                  alignLabelWithHint:
                      true,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isGenerating
                          ? null
                          : generateQuestionPaper,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .auto_awesome,
                        ),
                  label: Text(
                    isGenerating
                        ? 'SparkAI is generating...'
                        : 'Generate Question Paper',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.deepPurple,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),

              buildGeneratedPaper(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUESTION PAPER HISTORY SCREEN
// ============================================================

class QuestionPaperHistoryScreen
    extends StatefulWidget {
  const QuestionPaperHistoryScreen({
    super.key,
  });

  @override
  State<QuestionPaperHistoryScreen> createState() =>
      _QuestionPaperHistoryScreenState();
}

class _QuestionPaperHistoryScreenState
    extends State<QuestionPaperHistoryScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  User? get currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  CollectionReference<Map<String, dynamic>>?
      get historyCollection {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('question_paper_history');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DATE
  // ==========================================================

  DateTime? getDate(
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }

  // ==========================================================
  // DATE GROUP
  // ==========================================================

  String dateGroup(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Older';
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final paperDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(paperDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference >= 2 &&
        difference <= 7) {
      return 'Previous 7 Days';
    }

    return 'Older';
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Recently generated';
    }

    final hour =
        date.hour == 0 ? 12 : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  bool matchesSearch(
    Map<String, dynamic> data,
  ) {
    if (searchText.trim().isEmpty) {
      return true;
    }

    final query =
        searchText.trim().toLowerCase();

    final subject =
        '${data['subject'] ?? ''}'.toLowerCase();

    final topic =
        '${data['topic'] ?? ''}'.toLowerCase();

    final year =
        '${data['year'] ?? ''}'.toLowerCase();

    final difficulty =
        '${data['difficulty'] ?? ''}'.toLowerCase();

    return subject.contains(query) ||
        topic.contains(query) ||
        year.contains(query) ||
        difficulty.contains(query);
  }

  // ==========================================================
  // DELETE ONE
  // ==========================================================

  Future<void> deletePaper(
    String documentId,
  ) async {
    final collection =
        historyCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(documentId).delete();
  }

  // ==========================================================
  // DELETE ALL
  // ==========================================================

  Future<void> deleteAllPapers() async {
    final collection =
        historyCollection;

    if (collection == null) {
      return;
    }

    final snapshot =
        await collection.get();

    final batch =
        FirebaseFirestore.instance.batch();

    for (final document in snapshot.docs) {
      batch.delete(
        document.reference,
      );
    }

    await batch.commit();
  }

  // ==========================================================
  // CONFIRM DELETE ALL
  // ==========================================================

  Future<void> confirmDeleteAll() async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete All Question Papers?',
          ),
          content: const Text(
            'All saved question papers will be permanently deleted from your history.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete All',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await deleteAllPapers();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'All question papers deleted.',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete all question papers.',
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // OPEN PAPER
  // ==========================================================

  void openPaper(
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuestionPaperViewerScreen(
          paper: '${data['paper'] ?? ''}',
          subject:
              '${data['subject'] ?? 'Question Paper'}',
          year:
              '${data['year'] ?? ''}',
          difficulty:
              '${data['difficulty'] ?? ''}',
          duration:
              '${data['duration'] ?? ''}',
          totalMarks:
              '${data['totalMarks'] ?? ''}',
          createdAt:
              getDate(data),
        ),
      ),
    );
  }

  // ==========================================================
  // PAPER CARD
  // ==========================================================

  Widget buildPaperCard(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final subject =
        '${data['subject'] ?? 'Untitled Subject'}';

    final topic =
        '${data['topic'] ?? 'No topic specified'}';

    final year =
        '${data['year'] ?? ''}';

    final difficulty =
        '${data['difficulty'] ?? ''}';

    final duration =
        '${data['duration'] ?? ''}';

    final totalMarks =
        '${data['totalMarks'] ?? ''}';

    final date =
        getDate(data);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          openPaper(data);
        },
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .deepPurple
                          .shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .description_rounded,
                      color:
                          Colors.deepPurple,
                      size: 27,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          subject,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          topic,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value ==
                          'delete') {
                        await deletePaper(
                          document.id,
                        );
                      }
                    },
                    itemBuilder:
                        (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                              color:
                                  Colors.red,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Delete',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildInfoChip(
                    Icons.school_outlined,
                    year,
                  ),
                  buildInfoChip(
                    Icons.speed_outlined,
                    difficulty,
                  ),
                  buildInfoChip(
                    Icons.timer_outlined,
                    duration,
                  ),
                  buildInfoChip(
                    Icons.grade_outlined,
                    '$totalMarks Marks',
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color:
                        Colors.grey.shade600,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Text(
                      formatDate(date),
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Text(
                    'Open Paper',
                    style: TextStyle(
                      color:
                          Colors.deepPurple,
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 13,
                    color:
                        Colors.deepPurple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INFO CHIP
  // ==========================================================

  Widget buildInfoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.deepPurple,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GROUP TITLE
  // ==========================================================

  Widget buildGroupTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        top: 18,
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color:
                  Colors.deepPurple,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD GROUP
  // ==========================================================

  List<Widget> buildHistoryGroups(
    List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        documents,
  ) {
    const groups = [
      'Today',
      'Yesterday',
      'Previous 7 Days',
      'Older',
    ];

    final List<Widget> widgets = [];

    for (final group in groups) {
      final matching = documents
          .where(
            (document) =>
                matchesSearch(
                  document.data(),
                ) &&
                dateGroup(
                      getDate(
                        document.data(),
                      ),
                    ) ==
                    group,
          )
          .toList();

      if (matching.isEmpty) {
        continue;
      }

      widgets.add(
        buildGroupTitle(group),
      );

      for (final document in matching) {
        widgets.add(
          buildPaperCard(document),
        );
      }
    }

    return widgets;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final collection =
        historyCollection;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor:
            Colors.deepPurple,
        foregroundColor:
            Colors.white,
        title: const Text(
          'Question Paper Library',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Delete all',
            onPressed:
                confirmDeleteAll,
            icon: const Icon(
              Icons
                  .delete_sweep_outlined,
            ),
          ),
        ],
      ),
      body: collection == null
          ? const Center(
              child: Text(
                'Please log in again.',
              ),
            )
          : Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    18,
                  ),
                  decoration:
                      const BoxDecoration(
                    color:
                        Colors.deepPurple,
                    borderRadius:
                        BorderRadius.only(
                      bottomLeft:
                          Radius.circular(
                        28,
                      ),
                      bottomRight:
                          Radius.circular(
                        28,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons
                                .auto_stories_rounded,
                            color:
                                Colors.white,
                            size: 30,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Your Exam Papers',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Generated question papers are safely stored here.',
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      TextField(
                        controller:
                            searchController,
                        onChanged:
                            (value) {
                          setState(() {
                            searchText =
                                value;
                          });
                        },
                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                        ),
                        decoration:
                            InputDecoration(
                          filled:
                              true,
                          fillColor:
                              Colors.white,
                          hintText:
                              'Search subject, topic, year...',
                          prefixIcon:
                              const Icon(
                            Icons.search,
                          ),
                          suffixIcon:
                              searchText
                                      .isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed:
                                          () {
                                        searchController
                                            .clear();

                                        setState(
                                          () {
                                            searchText =
                                                '';
                                          },
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .clear,
                                      ),
                                    ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide
                                    .none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // LIST
                // ==================================================

                Expanded(
                  child:
                      StreamBuilder<
                          QuerySnapshot<
                              Map<String,
                                  dynamic>>>(
                    stream: collection
                        .orderBy(
                          'createdAt',
                          descending:
                              true,
                        )
                        .snapshots(),
                    builder:
                        (
                      context,
                      snapshot,
                    ) {
                      if (snapshot
                          .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              24,
                            ),
                            child: Text(
                              'Could not load question paper history.\n\n${snapshot.error}',
                              textAlign:
                                  TextAlign
                                      .center,
                            ),
                          ),
                        );
                      }

                      final documents =
                          snapshot.data?.docs ??
                              [];

                      final filtered =
                          documents
                              .where(
                                (
                                  document,
                                ) =>
                                    matchesSearch(
                                  document
                                      .data(),
                                ),
                              )
                              .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              30,
                            ),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .deepPurple
                                        .shade50,
                                    shape:
                                        BoxShape
                                            .circle,
                                  ),
                                  child:
                                      const Icon(
                                    Icons
                                        .description_outlined,
                                    size: 40,
                                    color:
                                        Colors
                                            .deepPurple,
                                  ),
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                const Text(
                                  'No Question Papers Yet',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  searchText
                                          .isEmpty
                                      ? 'Generate your first question paper and it will appear here.'
                                      : 'No papers match your search.',
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors
                                            .grey,
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          4,
                          16,
                          30,
                        ),
                        children:
                            buildHistoryGroups(
                          documents,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// QUESTION PAPER VIEWER
// ============================================================

class QuestionPaperViewerScreen
    extends StatelessWidget {
  final String paper;
  final String subject;
  final String year;
  final String difficulty;
  final String duration;
  final String totalMarks;
  final DateTime? createdAt;

  const QuestionPaperViewerScreen({
    super.key,
    required this.paper,
    required this.subject,
    required this.year,
    required this.difficulty,
    required this.duration,
    required this.totalMarks,
    required this.createdAt,
  });

  String formatDate() {
    if (createdAt == null) {
      return 'Recently generated';
    }

    final date = createdAt!;

    final hour =
        date.hour == 0 ? 12 : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  Future<void> copyPaper(
    BuildContext context,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: paper,
      ),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Question paper copied to clipboard.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor:
            Colors.deepPurple,
        foregroundColor:
            Colors.white,
        title: const Text(
          'Question Paper',
        ),
        actions: [
          IconButton(
            tooltip: 'Copy',
            onPressed: () {
              copyPaper(
                context,
              );
            },
            icon: const Icon(
              Icons.copy_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PAPER INFORMATION
            // ==================================================

            Card(
              elevation: 2,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .deepPurple
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .description_rounded,
                            color: Colors
                                .deepPurple,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            subject,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _viewerChip(
                          Icons
                              .school_outlined,
                          year,
                        ),
                        _viewerChip(
                          Icons
                              .speed_outlined,
                          difficulty,
                        ),
                        _viewerChip(
                          Icons
                              .timer_outlined,
                          duration,
                        ),
                        _viewerChip(
                          Icons
                              .grade_outlined,
                          '$totalMarks Marks',
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      'Generated: ${formatDate()}',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // PAPER
            // ==================================================

            Card(
              elevation: 2,
              margin:
                  const EdgeInsets.only(
                top: 16,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: SelectableText(
                  paper,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  copyPaper(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.copy,
                ),
                label: const Text(
                  'Copy Question Paper',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
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
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewerChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.deepPurple,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}