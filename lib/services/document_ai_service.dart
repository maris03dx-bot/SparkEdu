import 'package:flutter_gemini/flutter_gemini.dart';

class DocumentAIService {
  static final Gemini gemini = Gemini.instance;

  static Future<String> askQuestion({
    required String documentText,
    required String question,
  }) async {
    try {
      final prompt = """
You are SparkAI, an AI learning assistant.

Use ONLY the information provided below to answer the student's question.

======================
DOCUMENT
======================

$documentText

======================
QUESTION
======================

$question

If the answer is not found in the document, clearly say:

"I couldn't find that information in the uploaded document."

Answer in a simple way suitable for college students.
""";

      final response = await gemini.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      return response?.output ??
          "Sorry, I couldn't generate an answer.";
    } catch (e) {
      return "Error: $e";
    }
  }
}