import 'package:flutter_gemini/flutter_gemini.dart';

class QuizAIService {
  static final Gemini gemini = Gemini.instance;

  static Future<String> generateQuiz(String notes) async {
    try {
      final prompt = """
You are an AI Quiz Generator.

Generate EXACTLY 10 multiple choice questions.

Return ONLY valid JSON.

Format:

[
  {
    "question":"Question",
    "options":[
      "Option A",
      "Option B",
      "Option C",
      "Option D"
    ],
    "correct":0
  }
]

Rules:
- No markdown
- No explanation
- No extra text
- correct must be 0,1,2 or 3

Study Notes:

$notes
""";

      final response = await gemini.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      return response?.output ?? "[]";
    } catch (e) {
      return "[]";
    }
  }
}