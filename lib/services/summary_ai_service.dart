import 'package:flutter_gemini/flutter_gemini.dart';

class SummaryAIService {
  static final Gemini gemini = Gemini.instance;

  static Future<String> summarize(String notes) async {
    try {
      final prompt = """
You are SparkAI.

Summarize the following study notes.

Requirements:
- Use simple language.
- Use bullet points.
- Highlight important concepts.
- Keep the summary suitable for quick revision.
- Do not exceed 300 words.

Study Notes:

$notes
""";

      final response = await gemini.prompt(
        parts: [
          Part.text(prompt),
        ],
      );

      return response?.output ?? "No summary generated.";
    } catch (e) {
      return "Error: $e";
    }
  }
}