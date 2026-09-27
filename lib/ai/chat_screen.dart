import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

import '../services/spark_ai_service.dart';
import '../services/spark_ai_doubt_tracker.dart';
import '../services/spark_ai_chat_history_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // ============================================================
  // VOICE INPUT
  // ============================================================

  final stt.SpeechToText speechToText = stt.SpeechToText();

  bool isSpeechAvailable = false;
  bool isListening = false;

  // ============================================================
  // TEXT TO SPEECH
  // ============================================================

  final FlutterTts flutterTts = FlutterTts();
  int? speakingMessageIndex;
  bool isSpeaking = false;

  // ============================================================
  // MESSAGES
  // ============================================================

  List<Map<String, dynamic>> messages = [];

  bool isLoading = false;

  // ============================================================
  // CHAT HISTORY
  // ============================================================

  String? currentChatId;

  bool isLoadingHistory = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> chatHistory = [];

  // ============================================================
  // HISTORY SEARCH
  // ============================================================

  final TextEditingController historySearchController =
      TextEditingController();

  String historySearchQuery = "";

  // ============================================================
  // STUDENT DETAILS
  // ============================================================

  String department = "";
  String year = "";
  String section = "";

  bool isLoadingStudent = true;

  // ============================================================
  // SUBJECTS
  // ============================================================

  List<Map<String, dynamic>> subjects = [];

  String? selectedSubjectId;
  Map<String, dynamic>? selectedSubject;

  bool isLoadingSubjects = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadStudentAndSubjects();
    loadChatHistory();
    initializeSpeech();
    initializeTextToSpeech();
  }

  // ============================================================
  // INITIALIZE VOICE INPUT
  // ============================================================

  Future<void> initializeSpeech() async {
    try {
      final bool available = await speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'notListening' || status == 'done') {
            setState(() {
              isListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint(
            'SparkAI speech error: ${error.errorMsg}',
          );

          if (!mounted) return;

          setState(() {
            isListening = false;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        isSpeechAvailable = available;
      });
    } catch (e) {
      debugPrint('SparkAI speech initialization error: $e');

      if (!mounted) return;

      setState(() {
        isSpeechAvailable = false;
        isListening = false;
      });
    }
  }

  // ============================================================
  // TOGGLE VOICE INPUT
  // ============================================================

  Future<void> toggleVoiceInput() async {
    if (isLoading) return;

    if (!isSpeechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice input is not available on this device or browser.',
          ),
        ),
      );
      return;
    }

    if (isListening) {
      await speechToText.stop();

      if (!mounted) return;

      setState(() {
        isListening = false;
      });

      return;
    }

    try {
      await speechToText.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            controller.text = result.recognizedWords;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );

      if (!mounted) return;

      setState(() {
        isListening = true;
      });
    } catch (e) {
      debugPrint('SparkAI voice input error: $e');

      if (!mounted) return;

      setState(() {
        isListening = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not start voice input. Please try again.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // INITIALIZE TEXT TO SPEECH
  // ============================================================

  Future<void> initializeTextToSpeech() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.48);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          isSpeaking = false;
          speakingMessageIndex = null;
        });
      });

      flutterTts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          isSpeaking = false;
          speakingMessageIndex = null;
        });
      });

      flutterTts.setErrorHandler((message) {
        debugPrint('SparkAI text-to-speech error: $message');
        if (!mounted) return;
        setState(() {
          isSpeaking = false;
          speakingMessageIndex = null;
        });
      });
    } catch (e) {
      debugPrint('SparkAI text-to-speech initialization error: $e');
    }
  }

  // ============================================================
  // READ AI ANSWER ALOUD
  // ============================================================

  Future<void> toggleTextToSpeech(String text, int messageIndex) async {
    final String answer = text.trim();
    if (answer.isEmpty) return;

    try {
      if (isSpeaking && speakingMessageIndex == messageIndex) {
        await flutterTts.stop();
        if (!mounted) return;
        setState(() {
          isSpeaking = false;
          speakingMessageIndex = null;
        });
        return;
      }

      await flutterTts.stop();
      if (!mounted) return;
      setState(() {
        isSpeaking = true;
        speakingMessageIndex = messageIndex;
      });
      await flutterTts.speak(answer);
    } catch (e) {
      debugPrint('SparkAI text-to-speech error: $e');
      if (!mounted) return;
      setState(() {
        isSpeaking = false;
        speakingMessageIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the SparkAI answer aloud.')),
      );
    }
  }

  // ============================================================
  // LOAD STUDENT + SUBJECTS
  // ============================================================

  Future<void> loadStudentAndSubjects() async {
    try {
      final User? user = auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingStudent = false;
          isLoadingSubjects = false;
        });

        return;
      }

      // ========================================================
      // LOAD STUDENT PROFILE
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> studentQuery =
          await firestore
              .collection("users")
              .where(
                "uid",
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      if (studentQuery.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingStudent = false;
          isLoadingSubjects = false;
        });

        return;
      }

      final Map<String, dynamic> studentData =
          studentQuery.docs.first.data();

      final String studentDepartment =
          studentData["department"]?.toString().trim() ?? "";

      final String studentYear =
          studentData["year"]?.toString().trim() ?? "";

      final String studentSection =
          studentData["section"]?.toString().trim() ?? "";

      if (!mounted) return;

      setState(() {
        department = studentDepartment;
        year = studentYear;
        section = studentSection;
        isLoadingStudent = false;
      });

      // ========================================================
      // LOAD SUBJECTS
      // ========================================================

      if (studentDepartment.isEmpty ||
          studentYear.isEmpty ||
          studentSection.isEmpty) {
        if (!mounted) return;

        setState(() {
          subjects = [];
          isLoadingSubjects = false;
        });

        return;
      }

      final QuerySnapshot<Map<String, dynamic>> subjectQuery =
          await firestore
              .collection("subjects")
              .where(
                "department",
                isEqualTo: studentDepartment,
              )
              .where(
                "year",
                isEqualTo: studentYear,
              )
              .where(
                "section",
                isEqualTo: studentSection,
              )
              .get();

      final List<Map<String, dynamic>> loadedSubjects = [];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in subjectQuery.docs) {
        final Map<String, dynamic> data = document.data();

        loadedSubjects.add({
          "id": document.id,
          ...data,
        });
      }

      if (!mounted) return;

      setState(() {
        subjects = loadedSubjects;
        isLoadingSubjects = false;
      });
    } catch (e) {
      debugPrint("Error loading SparkAI subjects: $e");

      if (!mounted) return;

      setState(() {
        isLoadingStudent = false;
        isLoadingSubjects = false;
      });
    }
  }

  // ============================================================
  // LOAD CHAT HISTORY
  // ============================================================

  Future<void> loadChatHistory() async {
    if (!mounted) return;

    setState(() {
      isLoadingHistory = true;
    });

    try {
      final chats =
          await SparkAIChatHistoryService.getChats();

      if (!mounted) return;

      setState(() {
        chatHistory = chats;
        isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint("Error loading SparkAI chat history: $e");

      if (!mounted) return;

      setState(() {
        isLoadingHistory = false;
      });
    }
  }

  // ============================================================
  // SUBJECT SELECTION
  // ============================================================

  void selectSubject(String? subjectId) {
    if (subjectId == null) {
      return;
    }

    Map<String, dynamic>? subject;

    for (final Map<String, dynamic> item in subjects) {
      if (item["id"]?.toString() == subjectId) {
        subject = item;
        break;
      }
    }

    if (subject == null) {
      return;
    }

    // Don't allow changing the subject while AI is answering.
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please wait for SparkAI to finish responding.",
          ),
        ),
      );

      return;
    }

    setState(() {
      selectedSubjectId = subjectId;
      selectedSubject = subject;
    });

    // ==========================================================
    // START A FRESH CHAT WHEN SUBJECT CHANGES
    // ==========================================================

    if (messages.isNotEmpty || currentChatId != null) {
      messages.clear();
      currentChatId = null;
      SparkAIService.clearChat();
    }

    debugPrint("======================================");
    debugPrint("SparkAI SUBJECT SELECTED");
    debugPrint("Subject ID: ${subject["id"]}");
    debugPrint("Subject Name: ${subject["name"]}");
    debugPrint("Subject Code: ${subject["code"]}");
    debugPrint("======================================");
  }

  // ============================================================
  // SELECTED SUBJECT NAME
  // ============================================================

  String getSelectedSubjectName() {
    if (selectedSubject == null) {
      return "";
    }

    return selectedSubject!["name"]?.toString().trim() ?? "";
  }

  // ============================================================
  // SELECTED SUBJECT CODE
  // ============================================================

  String getSelectedSubjectCode() {
    if (selectedSubject == null) {
      return "";
    }

    return selectedSubject!["code"]?.toString().trim() ?? "";
  }

  // ============================================================
  // CREATE CHAT TITLE
  // ============================================================

  String createChatTitle(String question) {
    String title = question.trim();

    if (title.isEmpty) {
      return "New Chat";
    }

    // Remove line breaks.
    title = title.replaceAll(RegExp(r'\s+'), ' ');

    // Keep history titles short like ChatGPT.
    if (title.length > 45) {
      title = "${title.substring(0, 45)}...";
    }

    return title;
  }

  // ============================================================
  // CREATE CHAT IF REQUIRED
  // ============================================================

  Future<void> ensureChatExists(String firstQuestion) async {
    if (currentChatId != null) {
      return;
    }

    final String subjectId =
        selectedSubject!["id"]?.toString().trim() ?? "";

    final String subjectName =
        selectedSubject!["name"]?.toString().trim() ?? "";

    final String subjectCode =
        selectedSubject!["code"]?.toString().trim() ?? "";

    final String chatId =
        await SparkAIChatHistoryService.createChat(
      title: createChatTitle(firstQuestion),
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCode: subjectCode,
    );

    currentChatId = chatId;

    await loadChatHistory();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    final String prompt = controller.text.trim();

    if (prompt.isEmpty || isLoading) {
      return;
    }

    // ==========================================================
    // SUBJECT REQUIRED
    // ==========================================================

    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a subject first.",
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // GET SUBJECT INFORMATION
    // ==========================================================

    final String subjectId =
        selectedSubject!["id"]?.toString().trim() ?? "";

    final String subjectName =
        selectedSubject!["name"]?.toString().trim() ?? "";

    final String subjectCode =
        selectedSubject!["code"]?.toString().trim() ?? "";

    // ==========================================================
    // CREATE FIRESTORE CHAT
    // ==========================================================

    try {
      await ensureChatExists(prompt);
    } catch (e) {
      debugPrint("Could not create SparkAI chat: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not save chat history. Please try again.",
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // SHOW USER MESSAGE
    // ==========================================================

    setState(() {
      messages.add({
        "role": "user",
        "text": prompt,
      });

      isLoading = true;
    });

    // ==========================================================
    // SAVE USER MESSAGE TO FIRESTORE
    // ==========================================================

    try {
      await SparkAIChatHistoryService.addMessage(
        chatId: currentChatId!,
        role: "user",
        text: prompt,
      );
    } catch (e) {
      debugPrint(
        "SparkAI user message history error: $e",
      );
    }

    // ==========================================================
    // SAVE DOUBT
    // ==========================================================

    try {
      await SparkAIDoubtTracker.saveDoubt(
        question: prompt,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectCode: subjectCode,
      );
    } catch (e) {
      debugPrint(
        "SparkAI doubt tracking error: $e",
      );
    }

    controller.clear();

    _scrollToBottom();

    // ==========================================================
    // ASK SPARKAI
    // ==========================================================

    try {
      final String answer =
          await SparkAIService.askAI(
        prompt: prompt,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // SHOW AI RESPONSE
      // ========================================================

      setState(() {
        messages.add({
          "role": "ai",
          "text": answer,
        });

        isLoading = false;
      });

      // ========================================================
      // SAVE AI RESPONSE TO FIRESTORE
      // ========================================================

      try {
        await SparkAIChatHistoryService.addMessage(
          chatId: currentChatId!,
          role: "ai",
          text: answer,
        );
      } catch (e) {
        debugPrint(
          "SparkAI AI message history error: $e",
        );
      }

      await loadChatHistory();

      _scrollToBottom();
    } catch (e) {
      debugPrint("SparkAI response error: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add({
          "role": "ai",
          "text":
              "SparkAI could not respond right now.\n\n"
              "Please try again in a few seconds.",
        });

        isLoading = false;
      });

      _scrollToBottom();
    }
  }

  // ============================================================
  // NEW CHAT
  // ============================================================

  void startNewChat() {
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please wait for SparkAI to finish responding.",
          ),
        ),
      );

      return;
    }

    setState(() {
      messages.clear();
      currentChatId = null;
    });

    SparkAIService.clearChat();

    Navigator.pop(context);

    debugPrint("SparkAI: New chat started");
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  Future<void> openChat(
  QueryDocumentSnapshot<Map<String, dynamic>> chat,
) async {
  if (isLoading || isLoadingHistory) {
    return;
  }

  setState(() {
    isLoadingHistory = true;
  });

  try {
    final String chatId = chat.id;

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        loadedMessages =
        await SparkAIChatHistoryService.getMessages(chatId);

    final List<Map<String, dynamic>> restoredMessages = [];

    for (final messageDoc in loadedMessages) {
      final data = messageDoc.data();

      final dynamic role = data['role'];
      final dynamic text = data['text'];

      if (text is! String || text.trim().isEmpty) {
        continue;
      }

      String displayRole;

      if (role == 'user') {
        displayRole = 'user';
      } else if (role == 'model' || role == 'ai') {
        displayRole = 'ai';
      } else {
        continue;
      }

      restoredMessages.add({
        'role': displayRole,
        'text': text.trim(),
      });
    }

    // Build the conversation context for SparkAI WITHOUT
    // sending any request to Gemini.
    final List<Map<String, dynamic>> aiConversation = [];

    for (final message in restoredMessages) {
      final String role = message['role'] as String;
      final String text = message['text'] as String;

      aiConversation.add({
        'role': role == 'user' ? 'user' : 'model',
        'text': text,
      });
    }

    SparkAIService.restoreConversation(
      aiConversation,
    );

    String? restoredSubjectId;

    final dynamic storedSubjectId =
        chat.data()['subjectId'];

    if (storedSubjectId is String &&
        storedSubjectId.trim().isNotEmpty) {
      restoredSubjectId = storedSubjectId;
    }

    Map<String, dynamic>? restoredSubject;

    if (restoredSubjectId != null) {
      for (final subject in subjects) {
        final dynamic subjectId = subject['id'];

        if (subjectId == restoredSubjectId) {
          restoredSubject = subject;
          break;
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      messages = restoredMessages;
      currentChatId = chatId;

      if (restoredSubject != null) {
        selectedSubjectId = restoredSubject['id'] as String?;
        selectedSubject = restoredSubject;
      }

      isLoadingHistory = false;
    });

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  } catch (e) {
    debugPrint('SparkAI open chat error: $e');

    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingHistory = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open this SparkAI conversation.',
        ),
      ),
    );
  }
}

  // ============================================================
  // DELETE CHAT
  // ============================================================

  Future<void> deleteChat(
    QueryDocumentSnapshot<Map<String, dynamic>> chat,
  ) async {
    final Map<String, dynamic> data = chat.data();

    final String title =
        data["title"]?.toString() ?? "Conversation";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete conversation?",
          ),
          content: Text(
            'Delete "$title"?\n\n'
            "This conversation and its messages will be permanently removed.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await SparkAIChatHistoryService.deleteChat(chat.id);

      if (currentChatId == chat.id) {
        setState(() {
          currentChatId = null;
          messages.clear();
        });

        SparkAIService.clearChat();
      }

      await loadChatHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Conversation deleted.",
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error deleting SparkAI chat: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not delete conversation.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // CLEAR ALL CHAT HISTORY
  // ============================================================

  Future<void> clearAllHistory() async {
    if (chatHistory.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete all chat history?",
          ),
          content: const Text(
            "All your SparkAI conversations will be permanently deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Delete All"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await SparkAIChatHistoryService.deleteAllChats();

      if (!mounted) return;

      setState(() {
        chatHistory.clear();
        currentChatId = null;
        messages.clear();
      });

      SparkAIService.clearChat();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "All chat history deleted.",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "Error clearing SparkAI history: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not clear chat history.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? getChatDate(
    QueryDocumentSnapshot<Map<String, dynamic>> chat,
  ) {
    final dynamic timestamp =
        chat.data()["updatedAt"];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String getDateGroup(
    DateTime? date,
  ) {
    if (date == null) {
      return "Older";
    }

    final DateTime now = DateTime.now();

    if (isSameDay(date, now)) {
      return "Today";
    }

    final DateTime yesterday =
        now.subtract(const Duration(days: 1));

    if (isSameDay(date, yesterday)) {
      return "Yesterday";
    }

    final DateTime sevenDaysAgo =
        now.subtract(const Duration(days: 7));

    if (date.isAfter(sevenDaysAgo)) {
      return "Previous 7 Days";
    }

    return "Older";
  }

  // ============================================================
  // FORMAT CHAT TIME
  // ============================================================

  String formatChatTime(DateTime? date) {
    if (date == null) {
      return "";
    }

    final int hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final String minute =
        date.minute.toString().padLeft(2, "0");

    final String period =
        date.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  // ============================================================
  // FILTER CHAT HISTORY
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>> getFilteredChatHistory() {
    final String query = historySearchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return chatHistory;
    }

    return chatHistory.where((chat) {
      final Map<String, dynamic> data = chat.data();

      final String title =
          data["title"]?.toString().toLowerCase() ?? "";
      final String subjectName =
          data["subjectName"]?.toString().toLowerCase() ?? "";
      final String subjectCode =
          data["subjectCode"]?.toString().toLowerCase() ?? "";

      return title.contains(query) ||
          subjectName.contains(query) ||
          subjectCode.contains(query);
    }).toList();
  }

  // ============================================================
  // HISTORY DRAWER
  // ============================================================

  Widget buildHistoryDrawer() {
    final List<String> groups = [
      "Today",
      "Yesterday",
      "Previous 7 Days",
      "Older",
    ];

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredChats =
        getFilteredChatHistory();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // DRAWER HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                12,
                18,
              ),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "SparkAI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Close",
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Your learning conversations",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // NEW CHAT BUTTON
                  // ==========================================

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: startNewChat,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        "New Chat",
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Colors.deepPurple,
                        backgroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
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

                  const SizedBox(height: 12),

                  // ==========================================
                  // SEARCH CONVERSATIONS
                  // ==========================================

                  TextField(
                    controller: historySearchController,
                    onChanged: (value) {
                      setState(() {
                        historySearchQuery = value;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search conversations...",
                      hintStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      suffixIcon: historySearchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: "Clear search",
                              onPressed: () {
                                historySearchController.clear();
                                setState(() {
                                  historySearchQuery = "";
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.14),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Colors.white54,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // HISTORY
            // ==================================================

            Expanded(
              child: isLoadingHistory
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : chatHistory.isEmpty
                      ? buildEmptyHistory()
                      : filteredChats.isEmpty
                          ? buildNoSearchResults()
                          : ListView(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 10,
                              ),
                              children: [
                                for (final String group
                                    in groups)
                                  buildHistoryGroup(
                                    group,
                                    chats: filteredChats,
                                  ),
                              ],
                            ),
            ),

            // ==================================================
            // DELETE ALL
            // ==================================================

            if (chatHistory.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: clearAllHistory,
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                    ),
                    label: const Text(
                      "Delete All History",
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.red.shade700,
                      side: BorderSide(
                        color: Colors.red.shade200,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY HISTORY
  // ============================================================

  Widget buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 55,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              "No conversations yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ask SparkAI a question to start your first chat.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 31,
                color: Colors.deepPurple.shade300,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No conversations found",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No chat matches "$historySearchQuery".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                historySearchController.clear();
                setState(() {
                  historySearchQuery = "";
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text("Clear search"),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY GROUP
  // ============================================================

  Widget buildHistoryGroup(
    String group, {
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? chats,
  }) {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        sourceChats = chats ?? chatHistory;

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        groupChats = sourceChats.where((chat) {
      return getDateGroup(getChatDate(chat)) == group;
    }).toList();

    if (groupChats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            12,
            7,
          ),
          child: Text(
            group,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        for (final QueryDocumentSnapshot<
                Map<String, dynamic>>
            chat in groupChats)
          buildHistoryItem(chat),
      ],
    );
  }

  // ============================================================
  // HISTORY ITEM
  // ============================================================

  Widget buildHistoryItem(
  QueryDocumentSnapshot<Map<String, dynamic>> chat,
) {
  final Map<String, dynamic> data = chat.data();

  final String title =
      data["title"]?.toString().trim().isEmpty ?? true
          ? "New Chat"
          : data["title"].toString();

  final String subjectName =
      data["subjectName"]?.toString() ?? "";

  final String subjectCode =
      data["subjectCode"]?.toString() ?? "";

  final DateTime? date = getChatDate(chat);

  final bool isCurrent =
      currentChatId == chat.id;

  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: isCurrent
          ? Colors.deepPurple.shade50
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.deepPurple
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: isCurrent
                ? Colors.white
                : Colors.grey.shade600,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            if (subjectName.isNotEmpty)
              Expanded(
                child: Text(
                  subjectCode.isEmpty
                      ? subjectName
                      : "$subjectName • $subjectCode",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            if (date != null)
              Text(
                formatChatTime(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
        onTap: () => openChat(chat),
        trailing: PopupMenuButton<String>(
          tooltip: "Chat options",
          onSelected: (value) {
            if (value == "delete") {
              deleteChat(chat);
            }
          },
          itemBuilder: (context) => const [
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
      ),
    ),
  );
}

  // ============================================================
  // CLEAR CURRENT CHAT
  // ============================================================

  void clearChat() {
    if (messages.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Clear conversation?",
          ),
          content: const Text(
            "This will start a new SparkAI conversation. "
            "Your previous conversation will remain in Chat History.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  messages.clear();
                  currentChatId = null;
                });

                SparkAIService.clearChat();
                flutterTts.stop();
                isSpeaking = false;
                speakingMessageIndex = null;
              },
              child: const Text(
                "New Chat",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // USER MESSAGE
  // ============================================================

  Widget buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
                  0.78,
        ),
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AI QUICK ACTIONS
  // ============================================================

  String? getLastUserQuestion(int aiMessageIndex) {
    for (int i = aiMessageIndex - 1; i >= 0; i--) {
      if (messages[i]["role"] == "user") {
        final String question = messages[i]["text"]?.toString().trim() ?? "";
        if (question.isNotEmpty) {
          return question;
        }
      }
    }

    return null;
  }

  Future<void> copyAIAnswer(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Answer copied to clipboard."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> runAIQuickAction({
    required String action,
    required String originalQuestion,
  }) async {
    if (isLoading) return;

    String prompt;

    switch (action) {
      case "simpler":
        prompt =
            "Explain the following answer again in simpler language, "
            "step by step, as if teaching a student who is new to the topic. "
            "Keep the important details and add a simple example if useful. "
            "Original question: $originalQuestion";
        break;

      case "example":
        prompt =
            "Give a clear, practical example for the following question. "
            "Explain the example step by step and connect it to the concept. "
            "Keep it easy for a student to understand. "
            "Original question: $originalQuestion";
        break;

      case "regenerate":
        prompt =
            "Give a fresh and improved answer to this question. "
            "Use a different explanation or examples where helpful, "
            "while remaining accurate and student-friendly. "
            "Question: $originalQuestion";
        break;

      default:
        return;
    }

    await sendMessageWithPrompt(prompt);
  }

  Future<void> sendMessageWithPrompt(String prompt) async {
    final String cleanedPrompt = prompt.trim();

    if (cleanedPrompt.isEmpty || isLoading) {
      return;
    }

    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a subject first."),
        ),
      );
      return;
    }

    final String subjectId =
        selectedSubject!["id"]?.toString().trim() ?? "";
    final String subjectName =
        selectedSubject!["name"]?.toString().trim() ?? "";
    final String subjectCode =
        selectedSubject!["code"]?.toString().trim() ?? "";

    try {
      await ensureChatExists(cleanedPrompt);
    } catch (e) {
      debugPrint("Could not create SparkAI quick-action chat: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not save chat history. Please try again."),
        ),
      );

      return;
    }

    setState(() {
      messages.add({
        "role": "user",
        "text": cleanedPrompt,
      });
      isLoading = true;
    });

    try {
      await SparkAIChatHistoryService.addMessage(
        chatId: currentChatId!,
        role: "user",
        text: cleanedPrompt,
      );
    } catch (e) {
      debugPrint("SparkAI quick-action user history error: $e");
    }

    try {
      await SparkAIDoubtTracker.saveDoubt(
        question: cleanedPrompt,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectCode: subjectCode,
      );
    } catch (e) {
      debugPrint("SparkAI quick-action doubt tracking error: $e");
    }

    _scrollToBottom();

    try {
      final String answer = await SparkAIService.askAI(
        prompt: cleanedPrompt,
      );

      if (!mounted) return;

      setState(() {
        messages.add({
          "role": "ai",
          "text": answer,
        });
        isLoading = false;
      });

      try {
        await SparkAIChatHistoryService.addMessage(
          chatId: currentChatId!,
          role: "ai",
          text: answer,
        );
      } catch (e) {
        debugPrint("SparkAI quick-action AI history error: $e");
      }

      await loadChatHistory();
      _scrollToBottom();
    } catch (e) {
      debugPrint("SparkAI quick-action response error: $e");

      if (!mounted) return;

      setState(() {
        messages.add({
          "role": "ai",
          "text":
              "SparkAI could not respond right now.\n\n"
              "Please try again in a few seconds.",
        });
        isLoading = false;
      });

      _scrollToBottom();
    }
  }


  // ============================================================
  // AI MESSAGE
  // ============================================================

  Widget buildAIMessage(String text, {required int messageIndex}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.5),
                h1: const TextStyle(color: Colors.black87, fontSize: 25, fontWeight: FontWeight.bold, height: 1.3),
                h2: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                h3: const TextStyle(color: Colors.black87, fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
                h4: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
                strong: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                em: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                listBullet: const TextStyle(color: Colors.black87, fontSize: 16),
                blockquote: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.5),
                code: TextStyle(color: Colors.deepPurple.shade700, backgroundColor: Colors.grey.shade300, fontSize: 14),
                codeblockDecoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade400)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final bool speaking = isSpeaking && speakingMessageIndex == messageIndex;
                final String? question = getLastUserQuestion(messageIndex);

                return Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => toggleTextToSpeech(text, messageIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                                size: 20,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                speaking ? 'Stop' : 'Read aloud',
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (question != null) ...[
                      IconButton(
                        tooltip: "Copy answer",
                        visualDensity: VisualDensity.compact,
                        onPressed: isLoading ? null : () => copyAIAnswer(text),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                      ),
                      IconButton(
                        tooltip: "Explain simpler",
                        visualDensity: VisualDensity.compact,
                        onPressed: isLoading ? null : () => runAIQuickAction(action: "simpler", originalQuestion: question),
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      ),
                      IconButton(
                        tooltip: "Give an example",
                        visualDensity: VisualDensity.compact,
                        onPressed: isLoading ? null : () => runAIQuickAction(action: "example", originalQuestion: question),
                        icon: const Icon(Icons.auto_stories_outlined, size: 18),
                      ),
                      IconButton(
                        tooltip: "Regenerate answer",
                        visualDensity: VisualDensity.compact,
                        onPressed: isLoading ? null : () => runAIQuickAction(action: "regenerate", originalQuestion: question),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME MESSAGE
  // ============================================================

  Widget buildSuggestionCard({
    required IconData icon,
    required String title,
    required String question,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isLoading
          ? null
          : () {
              controller.text = question;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.deepPurple.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.deepPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWelcomeMessage() {
    final String subjectName = getSelectedSubjectName();
    final bool hasSubject = selectedSubject != null && subjectName.isNotEmpty;

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(
          top: 20,
          bottom: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 600
              ? 560
              : MediaQuery.of(context).size.width * 0.94,
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.deepPurple.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Hi, I'm SparkAI 👋",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Your AI learning assistant",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSubject
                  ? "Ask questions, understand concepts, and learn better with $subjectName."
                  : "Select a subject, then ask questions, understand concepts, and learn better.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Try asking",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            buildSuggestionCard(
              icon: Icons.lightbulb_outline_rounded,
              title: "Explain a topic simply",
              question: hasSubject
                  ? "Explain an important topic in $subjectName in simple terms."
                  : "Explain an important academic topic in simple terms.",
            ),
            buildSuggestionCard(
              icon: Icons.assignment_outlined,
              title: "Help me prepare for an exam",
              question: hasSubject
                  ? "Help me prepare for my $subjectName exam."
                  : "Help me prepare for my upcoming exam.",
            ),
            buildSuggestionCard(
              icon: Icons.code_rounded,
              title: "Help me with programming",
              question: "Teach me a programming concept with a simple example.",
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING MESSAGE
  // ============================================================

  Widget buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "SparkAI is thinking...",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBJECT SELECTOR
  // ============================================================

  Widget buildSubjectSelector() {
    if (isLoadingSubjects) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          4,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Loading subjects...",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (subjects.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          4,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.shade200,
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "No subjects found for your class. "
                "Please check your student profile and subjects.",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        4,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: selectedSubject == null
              ? Colors.orange.shade300
              : Colors.deepPurple.shade200,
          width: 1.3,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSubjectId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          hint: const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 10),
              Text(
                "Select Subject",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          items: subjects.map(
            (
              Map<String, dynamic> subject,
            ) {
              final String id =
                  subject["id"]?.toString() ?? "";

              final String name =
                  subject["name"]?.toString().trim() ??
                      "Subject";

              final String code =
                  subject["code"]?.toString().trim() ?? "";

              return DropdownMenuItem<String>(
                value: id,
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.deepPurple,
                      size: 21,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        code.isEmpty
                            ? name
                            : "$name ($code)",
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: selectSubject,
        ),
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
          const Color(0xFFFFF7FF),

      // ========================================================
      // HISTORY DRAWER
      // ========================================================

      drawer: buildHistoryDrawer(),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              "SparkAI",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor:
            Colors.deepPurple,
        foregroundColor:
            Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: "Chat history",
              icon: const Icon(
                Icons.menu_rounded,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: "New chat",
            icon: const Icon(
              Icons.add_comment_outlined,
            ),
            onPressed: startNewChat,
          ),
          IconButton(
            tooltip: "New chat",
            icon: const Icon(
              Icons.delete_outline,
            ),
            onPressed: clearChat,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          // ======================================================
          // SUBJECT SELECTOR
          // ======================================================

          buildSubjectSelector(),

          // ======================================================
          // SELECTED SUBJECT INFORMATION
          // ======================================================

          if (selectedSubject != null)
            Container(
              margin: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                2,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color:
                    Colors.deepPurple.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color:
                        Colors.deepPurple,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      getSelectedSubjectCode()
                              .isEmpty
                          ? getSelectedSubjectName()
                          : "${getSelectedSubjectName()} • ${getSelectedSubjectCode()}",
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.deepPurple,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ======================================================
          // CHAT MESSAGES
          // ======================================================

          Expanded(
            child: ListView.builder(
              controller:
                  scrollController,
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                20,
              ),
              itemCount:
                  messages.length +
                  (messages.isEmpty ? 1 : 0) +
                  (isLoading ? 1 : 0),
              itemBuilder:
                  (context, index) {
                // ----------------------------------------------
                // WELCOME
                // ----------------------------------------------

                if (messages.isEmpty &&
                    index == 0) {
                  return buildWelcomeMessage();
                }

                // ----------------------------------------------
                // LOADING
                // ----------------------------------------------

                if (isLoading &&
                  index == messages.length + (messages.isEmpty ? 1 : 0)) {
                 return buildLoadingMessage();
               }

                // ----------------------------------------------
                // MESSAGE
                // ----------------------------------------------

                final Map<String, dynamic>
                    message =
                    messages[index];

                final String text =
                    message["text"].toString();

                final bool isUser =
                    message["role"] == "user";

                if (isUser) {
                  return buildUserMessage(
                    text,
                  );
                }

               return buildAIMessage(
                    text,
                    messageIndex: index,
                 );
              },
            ),
          ),

          // ======================================================
          // INPUT AREA
          // ======================================================

          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                10,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 8,
                    offset:
                        const Offset(
                      0,
                      -2,
                    ),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  // ============================================
                  // TEXT FIELD
                  // ============================================

                  Expanded(
                    child: TextField(
                      controller:
                          controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction:
                          TextInputAction.newline,
                      decoration:
                          InputDecoration(
                        hintText:
                            selectedSubject ==
                                    null
                                ? "Select a subject first..."
                                : "Ask about ${getSelectedSubjectName()}...",
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            28,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            28,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            28,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // ============================================
                  // VOICE INPUT BUTTON
                  // ============================================

                  Container(
                    decoration: BoxDecoration(
                      color: isListening
                          ? Colors.red.shade600
                          : Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: isListening
                          ? 'Stop listening'
                          : 'Voice input',
                      icon: Icon(
                        isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: isListening
                            ? Colors.white
                            : Colors.deepPurple,
                      ),
                      onPressed: isLoading
                          ? null
                          : toggleVoiceInput,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  // ============================================
                  // SEND BUTTON
                  // ============================================

                  Container(
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.deepPurple,
                      shape:
                          BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: "Send",
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color:
                                  Colors.white,
                            ),
                      onPressed:
                          isLoading
                              ? null
                              : sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    historySearchController.dispose();
    speechToText.stop();
    flutterTts.stop();

    super.dispose();
  }
}