import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/file_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/quiz_ai_service.dart';

import 'quiz_play_screen.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() =>
      _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState
    extends State<QuizGeneratorScreen> {

  final TextEditingController notesController =
      TextEditingController();

  bool loading = false;
  bool generatingQuiz = false;

  String extractedText = "";

  File? selectedImage;
  File? selectedFile;

  String selectedFileName = "";

  int extractedCharacters = 0;

  int extractedWords = 0;

  Future<void> pickImage() async {

    final image = await FileService.pickImage();

    if (image == null) return;

    setState(() {
      loading = true;
      selectedImage = image;
    });

    final text =
        await OCRService.readText(image);

    setState(() {

      extractedText = text;

      notesController.text = text;

      selectedFileName =
          image.path.split("/").last;

      extractedCharacters = text.length;

      extractedWords =
          text.trim().isEmpty
              ? 0
              : text.trim().split(RegExp(r"\s+")).length;

      loading = false;

    });

  }

  Future<void> pickFile() async {

    final file =
        await FileService.pickFile();

    if (file == null) return;

    setState(() {

      loading = true;

      selectedFile = file;

    });

    final text =
        await PdfService.extractText(file);

    setState(() {

      extractedText = text;

      notesController.text = text;

      selectedFileName =
          file.path.split("/").last;

      extractedCharacters =
          text.length;

      extractedWords =
          text.trim().isEmpty
              ? 0
              : text.trim().split(RegExp(r"\s+")).length;

      loading = false;

    });

  }

  Future<void> generateQuiz() async {

    if (notesController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Please upload notes first."),
        ),
      );

      return;

    }

    setState(() {

      generatingQuiz = true;

    });

    try {

      final response =
          await QuizAIService.generateQuiz(
        notesController.text,
      );

      final cleaned = response
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final List<dynamic> json =
          jsonDecode(cleaned);

      final questions =
          List<Map<String, dynamic>>.from(
              json);

      setState(() {

        generatingQuiz = false;

      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPlayScreen(
            questions: questions,
          ),
        ),
      );

    } catch (e) {

      setState(() {

        generatingQuiz = false;

      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    }

  }@override
Widget build(BuildContext context) {

  return Scaffold(

    appBar: AppBar(
      title: const Text("📝 SparkAI Quiz Generator"),
      backgroundColor: Colors.orange,
      centerTitle: true,
    ),

    body: SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "Choose Input Method",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(

            children: [

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text("Notes"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text("Photo"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("PDF"),
                ),
              ),

            ],

          ),

          const SizedBox(height: 25),

          TextField(

            controller: notesController,

            maxLines: 8,

            decoration: InputDecoration(

              labelText: "Paste Notes",

              hintText:
                  "Paste your notes here or upload a PDF/image.",

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),

            ),

          ),

          const SizedBox(height: 25),

          const Text(

            "Document Summary",

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),

          ),

          const SizedBox(height: 10),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(

              color: Colors.orange.shade50,

              borderRadius:
                  BorderRadius.circular(20),

              border: Border.all(
                color: Colors.orange.shade300,
              ),

            ),

            child: loading

                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )

                : extractedText.isEmpty

                    ? const Column(

                        children: [

                          Icon(
                            Icons.upload_file,
                            size: 60,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 15),

                          Text(
                            "No document uploaded yet.",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),

                        ],

                      )

                    : Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Row(

                            children: [

                              const Icon(
                                Icons.description,
                                color: Colors.orange,
                                size: 30,
                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                child: Text(

                                  selectedFileName.isEmpty
                                      ? "Manual Notes"
                                      : selectedFileName,

                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 17,
                                  ),

                                ),

                              ),

                            ],

                          ),

                          const Divider(height: 30),

                          Row(

                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [

                              Text(
                                  "Characters : $extractedCharacters"),

                              Text(
                                  "Words : $extractedWords"),

                            ],

                          ),

                          const SizedBox(height: 20),

                          const Text(

                            "Preview",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),

                          ),

                          const SizedBox(height: 10),

                          Container(

                            width: double.infinity,

                            padding:
                                const EdgeInsets.all(12),

                            decoration: BoxDecoration(

                              color: Colors.white,

                              borderRadius:
                                  BorderRadius.circular(
                                      12),

                            ),

                            child: Text(

                              extractedText.length > 400

                                  ? "${extractedText.substring(0,400)}..."

                                  : extractedText,

                              maxLines: 8,

                              overflow:
                                  TextOverflow.fade,

                            ),

                          ),

                        ],

                      ),

          ),

          const SizedBox(height: 30),SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton.icon(
    onPressed: generatingQuiz
        ? null
        : generateQuiz,
    icon: generatingQuiz
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.auto_awesome),
    label: Text(
      generatingQuiz
          ? "Generating AI Quiz..."
          : "Generate AI Quiz",
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),
    ),
  ),
),

const SizedBox(height: 20),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius:
        BorderRadius.circular(15),
  ),
  child: const Row(
    children: [
      Icon(
        Icons.auto_awesome,
        color: Colors.blue,
      ),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          "SparkAI will automatically generate 10 multiple-choice questions and start the quiz.",
          style: TextStyle(fontSize: 15),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 40),

],
),
),
);
}
}