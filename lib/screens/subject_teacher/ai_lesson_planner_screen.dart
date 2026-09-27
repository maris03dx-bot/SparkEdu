import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/spark_ai_service.dart';
import '../../services/ai_lesson_plan_history_service.dart';

class AILessonPlannerScreen extends StatefulWidget {
  const AILessonPlannerScreen({super.key});

  @override
  State<AILessonPlannerScreen> createState() =>
      _AILessonPlannerScreenState();
}

class _AILessonPlannerScreenState
    extends State<AILessonPlannerScreen> {
  final TextEditingController topicController =
      TextEditingController();

  int selectedDuration = 45;
  String selectedLevel = "Intermediate";
  String selectedYear = "III Year";

  bool isGenerating = false;
  String generatedLessonPlan = "";

  // ============================================================
  // DURATION RULES
  // Used only inside the hidden AI prompt.
  // ============================================================

  String getDurationPlan() {
    switch (selectedDuration) {
      case 30:
        return """
The lesson must fit exactly 30 minutes.

Use a realistic short classroom structure:
0–5 minutes: Introduction and prior-knowledge activation
5–12 minutes: Core concept explanation
12–20 minutes: Worked example or demonstration
20–26 minutes: Student practice or interaction
26–30 minutes: Assessment, recap and closing

All time blocks must total exactly 30 minutes.
Do not create content that requires more than 30 minutes.
""";

      case 45:
        return """
The lesson must fit exactly 45 minutes.

Use a realistic classroom structure:
0–5 minutes: Introduction and prior-knowledge activation
5–15 minutes: Core concept explanation
15–25 minutes: Worked example or demonstration
25–35 minutes: Guided student activity
35–41 minutes: Individual or pair practice and assessment
41–45 minutes: Recap and closing

All time blocks must total exactly 45 minutes.
Do not create content that requires more than 45 minutes.
""";

      case 60:
        return """
The lesson must fit exactly 60 minutes.

Use a realistic classroom structure:
0–5 minutes: Introduction and prior-knowledge activation
5–18 minutes: Core concept teaching
18–30 minutes: Worked examples and demonstration
30–43 minutes: Student activity or guided practice
43–53 minutes: Individual or pair practice and formative assessment
53–60 minutes: Review, questions, recap and closing

All time blocks must total exactly 60 minutes.
Use the additional time for meaningful practice and interaction.
""";

      case 90:
        return """
The lesson must fit exactly 90 minutes.

Use a realistic extended classroom structure:
0–10 minutes: Introduction and prior-knowledge check
10–25 minutes: Core concept explanation
25–40 minutes: Detailed examples and demonstration
40–55 minutes: Guided student activity
55–70 minutes: Individual or group practice
70–80 minutes: Application or problem-solving
80–87 minutes: Assessment and feedback
87–90 minutes: Recap and closing

All time blocks must total exactly 90 minutes.
Use the longer duration for deeper learning and practice.
Do not simply make the lecture longer.
""";

      default:
        return """
Create realistic time blocks that add up to exactly
$selectedDuration minutes.
""";
    }
  }

  // ============================================================
  // DIFFICULTY RULES
  // Used only inside the hidden AI prompt.
  // ============================================================

  String getDifficultyPlan() {
    switch (selectedLevel) {
      case "Beginner":
        return """
The students are learning the topic at a beginner level.

Teaching approach:
• Assume limited prior knowledge.
• Start with essential concepts and definitions.
• Use simple classroom language.
• Explain concepts step by step.
• Use familiar and easy-to-understand examples.
• Introduce technical terms only when necessary and explain them.
• Use guided practice before independent practice.
• Ask simple understanding questions.
• Build student confidence.
• Avoid unnecessary advanced concepts.

The lesson must genuinely feel suitable for beginners.
Do not simply label an advanced lesson as Beginner.
""";

      case "Intermediate":
        return """
The students have basic prior knowledge and are ready to
apply the topic.

Teaching approach:
• Briefly connect the topic to previously learned concepts.
• Explain the important concepts with appropriate technical detail.
• Use realistic examples.
• Include guided application.
• Ask students to apply, compare, explain or solve.
• Include moderate-difficulty questions.
• Give students opportunities for independent thinking.
• Include formative assessment.

The lesson should balance explanation, application and participation.
Do not make it too basic or unnecessarily advanced.
""";

      case "Advanced":
        return """
The students already have a strong foundation.

Teaching approach:
• Minimize basic introductory explanation.
• Focus on deeper concepts and relationships.
• Use realistic and technically meaningful examples.
• Include analytical and problem-solving activities.
• Ask students to justify decisions and explain reasoning.
• Include challenging scenarios or questions.
• Use case analysis, design, debugging, evaluation or problem-solving
  when appropriate.
• Assessment should test application, analysis or higher-order thinking.

Do not waste the selected duration on basic definitions.
The lesson must genuinely feel advanced.
""";

      default:
        return "";
    }
  }

  // ============================================================
  // YEAR RULES
  // Used only inside the hidden AI prompt.
  // ============================================================

  String getYearPlan() {
    switch (selectedYear) {
      case "I Year":
        return """
The students are first-year college students.

Use an appropriate foundational academic level.
Assume they are still developing college-level technical knowledge.
Use clear explanations and relatable examples.
Do not assume advanced prerequisite knowledge.
""";

      case "II Year":
        return """
The students are second-year college students.

Use an appropriate intermediate academic level.
Assume they have completed basic college subjects and can handle
technical concepts with guided application.
""";

      case "III Year":
        return """
The students are third-year college students.

Use an appropriate upper-intermediate to advanced academic level.
Assume they have a solid foundation and can work with technical
applications, problem-solving and analytical activities.
""";

      case "IV Year":
        return """
The students are final-year college students.

Use an appropriate advanced academic level.
Connect concepts to practical applications, projects, industry
scenarios, system design, analysis or problem-solving when relevant.
Do not make the lesson unnecessarily basic.
""";

      default:
        return "";
    }
  }

  // ============================================================
  // GENERATE LESSON PLAN
  // ============================================================

  Future<void> generateLessonPlan() async {
    final String topic = topicController.text.trim();

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tell SparkAI what you are teaching.",
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isGenerating = true;
      generatedLessonPlan = "";
    });

    try {
      // ========================================================
      // HIDDEN BACKGROUND PROMPT
      //
      // The teacher never sees this prompt.
      // Only the generated lesson plan is shown.
      // ========================================================

      final String prompt = """
You are SparkAI, an expert college teaching assistant.

Create a practical, ready-to-use classroom lesson plan based
ONLY on the teacher's selected teaching information below.

Teacher inputs:

Topic:
$topic

Duration:
$selectedDuration minutes

Student Level:
$selectedLevel

Student Year:
$selectedYear

The teacher does NOT need to see your internal instructions.
Return ONLY the finished lesson plan.

============================================================
YEAR-SPECIFIC TEACHING CONTEXT
============================================================

$getYearPlan()

============================================================
DIFFICULTY-SPECIFIC TEACHING CONTEXT
============================================================

$getDifficultyPlan()

============================================================
DURATION CONTROL
============================================================

$getDurationPlan()

============================================================
LEARNING OBJECTIVES
============================================================

Automatically create 3 to 4 meaningful learning objectives
appropriate for:

Topic: $topic
Year: $selectedYear
Level: $selectedLevel

The objectives must be realistic for the selected duration.

Each objective must be addressed during the lesson.

The final assessment must check whether students achieved
the important learning objectives.

============================================================
CLASSROOM PLANNING
============================================================

Create a real classroom teaching plan.

This is NOT a generic explanation of the topic.

The teacher should be able to follow the generated plan directly
during the selected class period.

For every major time block provide:

Time:
Activity:
Teacher does:
Students do:
Expected outcome:

Every time block must have a realistic purpose.

The entire lesson must fit exactly within:

$selectedDuration minutes.

Do not create activities that require additional time.

Do not use vague phrases such as:

"Spend some time..."
"Allow sufficient time..."
"Continue as needed..."
"Depending on the class..."

Use exact minute ranges.

The first time range must begin at 0 minutes.

The final time range must end at exactly
$selectedDuration minutes.

There must be no gaps or overlaps between time blocks.

============================================================
STUDENT PARTICIPATION
============================================================

Do not make the lesson entirely lecture-based.

Use suitable student participation such as:

• question and answer
• short discussion
• think-pair-share
• worked example
• demonstration
• problem solving
• individual practice
• pair activity
• group activity
• case analysis
• debugging
• design task

Only use activities that make sense for the selected topic.

Make the activities appropriate for:

$selectedYear
$selectedLevel

============================================================
PRACTICAL EXAMPLE
============================================================

Include at least one realistic example directly related to:

$topic

The example must be suitable for:

$selectedYear
$selectedLevel

The example should help students understand or apply the concept.

============================================================
ASSESSMENT
============================================================

Include a short formative assessment near the end.

The assessment must be possible within the selected duration.

Use an appropriate format such as:

• quick questions
• short problem
• application task
• mini quiz
• debugging task
• scenario
• exit ticket
• one-minute explanation

The assessment must test the actual learning objectives.

============================================================
WRAP-UP
============================================================

End with:

• key takeaways
• short recap
• final check for understanding

Optionally include a small homework or follow-up activity
if it is useful for the topic.

Homework must be realistic.

============================================================
OUTPUT FORMAT
============================================================

Start directly with:

Lesson Plan

Then use:

Lesson Overview

Learning Goals

Classroom Flow

Practical Example

Assessment

Wrap-Up

Optional Homework

For Lesson Overview include:

Topic:
Year:
Level:
Duration:

============================================================
IMPORTANT QUALITY RULES
============================================================

The generated lesson must be:

• realistic
• classroom-ready
• time-controlled
• suitable for the selected year
• suitable for the selected difficulty
• suitable for the selected duration
• interactive
• practical
• academically appropriate

The selected inputs MUST visibly affect the lesson.

Do not generate the same lesson simply by changing the
displayed year or difficulty label.

A Beginner lesson must be genuinely beginner-friendly.

An Intermediate lesson must include meaningful application.

An Advanced lesson must include deeper analysis or application.

The year must influence vocabulary, technical depth,
examples, assumptions and activities.

The duration must influence the amount of content,
practice and assessment.

============================================================
FINAL INTERNAL CHECK
============================================================

Before returning the lesson plan, internally verify:

1. The lesson is exactly $selectedDuration minutes.
2. The first time block starts at 0 minutes.
3. The final time block ends at $selectedDuration minutes.
4. There are no gaps in the schedule.
5. There are no overlapping time blocks.
6. The lesson is appropriate for $selectedLevel.
7. The lesson is appropriate for $selectedYear.
8. The lesson contains meaningful student participation.
9. Learning objectives are actually addressed.
10. Assessment checks the learning objectives.
11. The lesson is realistic for a real college classroom.
12. The lesson does not require extra time.

If anything fails these checks, fix it before returning the answer.

============================================================
PLAIN TEXT OUTPUT
============================================================

Return plain text only.

Do not use Markdown.

Do not use # symbols.

Do not use ## symbols.

Do not use ### symbols.

Do not use ** symbols.

Do not use Markdown code blocks.

Use simple plain-text headings.

Use the bullet character • when needed.

Do not add greetings.

Do not say "Here is your lesson plan."

Start directly with:

Lesson Plan
""";

      // ========================================================
      // SEND HIDDEN PROMPT TO SPARKAI
      // ========================================================

      final String response = await SparkAIService.askAI(
        prompt: prompt,
      );

      if (!mounted) return;

      final String cleanedResponse =
          cleanLessonPlanText(response);

      setState(() {
        generatedLessonPlan = cleanedResponse;
        isGenerating = false;
      });

      // ========================================================
      // SAVE TO HISTORY
      // ========================================================

      try {
        await AILessonPlanHistoryService.saveLessonPlan(
          topic: topic,
          className: selectedYear,
          duration: selectedDuration,
          difficulty: selectedLevel,
          objectives: "",
          lessonPlan: cleanedResponse,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Lesson plan saved to history.",
            ),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lesson created, but history could not be saved.\n$e",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to create the lesson.\n$e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // CLEAN AI RESPONSE
  // ============================================================

  String cleanLessonPlanText(String text) {
    String result = text.trim();

    result = result.replaceAll(
      RegExp(r'```[\s\S]*?```'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'^#{1,6}\s*', multiLine: true),
      '',
    );

    result = result.replaceAll('**', '');
    result = result.replaceAll('__', '');

    result = result.replaceAll(
      RegExp(r'(?<!\w)\*(?!\s)'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'^\s*>\s?', multiLine: true),
      '',
    );

    result = result.replaceAll(
      RegExp(r'^\s*[-*]\s+', multiLine: true),
      '• ',
    );

    result = result.replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    );

    return result.trim();
  }

  // ============================================================
  // OPEN HISTORY
  // ============================================================

  Future<void> openHistory() async {
    if (isGenerating) return;

    final Map<String, dynamic>? selectedLesson =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AILessonPlanHistoryScreen(),
      ),
    );

    if (!mounted || selectedLesson == null) {
      return;
    }

    final String topic =
        (selectedLesson['topic'] ?? '').toString();

    final String className =
        (selectedLesson['className'] ?? 'III Year')
            .toString();

    final String difficulty =
        (selectedLesson['difficulty'] ?? 'Intermediate')
            .toString();

    final String lessonPlan =
        (selectedLesson['lessonPlan'] ?? '').toString();

    final int duration =
        selectedLesson['duration'] is int
            ? selectedLesson['duration'] as int
            : int.tryParse(
                  selectedLesson['duration']
                          ?.toString() ??
                      '',
                ) ??
                45;

    setState(() {
      topicController.text = topic;

      selectedDuration = duration;

      if ([
        "Beginner",
        "Intermediate",
        "Advanced",
      ].contains(difficulty)) {
        selectedLevel = difficulty;
      }

      if ([
        "I Year",
        "II Year",
        "III Year",
        "IV Year",
      ].contains(className)) {
        selectedYear = className;
      }

      generatedLessonPlan =
          cleanLessonPlanText(lessonPlan);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Previous lesson loaded.",
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearAll() {
    topicController.clear();

    setState(() {
      selectedDuration = 45;
      selectedLevel = "Intermediate";
      selectedYear = "III Year";
      generatedLessonPlan = "";
    });
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> copyLessonPlan() async {
    if (generatedLessonPlan.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: generatedLessonPlan,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Lesson plan copied.",
        ),
      ),
    );
  }

  // ============================================================
  // DURATION CHIP
  // ============================================================

  Widget buildDurationChip(int duration) {
    final bool selected =
        selectedDuration == duration;

    return ChoiceChip(
      label: Text("$duration min"),
      selected: selected,
      onSelected: isGenerating
          ? null
          : (_) {
              setState(() {
                selectedDuration = duration;
              });
            },
      selectedColor: const Color(0xFF6B4FD3),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : const Color(0xFF4B4658),
        fontWeight:
            selected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFF6B4FD3)
            : const Color(0xFFE0DBEA),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // ============================================================
  // LEVEL CHIP
  // ============================================================

  Widget buildLevelChip(String level) {
    final bool selected =
        selectedLevel == level;

    return ChoiceChip(
      label: Text(level),
      selected: selected,
      onSelected: isGenerating
          ? null
          : (_) {
              setState(() {
                selectedLevel = level;
              });
            },
      selectedColor: const Color(0xFF6B4FD3),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : const Color(0xFF4B4658),
        fontWeight:
            selected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFF6B4FD3)
            : const Color(0xFFE0DBEA),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // ============================================================
  // YEAR CHIP
  // ============================================================

  Widget buildYearChip(String year) {
    final bool selected =
        selectedYear == year;

    return ChoiceChip(
      label: Text(year),
      selected: selected,
      onSelected: isGenerating
          ? null
          : (_) {
              setState(() {
                selectedYear = year;
              });
            },
      selectedColor: const Color(0xFF6B4FD3),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : const Color(0xFF4B4658),
        fontWeight:
            selected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFF6B4FD3)
            : const Color(0xFFE0DBEA),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9B96A8),
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            top: maxLines > 1 ? 14 : 0,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6B4FD3),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFFE1DCEC),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFFE1DCEC),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFF6B4FD3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENERATING VIEW
  // ============================================================

  Widget buildGeneratingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4DEEF),
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF6B4FD3),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "SparkAI is building your lesson...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF29243B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Planning the topic, year, level, timing and activities.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF817B8F),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT SECTION DETECTION
  // ============================================================

  bool isSectionHeading(String text) {
    final String value =
        text.trim().toLowerCase();

    const headings = [
      'lesson plan',
      'lesson overview',
      'learning goals',
      'learning objectives',
      'classroom flow',
      'classroom plan',
      'teaching flow',
      'practical example',
      'assessment',
      'wrap-up',
      'wrap up',
      'optional homework',
      'homework',
      'key takeaways',
      'recap',
      'teacher preparation',
      'materials',
      'resources',
    ];

    return headings.contains(value);
  }

  String normalizeHeading(String text) {
    final String value = text.trim();

    switch (value.toLowerCase()) {
      case 'wrap up':
        return 'Wrap-Up';

      case 'learning objectives':
        return 'Learning Goals';

      case 'classroom plan':
      case 'teaching flow':
        return 'Classroom Flow';

      case 'homework':
        return 'Optional Homework';

      default:
        return value;
    }
  }

  // ============================================================
  // RESULT LINE
  // ============================================================

  Widget buildResultLine(String line) {
    final String trimmed =
        line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 8);
    }

    if (isSectionHeading(trimmed)) {
      final String heading =
          normalizeHeading(trimmed);

      if (heading.toLowerCase() ==
          'lesson plan') {
        return const SizedBox.shrink();
      }

      return Padding(
        padding:
            const EdgeInsets.only(
          top: 18,
          bottom: 10,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF6B4FD3),
                borderRadius:
                    BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                heading,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF29243B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------
    // KEY-VALUE INFORMATION
    // ------------------------------------------------------------

    final RegExp keyValueRegex =
        RegExp(r'^([^:]{1,35}):\s*(.+)$');

    final Match? match =
        keyValueRegex.firstMatch(trimmed);

    if (match != null) {
      final String key =
          match.group(1)!.trim();

      final String value =
          match.group(2)!.trim();

      final List<String> knownKeys = [
        'topic',
        'year',
        'level',
        'duration',
        'class',
        'subject',
      ];

      if (knownKeys.contains(
        key.toLowerCase(),
      )) {
        return buildInfoRow(
          label: key,
          value: value,
        );
      }
    }

    // ------------------------------------------------------------
    // BULLET
    // ------------------------------------------------------------

    if (trimmed.startsWith('•')) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 9,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding:
                  EdgeInsets.only(
                top: 7,
              ),
              child: Icon(
                Icons.circle,
                size: 6,
                color:
                    Color(0xFF6B4FD3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                trimmed
                    .substring(1)
                    .trim(),
                style:
                    const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color:
                      Color(0xFF45404F),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------
    // NUMBERED ITEM
    // ------------------------------------------------------------

    final RegExp numberedRegex =
        RegExp(r'^(\d+)[.)]\s*(.+)$');

    final Match? numberedMatch =
        numberedRegex.firstMatch(trimmed);

    if (numberedMatch != null) {
      final String number =
          numberedMatch.group(1)!;

      final String content =
          numberedMatch.group(2)!;

      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 10,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 25,
              height: 25,
              alignment:
                  Alignment.center,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF6B4FD3)
                        .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF6B4FD3),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                content,
                style:
                    const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color:
                      Color(0xFF45404F),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------
    // TIME BLOCK
    // ------------------------------------------------------------

    if (RegExp(
      r'^\d+\s*[–-]\s*\d+\s*(minutes?|mins?)',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return Container(
        margin:
            const EdgeInsets.only(
          top: 4,
          bottom: 10,
        ),
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF7F4FD),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                const Color(0xFFE5DDF2),
          ),
        ),
        child: SelectableText(
          trimmed,
          style:
              const TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF45404F),
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // NORMAL TEXT
    // ------------------------------------------------------------

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: SelectableText(
        trimmed,
        style:
            const TextStyle(
          fontSize: 15,
          height: 1.65,
          color:
              Color(0xFF45404F),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget buildInfoRow({
    required String label,
    required String value,
  }) {
    IconData icon = Icons.info_outline;

    switch (label.toLowerCase()) {
      case 'topic':
        icon = Icons.auto_awesome;
        break;

      case 'year':
      case 'class':
        icon = Icons.groups_rounded;
        break;

      case 'level':
        icon = Icons.signal_cellular_alt_rounded;
        break;

      case 'duration':
        icon = Icons.schedule_rounded;
        break;

      case 'subject':
        icon = Icons.menu_book_rounded;
        break;
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FD),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFE8E1F1),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment:
                Alignment.center,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF6B4FD3)
                      .withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
                  const Color(0xFF6B4FD3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF8B8496),
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF393346),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget buildResultCard() {
    final List<String> lines =
        generatedLessonPlan
            .split('\n');

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 24,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFE3DDEE),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF6B4FD3)
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color:
                      Color(0xFF6B4FD3),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lesson Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF29243B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "AI-generated classroom plan",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF8B8695),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color:
                const Color(0xFFF0ECF5),
          ),

          const SizedBox(height: 6),

          for (final line in lines)
            buildResultLine(line),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF6B4FD3),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          "AI Lesson Planner",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                "Lesson history",
            icon: const Icon(
              Icons.history_rounded,
            ),
            onPressed:
                isGenerating
                    ? null
                    : openHistory,
          ),
          IconButton(
            tooltip:
                "Start over",
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed:
                isGenerating
                    ? null
                    : clearAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          40,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // INTRO
            // ======================================================

            const Text(
              "What are you teaching today?",
              style: TextStyle(
                fontSize: 27,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF29243B),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Choose the topic and class settings. SparkAI will build the teaching plan automatically.",
              style: TextStyle(
                fontSize: 14,
                color:
                    Color(0xFF8B8695),
              ),
            ),

            const SizedBox(height: 22),

            // ======================================================
            // TOPIC
            // ======================================================

            buildTextField(
              controller:
                  topicController,
              hint:
                  "Example: AI Agents and PEAS",
              icon:
                  Icons.auto_awesome,
            ),

            const SizedBox(height: 24),

            // ======================================================
            // DURATION
            // ======================================================

            const Text(
              "Class duration",
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF393346),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildDurationChip(30),
                buildDurationChip(45),
                buildDurationChip(60),
                buildDurationChip(90),
              ],
            ),

            const SizedBox(height: 22),

            // ======================================================
            // LEVEL
            // ======================================================

            const Text(
              "Student level",
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF393346),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildLevelChip("Beginner"),
                buildLevelChip("Intermediate"),
                buildLevelChip("Advanced"),
              ],
            ),

            const SizedBox(height: 22),

            // ======================================================
            // YEAR
            // ======================================================

            const Text(
              "Student year",
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF393346),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildYearChip("I Year"),
                buildYearChip("II Year"),
                buildYearChip("III Year"),
                buildYearChip("IV Year"),
              ],
            ),

            const SizedBox(height: 28),

            // ======================================================
            // BUILD BUTTON
            // ======================================================

            SizedBox(
              width: double.infinity,
              height: 58,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isGenerating
                        ? null
                        : generateLessonPlan,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF6B4FD3,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                icon: isGenerating
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                      ),
                label: Text(
                  isGenerating
                      ? "Building..."
                      : "Build My Lesson",
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ======================================================
            // GENERATING
            // ======================================================

            if (isGenerating)
              buildGeneratingCard(),

            // ======================================================
            // RESULT
            // ======================================================

            if (!isGenerating &&
                generatedLessonPlan
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✨ Your lesson is ready",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(
                              0xFF29243B,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Ready to use in your classroom",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Color(
                              0xFF8B8695,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        "Copy lesson plan",
                    onPressed:
                        copyLessonPlan,
                    icon:
                        const Icon(
                      Icons.copy_outlined,
                      color:
                          Color(0xFF5E5869),
                    ),
                  ),
                ],
              ),

              buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }
}

// ==================================================================
// AI LESSON PLAN HISTORY SCREEN
// ==================================================================

class AILessonPlanHistoryScreen
    extends StatefulWidget {
  const AILessonPlanHistoryScreen({
    super.key,
  });

  @override
  State<AILessonPlanHistoryScreen> createState() =>
      _AILessonPlanHistoryScreenState();
}

class _AILessonPlanHistoryScreenState
    extends State<AILessonPlanHistoryScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String searchText = "";

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchText =
            searchController.text
                .trim()
                .toLowerCase();
      });
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return "Today";
    }

    final DateTime date =
        timestamp.toDate();

    final DateTime now =
        DateTime.now();

    final DateTime today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime lessonDay =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final int difference =
        today
            .difference(lessonDay)
            .inDays;

    if (difference <= 0) {
      return "Today";
    }

    if (difference == 1) {
      return "Yesterday";
    }

    if (difference <= 7) {
      return "Previous 7 Days";
    }

    return "Older";
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  Future<void> deleteLesson(
    String planId,
  ) async {
    await AILessonPlanHistoryService
        .deleteLessonPlan(planId);
  }

  // ============================================================
  // DELETE ALL
  // ============================================================

  Future<void> confirmDeleteAll() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete all history?",
          ),
          content: const Text(
            "All saved lesson plans will be permanently deleted.",
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
                "Cancel",
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
                "Delete all",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AILessonPlanHistoryService
          .deleteAllLessonPlans();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "All lesson history deleted.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to delete history.\n$e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DELETE ONE DIALOG
  // ============================================================

  Future<void> confirmDelete(
    String planId,
    String topic,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete lesson?",
          ),
          content: Text(
            'Delete "$topic" from your history?',
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
                "Cancel",
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
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteLesson(planId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lesson deleted.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to delete lesson.\n$e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // OPEN LESSON
  // ============================================================

  void openLesson(
    Map<String, dynamic> data,
  ) {
    Navigator.pop(
      context,
      data,
    );
  }

  // ============================================================
  // LESSON CARD
  // ============================================================

  Widget buildLessonCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String topic =
        (data['topic'] ??
                'Untitled Lesson')
            .toString();

    final String className =
        (data['className'] ?? '')
            .toString();

    final String difficulty =
        (data['difficulty'] ??
                'Intermediate')
            .toString();

    final String lessonPlan =
        (data['lessonPlan'] ?? '')
            .toString();

    final String searchableText =
        "$topic $className $difficulty $lessonPlan"
            .toLowerCase();

    if (searchText.isNotEmpty &&
        !searchableText.contains(
          searchText,
        )) {
      return const SizedBox.shrink();
    }

    final int duration =
        data['duration'] is int
            ? data['duration'] as int
            : int.tryParse(
                  data['duration']
                          ?.toString() ??
                      '',
                ) ??
                45;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE4DEEF),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          8,
          10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                const Color(0xFF6B4FD3)
                    .withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color:
                Color(0xFF6B4FD3),
          ),
        ),
        title: Text(
          topic,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 16,
            color:
                Color(0xFF29243B),
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 7,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (className.isNotEmpty)
                _historyTag(
                  Icons.groups_rounded,
                  className,
                ),
              _historyTag(
                Icons.schedule_rounded,
                "$duration min",
              ),
              _historyTag(
                Icons.signal_cellular_alt_rounded,
                difficulty,
              ),
            ],
          ),
        ),
        trailing:
            PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "delete") {
              confirmDelete(
                document.id,
                topic,
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: "delete",
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          openLesson({
            ...data,
            'id': document.id,
          });
        },
      ),
    );
  }

  // ============================================================
  // HISTORY TAG
  // ============================================================

  Widget _historyTag(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF5F2FA),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color:
                const Color(0xFF746D80),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF746D80),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 70,
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF6B4FD3)
                        .withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color:
                    Color(0xFF6B4FD3),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No lesson plans yet",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF29243B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your generated lesson plans will appear here automatically.",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    Color(0xFF817B8F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD HISTORY
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF6B4FD3),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          "Lesson History",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                "Delete all history",
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
            onPressed:
                confirmDeleteAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // ========================================================
          // SEARCH
          // ========================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              10,
            ),
            child: TextField(
              controller:
                  searchController,
              textInputAction:
                  TextInputAction.search,
              decoration:
                  InputDecoration(
                hintText:
                    "Search lesson plans...",
                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                  color:
                      Color(0xFF6B4FD3),
                ),
                suffixIcon:
                    searchText.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                            onPressed: () {
                              searchController
                                  .clear();
                            },
                          )
                        : null,
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFFE1DCEC),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFFE1DCEC),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFF6B4FD3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // HISTORY LIST
          // ========================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  AILessonPlanHistoryService
                      .lessonPlanStream(),
              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF6B4FD3),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 45,
                            color: Colors.red,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            "Unable to load history.",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            snapshot.error
                                .toString(),
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    documents =
                    snapshot.data?.docs ?? [];

                // ==================================================
                // SEARCH
                // ==================================================

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    visibleDocuments =
                    documents.where((document) {
                  final Map<String, dynamic>
                      data =
                      document.data();

                  final String topic =
                      (data['topic'] ?? '')
                          .toString()
                          .toLowerCase();

                  final String className =
                      (data['className'] ?? '')
                          .toString()
                          .toLowerCase();

                  final String difficulty =
                      (data['difficulty'] ?? '')
                          .toString()
                          .toLowerCase();

                  final String lessonPlan =
                      (data['lessonPlan'] ?? '')
                          .toString()
                          .toLowerCase();

                  return searchText.isEmpty ||
                      topic.contains(
                        searchText,
                      ) ||
                      className.contains(
                        searchText,
                      ) ||
                      difficulty.contains(
                        searchText,
                      ) ||
                      lessonPlan.contains(
                        searchText,
                      );
                }).toList();

                if (documents.isEmpty) {
                  return buildEmptyState();
                }

                if (visibleDocuments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color:
                                Color(0xFF9B96A8),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            "No matching lessons",
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          const Text(
                            "Try another topic, year, level or keyword.",
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final Map<String,
                        List<
                            QueryDocumentSnapshot<
                                Map<String,
                                    dynamic>>>>
                    grouped = {
                  "Today": [],
                  "Yesterday": [],
                  "Previous 7 Days": [],
                  "Older": [],
                };

                for (final document
                    in visibleDocuments) {
                  final Map<String, dynamic>
                      data =
                      document.data();

                  final Timestamp? timestamp =
                      data['updatedAt']
                              is Timestamp
                          ? data['updatedAt']
                              as Timestamp
                          : null;

                  final String group =
                      formatDate(timestamp);

                  grouped[group]!.add(
                    document,
                  );
                }

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    30,
                  ),
                  children: [
                    for (final group
                        in [
                      "Today",
                      "Yesterday",
                      "Previous 7 Days",
                      "Older",
                    ])
                      if (grouped[group]!
                          .isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 12,
                            bottom: 10,
                          ),
                          child: Text(
                            group,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF514A5E),
                            ),
                          ),
                        ),
                        ...grouped[group]!
                            .map(
                          (document) {
                            return buildLessonCard(
                              document,
                            );
                          },
                        ),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}