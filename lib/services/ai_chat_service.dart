import 'spark_ai_service.dart';

class AIChatService {
  static Future<String> ask(String prompt) async {
    return await SparkAIService.askAI(
      prompt: prompt,
    );
  }

  static void clearHistory() {
    SparkAIService.clearChat();
  }
}