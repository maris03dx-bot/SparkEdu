import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static Future<String> extractText(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();

      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final PdfTextExtractor extractor = PdfTextExtractor(document);

      final String text = extractor.extractText();

      document.dispose();

      return text;
    } catch (e) {
      return "Error: $e";
    }
  }
}