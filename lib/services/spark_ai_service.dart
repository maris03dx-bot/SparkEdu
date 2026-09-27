import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Exception used for SparkAI failures.
///
/// ChatScreen can catch this separately from a successful AI answer,
/// so an error message is never accidentally saved as an AI response.
class SparkAIException implements Exception {
  final String message;

  const SparkAIException(this.message);

  @override
  String toString() => message;
}

class SparkAIService {
  static String _apiKey = "";

  static const String model = "gemini-3.5-flash";

  static const String endpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent";

  /// Current conversation used only for Gemini context.
  ///
  /// This is NOT the Firestore chat history.
  static final List<Map<String, dynamic>> _conversation = [];

  /// Maximum number of messages kept in the live Gemini context.
  ///
  /// A user message + AI answer = 2 messages.
  /// 12 messages therefore represents approximately 6 turns.
  static const int _maxConversationMessages = 12;

  /// Maximum number of tokens SparkAI can generate in one response.
  ///
  /// This was previously 700.
  ///
  /// Lesson plans require much more output because they can contain:
  /// • Lesson Overview
  /// • Learning Goals
  /// • Classroom Flow
  /// • Teacher Activities
  /// • Student Activities
  /// • Practical Example
  /// • Assessment
  /// • Wrap-Up
  /// • Optional Homework
  ///
  /// 3000 gives detailed requests enough room to finish properly.
  static const int _maxOutputTokens = 3000;

  /// Maximum time allowed for Gemini to generate a response.
  ///
  /// Detailed lesson plans can take longer than normal questions.
  static const Duration _requestTimeout =
      Duration(seconds: 60);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static void initialize({
    required String apiKey,
  }) {
    _apiKey = apiKey.trim();

    _conversation.clear();

    print("======================================");
    print("SparkAI initialized");
    print("API key present: ${_apiKey.isNotEmpty}");
    print("API key length: ${_apiKey.length}");
    print("Model: $model");
    print("Endpoint: $endpoint");
    print("Max output tokens: $_maxOutputTokens");
    print("Request timeout: ${_requestTimeout.inSeconds}s");
    print("======================================");
  }

  // ============================================================
  // CONFIGURATION
  // ============================================================

  static bool get isConfigured {
    final key = _apiKey.trim();

    return key.isNotEmpty &&
        key != "YOUR_API_KEY_HERE" &&
        key != "YOUR_NEW_GEMINI_API_KEY";
  }

  // ============================================================
  // ASK AI
  // ============================================================

  static Future<String> askAI({
    required String prompt,
  }) async {
    final String question = prompt.trim();

    if (question.isEmpty) {
      throw const SparkAIException(
        "Please enter a question.",
      );
    }

    if (!isConfigured) {
      throw const SparkAIException(
        "SparkAI is not configured. Please check the Gemini API key.",
      );
    }

    final Map<String, dynamic> userMessage = {
      "role": "user",
      "parts": [
        {
          "text": question,
        }
      ],
    };

    // Add the question to the temporary conversation.
    _conversation.add(userMessage);

    _trimConversation();

    final Map<String, dynamic> body = {
      "systemInstruction": {
        "parts": [
          {
            "text": """
You are SparkAI, the AI learning assistant inside SparkEdu.

Your job is to help students and teachers clearly, accurately, and efficiently.

============================================================
RESPONSE STYLE
============================================================

Always write responses in clean plain text.

DO NOT use Markdown formatting.

Never use:
- # headings
- ## headings
- ### headings
- **bold text**
- *italic text*
- ***bold italic***
- Markdown code fences
- unnecessary backticks
- decorative Markdown symbols

Instead of Markdown headings, write simple plain-text headings.

Example:

Bad:
# Lesson Plan

## Learning Objectives

Good:

Lesson Plan

Learning Objectives

============================================================
BULLET STYLE
============================================================

When a list is useful, use the bullet character:

• First point
• Second point
• Third point

Do not use:
*
**
- unnecessary Markdown bullets

For numbered steps, use:

1. First step
2. Second step
3. Third step

============================================================
GENERAL ANSWER STYLE
============================================================

Start with the answer immediately.

Do not unnecessarily greet the user.

Do not repeat the user's question.

Do not say:
"Sure!"
"Of course!"
"Let me explain..."
"I hope this helps."
"I'd be happy to help."

Keep responses natural and professional.

Use short paragraphs.

Use simple language.

Use spacing between sections so the answer is easy to read.

============================================================
ANSWER LENGTH
============================================================

Very simple question:
1–3 sentences.

Normal academic question:
3–7 sentences.

Question requiring steps:
Give only the necessary steps.

Detailed request:
Give a complete explanation.

For educational content generation, provide enough detail
to completely satisfy the requested task.

Do not stop before completing the requested content.

============================================================
ACADEMIC QUESTIONS
============================================================

You can help with:

• Mathematics
• Science
• Computer Science
• Programming
• Engineering
• Artificial Intelligence
• Data Structures
• Algorithms
• Database systems
• Operating systems
• Computer networks
• Exam preparation
• Study planning
• Academic concepts

============================================================
MATHEMATICS
============================================================

Give the final answer clearly.

Show calculation steps when necessary.

Do not add unnecessary theory to simple calculations.

============================================================
PROGRAMMING
============================================================

Explain the problem clearly.

Provide code when appropriate.

Keep code focused on the user's question.

When showing code, keep the code readable.

Do not surround code with Markdown backticks.

============================================================
TEACHER REQUESTS
============================================================

When a teacher asks SparkAI to create educational material such as:

• Lesson plans
• Question papers
• Assignments
• Teaching activities
• Student feedback
• Performance analysis
• Announcements
• Doubt summaries

Create practical, useful and classroom-ready content.

Do not create unnecessarily complicated academic content.

Make the structure easy for a teacher to scan and use.

When the requested content is detailed, complete every requested
section before ending the response.

============================================================
LESSON PLANS
============================================================

When creating a lesson plan:

Do not simply produce a long block of text.

Use a practical classroom structure such as:

Lesson Overview

Subject:
Topic:
Class:
Duration:
Difficulty:

Learning Goals

• Goal 1
• Goal 2
• Goal 3

Class Flow

1. Warm-up
2. Concept introduction
3. Explanation
4. Practical activity
5. Student interaction
6. Quick assessment
7. Wrap-up

Teaching Activity

Explain what the teacher should do and what students should do.

Assessment

Give a practical way to check student understanding.

Homework or Follow-up

Give a useful follow-up activity when appropriate.

Adapt the structure depending on the topic.

When a lesson-plan request specifies an exact duration,
make sure the complete lesson plan covers the entire requested
duration and finishes all requested sections.

Do not stop in the middle of a section.

Do not end with an incomplete sentence.

Do not omit the final assessment or wrap-up simply because
the lesson is long.

============================================================
QUESTION PAPERS
============================================================

When creating a question paper:

Clearly separate:

Section A
Section B
Section C

Include marks where appropriate.

Balance difficulty.

Avoid repeating the same type of question.

Complete the entire requested question paper before ending.

============================================================
ASSIGNMENTS
============================================================

When creating assignments:

Include:

Assignment Title

Objective

Instructions

Tasks

Expected Outcome

Submission Requirements

Keep them practical and relevant to the subject.

Complete all requested sections.

============================================================
AI ANNOUNCEMENTS
============================================================

When creating announcements:

Make them professional, short and clear.

Do not add unnecessary greetings.

============================================================
CONVERSATION CONTEXT
============================================================

Remember the previous messages provided in the conversation.

Use previous context when it helps.

Do not repeat information unnecessarily.

============================================================
SIMPLICITY
============================================================

If the user says:

"Explain simply"
"Make it easy"
"Explain like a beginner"

Use very simple language and short steps.

============================================================
DETAIL
============================================================

If the user says:

"Explain in detail"
"Explain deeply"
"Teach me this"
"Give more information"

Provide a more complete explanation.

For generated educational material, prioritize completeness
over unnecessary repetition.

============================================================
ACCURACY
============================================================

Do not invent facts.

If you are unsure, say so.

For calculations, carefully check the result.

============================================================
IDENTITY
============================================================

Do not introduce yourself.

Do not say:

"I am SparkAI."

Do not mention Gemini.

Do not mention Google AI.

Only identify yourself as SparkAI if the user explicitly asks who you are.

============================================================
COMPLETION
============================================================

Always finish the requested response.

For long educational requests:

• Complete every requested section.
• Do not stop halfway through a section.
• Do not end with an incomplete sentence.
• Do not replace requested content with a summary.
• Do not omit the final section.
• Keep the response within the requested duration, scope and format.

============================================================
MOST IMPORTANT
============================================================

Give the shortest useful answer that completely answers the request.

For detailed generation tasks, completeness is more important
than extreme brevity.

Use clean plain text.

Make the response easy to read.

Do not use Markdown formatting symbols.
"""
          }
        ]
      },
      "contents": List<Map<String, dynamic>>.from(
        _conversation,
      ),
      "generationConfig": {
        "thinkingConfig": {
          "thinkingLevel": "low",
        },
        "maxOutputTokens": _maxOutputTokens,
      },
    };

    try {
      print("======================================");
      print("SparkAI REQUEST");
      print("Model: $model");
      print("Question length: ${question.length}");
      print("Conversation messages: ${_conversation.length}");
      print("Max output tokens: $_maxOutputTokens");
      print("Timeout: ${_requestTimeout.inSeconds}s");
      print("======================================");

      final http.Response response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": _apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(
            _requestTimeout,
          );

      print("======================================");
      print("SparkAI RESPONSE");
      print("HTTP STATUS: ${response.statusCode}");
      print("Response length: ${response.body.length}");
      print("======================================");

      if (response.statusCode != 200) {
        _removeLastUserMessage();

        throw SparkAIException(
          _friendlyHttpError(
            response.statusCode,
            response.body,
          ),
        );
      }

      String answer = _extractAnswer(
        response.body,
      );

      if (answer.isEmpty) {
        _removeLastUserMessage();

        throw const SparkAIException(
          "SparkAI received an empty response. Please try again.",
        );
      }

      // Clean unwanted Markdown formatting.
      answer = _cleanResponse(answer);

      if (answer.trim().isEmpty) {
        _removeLastUserMessage();

        throw const SparkAIException(
          "SparkAI received an empty response. Please try again.",
        );
      }

      // Only add the AI response after Gemini successfully
      // returned a valid answer.
      _conversation.add({
        "role": "model",
        "parts": [
          {
            "text": answer,
          }
        ],
      });

      _trimConversation();

      return answer;
    } on SparkAIException {
      rethrow;
    } on TimeoutException {
      _removeLastUserMessage();

      throw const SparkAIException(
        "SparkAI took too long to respond. Please check your internet connection and try again.",
      );
    } on SocketException {
      _removeLastUserMessage();

      throw const SparkAIException(
        "SparkAI could not connect to the internet. Please check your connection and try again.",
      );
    } on FormatException {
      _removeLastUserMessage();

      throw const SparkAIException(
        "SparkAI received an invalid response. Please try again.",
      );
    } catch (e) {
      _removeLastUserMessage();

      print("======================================");
      print("SparkAI UNEXPECTED ERROR");
      print(e);
      print("======================================");

      throw const SparkAIException(
        "SparkAI could not respond right now. Please try again in a few seconds.",
      );
    }
  }

  // ============================================================
  // CLEAN AI RESPONSE
  // ============================================================

  /// Removes common Markdown formatting from Gemini responses.
  ///
  /// This gives SparkAI a clean ChatGPT-style reading experience
  /// inside SparkEdu.
  static String _cleanResponse(
    String text,
  ) {
    String result = text;

    // ----------------------------------------------------------
    // Remove Markdown headings
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'^\s*#{1,6}\s*',
        multiLine: true,
      ),
      '',
    );

    // ----------------------------------------------------------
    // Remove bold / italic Markdown
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'\*\*\*(.*?)\*\*\*',
        dotAll: true,
      ),
      r'$1',
    );

    result = result.replaceAll(
      RegExp(
        r'\*\*(.*?)\*\*',
        dotAll: true,
      ),
      r'$1',
    );

    result = result.replaceAll(
      RegExp(
        r'(?<!\*)\*(?!\*)(.*?)\*(?!\*)',
        dotAll: true,
      ),
      r'$1',
    );

    // ----------------------------------------------------------
    // Remove underscore emphasis
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'___(.*?)___',
        dotAll: true,
      ),
      r'$1',
    );

    result = result.replaceAll(
      RegExp(
        r'__(.*?)__',
        dotAll: true,
      ),
      r'$1',
    );

    // ----------------------------------------------------------
    // Convert Markdown bullet points to clean bullets
    // ----------------------------------------------------------

    result = result.replaceAllMapped(
      RegExp(
        r'^\s*[-*+]\s+',
        multiLine: true,
      ),
      (match) => '• ',
    );

    // ----------------------------------------------------------
    // Remove Markdown blockquote symbol
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'^\s*>\s?',
        multiLine: true,
      ),
      '',
    );

    // ----------------------------------------------------------
    // Remove inline code backticks
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'`([^`]*)`',
      ),
      r'$1',
    );

    // ----------------------------------------------------------
    // Remove Markdown horizontal lines
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'^\s*([-*_]){3,}\s*$',
        multiLine: true,
      ),
      '',
    );

    // ----------------------------------------------------------
    // Clean excessive blank lines
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'\n{3,}',
      ),
      '\n\n',
    );

    // ----------------------------------------------------------
    // Remove spaces before punctuation
    // ----------------------------------------------------------

    result = result.replaceAll(
      RegExp(
        r'[ \t]+([,.!?;:])',
      ),
      r'$1',
    );

    return result.trim();
  }

  // ============================================================
  // RESTORE SAVED CONVERSATION
  // ============================================================

  /// Restores an existing conversation into SparkAI's local context.
  ///
  /// IMPORTANT:
  /// This method does NOT call Gemini.
  ///
  /// It is intended for opening an old Firestore chat.
  static void restoreConversation(
    List<Map<String, dynamic>> conversation,
  ) {
    _conversation.clear();

    for (final Map<String, dynamic> message in conversation) {
      final dynamic role = message["role"];
      final dynamic text = message["text"];

      if (role != "user" && role != "model") {
        continue;
      }

      if (text is! String || text.trim().isEmpty) {
        continue;
      }

      _conversation.add({
        "role": role,
        "parts": [
          {
            "text": text.trim(),
          }
        ],
      });
    }

    _trimConversation();

    print("======================================");
    print("SparkAI CONVERSATION RESTORED");
    print("Messages restored: ${_conversation.length}");
    print("======================================");
  }

  // ============================================================
  // CLEAR CURRENT AI CONTEXT
  // ============================================================

  static void clearChat() {
    _conversation.clear();

    print("SparkAI chat context cleared.");
  }

  // ============================================================
  // GET CURRENT CONTEXT SIZE
  // ============================================================

  static int get conversationLength {
    return _conversation.length;
  }

  // ============================================================
  // TRIM CONVERSATION
  // ============================================================

  static void _trimConversation() {
    if (_conversation.length <= _maxConversationMessages) {
      return;
    }

    final int removeCount =
        _conversation.length - _maxConversationMessages;

    _conversation.removeRange(
      0,
      removeCount,
    );

    // Avoid starting the conversation with an AI message.
    //
    // This can happen if the trimming point falls between
    // a user message and its response.
    if (_conversation.isNotEmpty &&
        _conversation.first["role"] == "model") {
      _conversation.removeAt(0);
    }
  }

  // ============================================================
  // REMOVE LAST USER MESSAGE AFTER FAILURE
  // ============================================================

  static void _removeLastUserMessage() {
    if (_conversation.isNotEmpty &&
        _conversation.last["role"] == "user") {
      _conversation.removeLast();
    }
  }

  // ============================================================
  // EXTRACT AI ANSWER
  // ============================================================

  static String _extractAnswer(
    String responseBody,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        return "";
      }

      // --------------------------------------------------------
      // Log finish reason for debugging.
      // --------------------------------------------------------

      final dynamic candidates =
          decoded["candidates"];

      if (candidates is List &&
          candidates.isNotEmpty) {
        final dynamic candidate =
            candidates.first;

        if (candidate is Map<String, dynamic>) {
          final dynamic finishReason =
              candidate["finishReason"];

          if (finishReason != null) {
            print(
              "SparkAI finish reason: $finishReason",
            );
          }
        }
      }

      if (candidates is! List ||
          candidates.isEmpty) {
        return "";
      }

      final dynamic candidate =
          candidates.first;

      if (candidate is! Map<String, dynamic>) {
        return "";
      }

      final dynamic content =
          candidate["content"];

      if (content is! Map<String, dynamic>) {
        return "";
      }

      final dynamic parts =
          content["parts"];

      if (parts is! List ||
          parts.isEmpty) {
        return "";
      }

      final StringBuffer result =
          StringBuffer();

      for (final dynamic part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }

        final dynamic text =
            part["text"];

        if (text is String &&
            text.trim().isNotEmpty) {
          if (result.isNotEmpty) {
            result.writeln();
          }

          result.write(text.trim());
        }
      }

      return result.toString().trim();
    } catch (e) {
      print(
        "SparkAI response parsing error: $e",
      );

      return "";
    }
  }

  // ============================================================
  // FRIENDLY HTTP ERRORS
  // ============================================================

  static String _friendlyHttpError(
    int statusCode,
    String responseBody,
  ) {
    print("======================================");
    print("SparkAI API ERROR");
    print("HTTP STATUS: $statusCode");
    print("Response:");
    print(responseBody);
    print("======================================");

    switch (statusCode) {
      case 400:
        return "SparkAI received an invalid request. Please try asking the question again.";

      case 401:
        return "SparkAI authentication failed. Please check the Gemini API key.";

      case 403:
        return "SparkAI access was denied. Please check the Gemini API key and API settings.";

      case 404:
        return "SparkAI could not find the requested Gemini model or API endpoint.";

      case 408:
        return "SparkAI request timed out. Please try again.";

      case 429:
        return "SparkAI is temporarily rate-limited. Please wait a few seconds and try again.";

      case 500:
        return "The Gemini server encountered an error. Please try again later.";

      case 502:
      case 503:
      case 504:
        return "The Gemini service is temporarily unavailable. Please try again in a few seconds.";

      default:
        return "SparkAI encountered a server error. Please try again.";
    }
  }
}