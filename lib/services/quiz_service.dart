import 'package:flutter_gemini/flutter_gemini.dart';

class QuizService {
  static final Gemini gemini = Gemini.instance;

  static Future<String> generateQuiz(String notes) async {
    final prompt = """
You are an educational AI.

Read the study material below and generate:

1. Five multiple-choice questions.
2. Each question should have 4 options.
3. Mention the correct answer after each question.

Study Material:

$notes
""";

    try {
      final response = await gemini.prompt(parts: [
        Part.text(prompt),
      ]);

      return response?.output ?? "Unable to generate quiz.";
    } catch (e) {
      return "Error: $e";
    }
  }
}