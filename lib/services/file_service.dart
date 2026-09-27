import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FileService {
  static final ImagePicker _picker = ImagePicker();

  // ============================================================
  // PICK IMAGE
  // ============================================================

  static Future<File?> pickImage() async {
    final XFile? image =
        await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  // ============================================================
  // PICK FILE
  // ============================================================

  static Future<File?> pickFile() async {
    final result = await FilePicker.pickFile();

    if (result == null) {
      return null;
    }

    final path = result.path;

    if (path == null || path.trim().isEmpty) {
      return null;
    }

    return File(path);
  }
}