import 'dart:io';

import 'package:flutter/material.dart';

import '../services/file_service.dart';
import '../services/pdf_service.dart';

class DocumentChatScreen extends StatefulWidget {
  const DocumentChatScreen({super.key});

  @override
  State<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends State<DocumentChatScreen> {
  File? selectedFile;

  String extractedText = "";

  final TextEditingController questionController =
      TextEditingController();

  Future<void> pickPdf() async {
    final file = await FileService.pickFile();

    if (file == null) return;

    setState(() {
      selectedFile = file;
    });

    extractedText =
        await PdfService.extractText(file);

    setState(() {});
  }

  Future<void> pickImage() async {
    final image = await FileService.pickImage();

    if (image == null) return;

    setState(() {
      selectedFile = image;
    });

    // OCR will be added next.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📄 Document Chat"),
        backgroundColor: Colors.blue,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Upload PDF"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Upload Image"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (selectedFile != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(
                    selectedFile!.path.split("/").last,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  extractedText.isEmpty
                      ? "Upload a PDF to extract its text."
                      : extractedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}