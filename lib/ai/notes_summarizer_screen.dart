import 'dart:io';

import 'package:flutter/material.dart';

import '../services/file_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/summary_ai_service.dart';

class NotesSummarizerScreen extends StatefulWidget {
  const NotesSummarizerScreen({super.key});

  @override
  State<NotesSummarizerScreen> createState() =>
      _NotesSummarizerScreenState();
}

class _NotesSummarizerScreenState
    extends State<NotesSummarizerScreen> {

  final TextEditingController notesController =
      TextEditingController();

  bool loading = false;
  bool generatingSummary = false;

  String extractedText = "";
  String summary = "";

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

      extractedCharacters = text.length;

      extractedWords =
          text.trim().isEmpty
              ? 0
              : text.trim().split(RegExp(r"\s+")).length;

      loading = false;

    });

  }

  Future<void> generateSummary() async {

    if (notesController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please upload notes first.",
          ),
        ),
      );

      return;

    }

    setState(() {
      generatingSummary = true;
    });

    final result =
        await SummaryAIService.summarize(
      notesController.text,
    );

    setState(() {
      summary = result;
      generatingSummary = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("📄 AI Notes Summarizer"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Choose Input Method",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_note),
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
                hintText: "Paste your notes here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green),
              ),
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : extractedText.isEmpty
                      ? const Text(
                          "No document selected.",
                          style: TextStyle(fontSize: 16),
                        )
                      : Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedFileName.isEmpty
                                        ? "Manual Notes"
                                        : selectedFileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 30),

                            Text(
                              "Characters : $extractedCharacters",
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Words : $extractedWords",
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Preview",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              extractedText.length > 400
                                  ? "${extractedText.substring(0, 400)}..."
                                  : extractedText,
                            ),

                          ],
                        ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: generatingSummary
                    ? null
                    : generateSummary,
                icon: generatingSummary
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
                  generatingSummary
                      ? "Generating..."
                      : "Generate AI Summary",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (summary.isNotEmpty) ...[

              const Text(
                "📚 AI Summary",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.green,
                  ),
                ),
                child: SelectableText(
                  summary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

            ],

            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}