import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'firebase_options.dart';
import 'services/spark_ai_service.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // GEMINI API KEY
  // ============================================================
  // Put your NEW Gemini API key here.
  //
  // Example:
  // Gemini.init(
  //   apiKey: "AIzaSy................",
  // );
  //
  // IMPORTANT:
  // Do NOT put the key inside SparkAIService.
  // ============================================================

  const String geminiApiKey = "YOUR_KEY_HERE";

  Gemini.init(
    apiKey: geminiApiKey,
  );

  // Give the same key to our SparkAI HTTP service.
  SparkAIService.initialize(
    apiKey: geminiApiKey,
  );

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