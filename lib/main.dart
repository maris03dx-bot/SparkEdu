import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'config/local_config.dart';
import 'firebase_options.dart';
import 'services/spark_ai_service.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // GEMINI AI
  // ============================================================
  //
  // The API key is stored locally in:
  // lib/config/local_config.dart
  //
  // That file is ignored by Git and will NOT be pushed to GitHub.
  // ============================================================

  if (geminiApiKey.trim().isEmpty ||
      geminiApiKey == 'YOUR_NEW_GEMINI_API_KEY') {
    debugPrint('WARNING: Gemini API key is not configured.');
  } else {
    Gemini.init(
      apiKey: geminiApiKey,
    );

    SparkAIService.initialize(
      apiKey: geminiApiKey,
    );
  }

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // START APP
  // ============================================================

  runApp(const SparkEduApp());
}

class SparkEduApp extends StatelessWidget {
  const SparkEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SparkEdu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}