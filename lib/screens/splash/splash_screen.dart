import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../student/student_navigation.dart';
import '../subject_teacher/subject_teacher_dashboard.dart';
import '../mentor/mentor_dashboard.dart';
import '../associate_dean/associate_dean_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<void> _checkLogin() async {
    // Keep the splash screen visible for 3 seconds
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    // ==========================================================
    // CHECK FIREBASE AUTHENTICATION
    // ==========================================================

    final User? user =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // NO USER LOGGED IN
    // ==========================================================

    if (user == null) {
      _openLogin();

      return;
    }

    // ==========================================================
    // USER IS ALREADY LOGGED IN
    // ==========================================================

    try {
      final QuerySnapshot<Map<String, dynamic>> query =
          await FirebaseFirestore.instance
              .collection("users")
              .where(
                "uid",
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      // ========================================================
      // USER PROFILE NOT FOUND
      // ========================================================

      if (query.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        _showErrorAndOpenLogin(
          "User profile not found.",
        );

        return;
      }

      // ========================================================
      // GET USER ROLE
      // ========================================================

      final Map<String, dynamic> data =
          query.docs.first.data();

      final String role =
          data["role"]?.toString() ?? "";

      // ========================================================
      // OPEN CORRECT DASHBOARD
      // ========================================================

      if (!mounted) return;

      switch (role) {
        // ======================================================
        // STUDENT
        // ======================================================

        case "Student":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const StudentNavigation(),
            ),
          );
          break;

        // ======================================================
        // SUBJECT TEACHER
        // ======================================================

        case "Subject Teacher":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SubjectTeacherDashboard(),
            ),
          );
          break;

        // ======================================================
        // MENTOR
        // ======================================================

        case "Mentor":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const MentorDashboard(),
            ),
          );
          break;

        // ======================================================
        // ASSOCIATE DEAN
        // ======================================================

        case "Associate Dean":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AssociateDeanDashboard(),
            ),
          );
          break;

        // ======================================================
        // INVALID ROLE
        // ======================================================

        default:
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          _showErrorAndOpenLogin(
            "Invalid user role.",
          );
      }
    } catch (e) {
      // ========================================================
      // ERROR
      // ========================================================

      if (!mounted) return;

      _showErrorAndOpenLogin(
        "Unable to load user profile.",
      );
    }
  }

  // ============================================================
  // OPEN LOGIN SCREEN
  // ============================================================

  void _openLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // ERROR + LOGIN
  // ============================================================

  void _showErrorAndOpenLogin(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051A),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ==================================================
            // SPARKEDU LOGO
            // ==================================================

            Image.asset(
              'assets/images/app_logo.png',

              width: 300,
              height: 300,

              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TAGLINE
            // ==================================================

            const Text(
              "Smart Campus Management",

              style: TextStyle(
                color: Colors.white70,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}