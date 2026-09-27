import 'package:flutter_gemini/flutter_gemini.dart';

class StudyPlannerService {
  static final Gemini gemini = Gemini.instance;

  static Future<String> generatePlan({
    required String subject,
    required String examDate,
    required String hours,
  }) async {
    try {
      final prompt = """
You are an AI Study Planner.

Create a personalized study plan.

Subject:
$subject

Exam Date:
$examDate

Available Study Hours Per Day:
$hours

Generate:
• Daily schedule
• Important topics
• Revision plan
• Tips for scoring high

Keep the answer simple and well formatted.
""";

      final response = await gemini.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      return response?.output ?? "No study plan generated.";
    } catch (e) {
      return "Error: $e";
    }
  }
}