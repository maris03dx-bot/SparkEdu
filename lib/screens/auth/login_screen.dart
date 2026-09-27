import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../student/student_navigation.dart';
import '../subject_teacher/subject_teacher_dashboard.dart';
import '../mentor/mentor_dashboard.dart';
import '../associate_dean/associate_dean_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String selectedRole = "Student";

  bool obscurePassword = true;
  bool isLoading = false;
  bool isResettingPassword = false;

  // ============================================================
  // ROLES
  // ============================================================

  final List<String> roles = [
    "Student",
    "Subject Teacher",
    "Mentor",
    "Associate Dean",
  ];

  // ============================================================
  // GET STUDENT EMAIL USING REGISTER NUMBER
  // ============================================================

  Future<String?> getStudentEmailByRegisterNo(
    String registerNo,
  ) async {
    final String cleanedRegisterNo = registerNo.trim();

    if (cleanedRegisterNo.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await FirebaseFirestore.instance
            .collection("login_identifiers")
            .doc(cleanedRegisterNo)
            .get();

    if (!document.exists) {
      return null;
    }

    final Map<String, dynamic>? data = document.data();

    if (data == null) {
      return null;
    }

    final String role =
        (data["role"] ?? "").toString().trim();

    if (role != "Student") {
      return null;
    }

    final String email =
        (data["email"] ?? "").toString().trim();

    if (email.isEmpty) {
      return null;
    }

    return email;
  }

  // ============================================================
  // GET USER FIRESTORE PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getUserProfile(
    String uid,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> query =
        await FirebaseFirestore.instance
            .collection("users")
            .where(
              "uid",
              isEqualTo: uid,
            )
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  // ============================================================
  // CHECK WHETHER PASSWORD CHANGE IS REQUIRED
  // ============================================================

  bool mustChangePassword(
    Map<String, dynamic> data,
  ) {
    return data["mustChangePassword"] == true;
  }

  // ============================================================
  // SEND PASSWORD RESET EMAIL
  // ============================================================

  Future<void> sendPasswordReset() async {
    final String loginValue =
        emailController.text.trim();

    if (loginValue.isEmpty) {
      showMessage(
        selectedRole == "Student"
            ? "Please enter your email or register number first."
            : "Please enter your email first.",
      );

      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      String resetEmail = loginValue;

      // ========================================================
      // STUDENT
      // ========================================================

      if (selectedRole == "Student") {
        final bool looksLikeEmail =
            loginValue.contains("@");

        if (!looksLikeEmail) {
          final String? studentEmail =
              await getStudentEmailByRegisterNo(
            loginValue,
          );

          if (studentEmail == null) {
            throw Exception(
              "No student account found with register number $loginValue.",
            );
          }

          resetEmail = studentEmail;
        }
      }

      // ========================================================
      // FIREBASE PASSWORD RESET
      // ========================================================

      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: resetEmail,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          content: Text(
            "Password reset email sent to $resetEmail.",
          ),
        ),
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERRORS
    // ==========================================================

    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "user-not-found":
          message =
              "No account was found with this email.";
          break;

        case "invalid-email":
          message =
              "The email address is invalid.";
          break;

        case "network-request-failed":
          message =
              "Network error. Please check your internet connection.";
          break;

        case "too-many-requests":
          message =
              "Too many reset requests. Please try again later.";
          break;

        default:
          message =
              e.message ??
              "Could not send password reset email.";
      }

      if (!mounted) return;

      showMessage(message);
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }

    // ==========================================================
    // STOP RESET LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW FORGOT PASSWORD DIALOG
  // ============================================================

  void showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: !isResettingPassword,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_reset,
                color: Color(0xFF6B4FD3),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Forgot Password?",
                ),
              ),
            ],
          ),
          content: Text(
            selectedRole == "Student"
                ? "Enter your Email or Register Number. "
                    "SparkEdu will send a password reset link to your registered email."
                : "Enter your registered email address. "
                    "SparkEdu will send a password reset link.",
          ),
          actions: [
            TextButton(
              onPressed: isResettingPassword
                  ? null
                  : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
              child: const Text(
                "CANCEL",
              ),
            ),
            ElevatedButton(
              onPressed: isResettingPassword
                  ? null
                  : () {
                      Navigator.pop(
                        dialogContext,
                      );
                      sendPasswordReset();
                    },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6B4FD3),
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                "SEND RESET LINK",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final String loginValue =
        emailController.text.trim();

    final String password =
        passwordController.text.trim();

    // ----------------------------------------------------------
    // CHECK EMPTY FIELDS
    // ----------------------------------------------------------

    if (loginValue.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            selectedRole == "Student"
                ? "Please enter email/register number and password."
                : "Please enter email and password.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String loginEmail = loginValue;

      // ========================================================
      // STUDENT LOGIN
      // ========================================================

      if (selectedRole == "Student") {
        final bool looksLikeEmail =
            loginValue.contains("@");

        if (!looksLikeEmail) {
          final String? studentEmail =
              await getStudentEmailByRegisterNo(
            loginValue,
          );

          if (studentEmail == null) {
            throw Exception(
              "No student account found with register number $loginValue.",
            );
          }

          loginEmail = studentEmail;
        }
      }

      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          "User not found.",
        );
      }

      // ========================================================
      // GET USER DATA FROM FIRESTORE
      // ========================================================

      final Map<String, dynamic>? data =
          await getUserProfile(
        user.uid,
      );

      if (data == null) {
        await FirebaseAuth.instance.signOut();

        throw Exception(
          "User profile not found in Firestore.",
        );
      }

      final String role =
          (data["role"] ?? "").toString().trim();

      // ========================================================
      // CHECK SELECTED ROLE
      // ========================================================

      if (role != selectedRole) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Please select the correct role ($role).",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // FIRST-LOGIN PASSWORD CHANGE
      // ========================================================
      //
      // IMPORTANT:
      // This now works for ALL roles:
      //
      // Student
      // Subject Teacher
      // Mentor
      // Associate Dean
      //
      // Previously this was restricted to Student only.
      // ========================================================

      if (mustChangePassword(data)) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChangeTemporaryPasswordScreen(
              role: role,
            ),
          ),
        );

        return;
      }

      // ========================================================
      // NORMAL NAVIGATION
      // ========================================================

      if (!mounted) return;

      navigateByRole(role);
    }

    // ==========================================================
    // FIREBASE LOGIN ERRORS
    // ==========================================================

    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "user-not-found":
          message =
              "No account found with this email.";
          break;

        case "wrong-password":
          message =
              "Incorrect password.";
          break;

        case "invalid-email":
          message =
              "Invalid email address.";
          break;

        case "invalid-credential":
          message =
              "Invalid email/register number or password.";
          break;

        case "too-many-requests":
          message =
              "Too many login attempts. Try again later.";
          break;

        case "network-request-failed":
          message =
              "Network error. Please check your internet connection.";
          break;

        default:
          message =
              e.message ?? "Login failed.";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message),
        ),
      );
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // NAVIGATE BASED ON ROLE
  // ============================================================

  void navigateByRole(String role) {
    switch (role) {
      case "Student":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StudentNavigation(),
          ),
        );
        break;

      case "Subject Teacher":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SubjectTeacherDashboard(),
          ),
        );
        break;

      case "Mentor":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MentorDashboard(),
          ),
        );
        break;

      case "Associate Dean":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AssociateDeanDashboard(),
          ),
        );
        break;

      default:
        FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Invalid role found.",
            ),
          ),
        );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD LOGIN PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isStudent =
        selectedRole == "Student";

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F5FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Column(
              children: [
                // ==================================================
                // SPARKEDU LOGO
                // ==================================================

                SizedBox(
                  width: 145,
                  height: 145,
                  child: Image.asset(
                    "assets/images/sparkedu_design.png",
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        size: 100,
                        color:
                            Color(0xFF6B4FD3),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 5),

                // ==================================================
                // SPARKEDU NAME
                // ==================================================

                const Text(
                  "SparkEdu",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF17152B),
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // TAGLINE
                // ==================================================

                const Text(
                  "LEARN • GROW • INSPIRE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2.2,
                    color:
                        Color(0xFF6B4FD3),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // EMAIL / REGISTER NUMBER
                // ==================================================

                TextField(
                  controller:
                      emailController,
                  keyboardType: isStudent
                      ? TextInputType.text
                      : TextInputType.emailAddress,
                  decoration:
                      InputDecoration(
                    labelText: isStudent
                        ? "Email / Register No"
                        : "Email",
                    hintText: isStudent
                        ? "Enter email or register number"
                        : "Enter your email",
                    prefixIcon:
                        const Icon(
                      Icons.badge_outlined,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF6B4FD3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // PASSWORD
                // ==================================================

                TextField(
                  controller:
                      passwordController,
                  obscureText:
                      obscurePassword,
                  decoration:
                      InputDecoration(
                    labelText: "Password",
                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                        IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF6B4FD3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // FORGOT PASSWORD
                // ==================================================

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        isLoading ||
                                isResettingPassword
                            ? null
                            : showForgotPasswordDialog,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color:
                            Color(0xFF6B4FD3),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // ROLE DROPDOWN
                // ==================================================

                DropdownButtonFormField<String>(
                  initialValue:
                      selectedRole,
                  decoration:
                      InputDecoration(
                    labelText:
                        "Select Role",
                    prefixIcon:
                        const Icon(
                      Icons.person_outline,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF6B4FD3),
                        width: 2,
                      ),
                    ),
                  ),
                  items: roles.map(
                    (String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    },
                  ).toList(),
                  onChanged:
                      isLoading ||
                              isResettingPassword
                          ? null
                          : (String? value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setState(() {
                                selectedRole =
                                    value;
                              });
                            },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 58,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLoading ||
                                isResettingPassword
                            ? null
                            : login,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6B4FD3,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 3,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Text(
                            "LOGIN",
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing:
                                  1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// CHANGE TEMPORARY PASSWORD SCREEN
// ==================================================================

class ChangeTemporaryPasswordScreen
    extends StatefulWidget {
  final String role;

  const ChangeTemporaryPasswordScreen({
    super.key,
    required this.role,
  });

  @override
  State<ChangeTemporaryPasswordScreen>
      createState() =>
          _ChangeTemporaryPasswordScreenState();
}

class _ChangeTemporaryPasswordScreenState
    extends State<ChangeTemporaryPasswordScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController
      newPasswordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> changePassword() async {
    final String newPassword =
        newPasswordController.text.trim();

    final String confirmPassword =
        confirmPasswordController.text.trim();

    // ----------------------------------------------------------
    // EMPTY CHECK
    // ----------------------------------------------------------

    if (newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        "Please enter and confirm your new password.",
      );

      return;
    }

    // ----------------------------------------------------------
    // MINIMUM PASSWORD LENGTH
    // ----------------------------------------------------------

    if (newPassword.length < 8) {
      showMessage(
        "Your new password must contain at least 8 characters.",
      );

      return;
    }

    // ----------------------------------------------------------
    // PASSWORD MATCH
    // ----------------------------------------------------------

    if (newPassword != confirmPassword) {
      showMessage(
        "The passwords do not match.",
      );

      return;
    }

    // ----------------------------------------------------------
    // GET CURRENT USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        "Your login session has expired. Please login again.",
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // UPDATE FIREBASE AUTH PASSWORD
      // ========================================================

      await user.updatePassword(
        newPassword,
      );

      // ========================================================
      // UPDATE FIRESTORE PASSWORD STATUS
      // ========================================================

      await FirebaseFirestore.instance
          .collection("users")
          .where(
            "uid",
            isEqualTo: user.uid,
          )
          .limit(1)
          .get()
          .then(
        (QuerySnapshot<Map<String, dynamic>> query) async {
          if (query.docs.isEmpty) {
            throw Exception(
              "User profile not found.",
            );
          }

          await query.docs.first.reference.set(
            {
              "mustChangePassword": false,
              "passwordStatus": "active",
              "passwordChangedAt":
                  FieldValue.serverTimestamp(),
              "updatedAt":
                  FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        },
      );

      if (!mounted) return;

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Password changed successfully.",
          ),
        ),
      );

      // ========================================================
      // NAVIGATE TO CORRECT ROLE DASHBOARD
      // ========================================================

      switch (widget.role) {
        case "Student":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const StudentNavigation(),
            ),
          );
          break;

        case "Subject Teacher":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SubjectTeacherDashboard(),
            ),
          );
          break;

        case "Mentor":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const MentorDashboard(),
            ),
          );
          break;

        case "Associate Dean":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AssociateDeanDashboard(),
            ),
          );
          break;

        default:
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const LoginScreen(),
            ),
          );
      }
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "weak-password":
          message =
              "This password is too weak. Please use a stronger password.";
          break;

        case "requires-recent-login":
          message =
              "For security, please login again and change the password.";
          break;

        case "network-request-failed":
          message =
              "Network error. Please check your internet connection.";
          break;

        default:
          message =
              e.message ??
              "Could not change the password.";
      }

      if (!mounted) return;

      showMessage(message);
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF7F5FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 30,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // ICON
                  // ==================================================

                  Container(
                    width: 90,
                    height: 90,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF6B4FD3,
                      ).withValues(
                        alpha: 0.12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.lock_reset,
                      size: 48,
                      color:
                          Color(0xFF6B4FD3),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    "Create New Password",
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF17152B),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  const Text(
                    "You are using a temporary password.\n"
                    "Please create a new password before continuing.",
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ==================================================
                  // NEW PASSWORD
                  // ==================================================

                  TextField(
                    controller:
                        newPasswordController,
                    obscureText:
                        obscureNewPassword,
                    enabled:
                        !isLoading,
                    decoration:
                        InputDecoration(
                      labelText:
                          "New Password",
                      hintText:
                          "Enter your new password",
                      prefixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                    setState(() {
                                      obscureNewPassword =
                                          !obscureNewPassword;
                                    });
                                  },
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFF6B4FD3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // CONFIRM PASSWORD
                  // ==================================================

                  TextField(
                    controller:
                        confirmPasswordController,
                    obscureText:
                        obscureConfirmPassword,
                    enabled:
                        !isLoading,
                    decoration:
                        InputDecoration(
                      labelText:
                          "Confirm New Password",
                      hintText:
                          "Re-enter your new password",
                      prefixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                    setState(() {
                                      obscureConfirmPassword =
                                          !obscureConfirmPassword;
                                    });
                                  },
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFF6B4FD3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // PASSWORD REQUIREMENT
                  // ==================================================

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      "Password must contain at least 8 characters.",
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ==================================================
                  // CHANGE PASSWORD BUTTON
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 58,
                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : changePassword,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF6B4FD3,
                        ),
                        foregroundColor:
                            Colors.white,
                        elevation: 3,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              "CHANGE PASSWORD",
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing:
                                    0.8,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // SECURITY MESSAGE
                  // ==================================================

                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        size: 17,
                        color:
                            Colors.black45,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Your new password will be securely stored by Firebase.",
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
