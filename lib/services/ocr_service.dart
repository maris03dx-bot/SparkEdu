import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static Future<String> readText(File image) async {
    final recognizer = TextRecognizer();

    final input = InputImage.fromFile(image);

    final result = await recognizer.processImage(input);

    await recognizer.close();

    return result.text;
  }
}