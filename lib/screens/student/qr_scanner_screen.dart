import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller =
      MobileScannerController();

  bool scanned = false;

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  Future<void> markAttendance(String qrData) async {
    if (scanned) return;

    scanned = true;

    try {
      // ========================================================
      // 1. READ QR DATA
      // ========================================================

      final Map<String, String> values = {};

      for (final item in qrData.split(";")) {
        final pair = item.split("=");

        if (pair.length == 2) {
          values[pair[0].trim()] = pair[1].trim();
        }
      }

      final sessionId = values["sessionId"];

      // MAIN CLASS IDENTIFIER
      final qrClassName = values["className"];

      // COMPATIBILITY FIELDS
      final qrDepartment = values["department"];
      final qrYear = values["year"];
      final qrSection = values["section"];

      final qrSubject = values["subject"];
      final qrTeacher = values["teacher"];
      final qrDate = values["date"];
      final qrTime = values["time"];

      // ========================================================
      // CLASS NAME IS REQUIRED
      // ========================================================

      if (sessionId == null ||
          sessionId.isEmpty ||
          qrClassName == null ||
          qrClassName.isEmpty ||
          qrSubject == null ||
          qrSubject.isEmpty ||
          qrTeacher == null ||
          qrTeacher.isEmpty ||
          qrDate == null ||
          qrDate.isEmpty ||
          qrTime == null ||
          qrTime.isEmpty) {
        throw Exception(
          "Invalid QR Code.",
        );
      }

      // ========================================================
      // 2. CHECK LOGGED-IN USER
      // ========================================================

      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception(
          "User is not logged in.",
        );
      }

      // ========================================================
      // 3. GET STUDENT PROFILE
      // ========================================================

      final userQuery =
          await FirebaseFirestore.instance
              .collection("users")
              .where(
                "uid",
                isEqualTo: currentUser.uid,
              )
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception(
          "Student profile not found.",
        );
      }

      final userData =
          userQuery.docs.first.data();

      // ========================================================
      // VERIFY ACCOUNT ROLE
      // ========================================================

      final accountRole =
          userData["role"]
              ?.toString()
              .trim();

      if (accountRole == null ||
          accountRole.toLowerCase() !=
              "student") {
        throw Exception(
          "Only student accounts can mark attendance.",
        );
      }

      // ========================================================
      // REGISTER NO IS THE STUDENT IDENTIFIER
      // ========================================================

      final studentId =
          userData["registerNo"]
              ?.toString()
              .trim();

      if (studentId == null ||
          studentId.isEmpty) {
        throw Exception(
          "Student Register No not found in profile.",
        );
      }

      final studentName =
          userData["name"]
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
              ? userData["name"]
                  .toString()
                  .trim()
              : currentUser.email ??
                  "Student";

      // ========================================================
      // STUDENT CLASS INFORMATION
      // ========================================================

      final studentClassName =
          userData["className"]
              ?.toString()
              .trim();

      final studentDepartment =
          userData["department"]
                  ?.toString()
                  .trim() ??
              "";

      final studentYear =
          userData["year"]
                  ?.toString()
                  .trim() ??
              "";

      final studentSection =
          userData["section"]
                  ?.toString()
                  .trim() ??
              "";

      // ========================================================
      // 4. VERIFY STUDENT CLASS
      // ========================================================

      if (studentClassName == null ||
          studentClassName.isEmpty) {
        throw Exception(
          "Your student profile does not have a Class Name.",
        );
      }

      if (studentClassName.toUpperCase() !=
          qrClassName.toUpperCase()) {
        throw Exception(
          "This QR is not for your class.\n"
          "Your class: $studentClassName\n"
          "QR class: $qrClassName",
        );
      }

      // ========================================================
      // 5. CHECK ATTENDANCE SESSION
      // ========================================================

      final sessionDoc =
          await FirebaseFirestore.instance
              .collection("attendance_sessions")
              .doc(sessionId)
              .get();

      if (!sessionDoc.exists) {
        throw Exception(
          "Attendance session not found.",
        );
      }

      final sessionData =
          sessionDoc.data();

      if (sessionData == null) {
        throw Exception(
          "Invalid attendance session.",
        );
      }

      final bool active =
          sessionData["active"] == true;

      if (!active) {
        throw Exception(
          "This attendance session is closed.",
        );
      }

      // ========================================================
      // 6. VERIFY SESSION CLASS
      // ========================================================

      final storedClassName =
          sessionData["className"]
              ?.toString()
              .trim();

      if (storedClassName == null ||
          storedClassName.isEmpty) {
        throw Exception(
          "This attendance session does not have a Class Name.",
        );
      }

      if (storedClassName.toUpperCase() !=
          qrClassName.toUpperCase()) {
        throw Exception(
          "Invalid Class Name in QR Code.",
        );
      }

      // ========================================================
      // 7. VERIFY QR DETAILS AGAINST FIRESTORE SESSION
      // ========================================================
      //
      // QR text should not be trusted by itself.
      // The actual Firestore session is authoritative.
      //
      // ========================================================

      final storedSubject =
          sessionData["subject"]
              ?.toString()
              .trim();

      if (storedSubject == null ||
          storedSubject.isEmpty) {
        throw Exception(
          "This attendance session does not have a subject.",
        );
      }

      if (storedSubject.toUpperCase() !=
          qrSubject.toUpperCase()) {
        throw Exception(
          "Invalid subject information in QR Code.",
        );
      }

      final storedDepartment =
          sessionData["department"]
              ?.toString()
              .trim();

      if (qrDepartment != null &&
          qrDepartment.isNotEmpty &&
          storedDepartment != null &&
          storedDepartment.isNotEmpty &&
          storedDepartment.toUpperCase() !=
              qrDepartment.toUpperCase()) {
        throw Exception(
          "Invalid department information in QR Code.",
        );
      }

      final storedYear =
          sessionData["year"]
              ?.toString()
              .trim();

      if (qrYear != null &&
          qrYear.isNotEmpty &&
          storedYear != null &&
          storedYear.isNotEmpty &&
          storedYear.toUpperCase() !=
              qrYear.toUpperCase()) {
        throw Exception(
          "Invalid year information in QR Code.",
        );
      }

      final storedSection =
          sessionData["section"]
              ?.toString()
              .trim();

      if (qrSection != null &&
          qrSection.isNotEmpty &&
          storedSection != null &&
          storedSection.isNotEmpty &&
          storedSection.toUpperCase() !=
              qrSection.toUpperCase()) {
        throw Exception(
          "Invalid section information in QR Code.",
        );
      }

      // ========================================================
      // 8. VERIFY STUDENT AGAINST QR OLD FIELDS
      // ========================================================
      //
      // Class Name remains the PRIMARY check.
      //
      // These fields provide an additional safety layer.
      //
      // ========================================================

      if (qrDepartment != null &&
          qrDepartment.isNotEmpty &&
          studentDepartment.isNotEmpty &&
          studentDepartment.toUpperCase() !=
              qrDepartment.toUpperCase()) {
        throw Exception(
          "This QR is not for your department.\n"
          "Your department: $studentDepartment\n"
          "QR department: $qrDepartment",
        );
      }

      if (qrYear != null &&
          qrYear.isNotEmpty &&
          studentYear.isNotEmpty &&
          studentYear.toUpperCase() !=
              qrYear.toUpperCase()) {
        throw Exception(
          "This QR is not for your year.\n"
          "Your year: $studentYear\n"
          "QR year: $qrYear",
        );
      }

      if (qrSection != null &&
          qrSection.isNotEmpty &&
          studentSection.isNotEmpty &&
          studentSection.toUpperCase() !=
              qrSection.toUpperCase()) {
        throw Exception(
          "This QR is not for your section.\n"
          "Your section: $studentSection\n"
          "QR section: $qrSection",
        );
      }

      // ========================================================
      // 9. CREATE UNIQUE ATTENDANCE ID
      // ========================================================

      final attendanceId =
          "${studentId}_$sessionId";

      final attendanceRef =
          FirebaseFirestore.instance
              .collection("attendance")
              .doc(attendanceId);

      // ========================================================
      // 10. CHECK DUPLICATE ATTENDANCE
      // ========================================================

      final alreadyMarked =
          await attendanceRef.get();

      if (alreadyMarked.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Attendance already marked.",
            ),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.pop(context);
        return;
      }

      // ========================================================
      // 11. SAVE ATTENDANCE
      // ========================================================

      await attendanceRef.set({
        "attendanceId":
            attendanceId,

        "sessionId":
            sessionId,

        // STUDENT INFORMATION
        "studentId":
            studentId,

        "studentName":
            studentName,

        "studentUid":
            currentUser.uid,

        // MAIN CLASS FIELD
        "className":
            studentClassName,

        // COMPATIBILITY FIELDS
        "department":
            studentDepartment,

        "year":
            studentYear,

        "section":
            studentSection,

        // ATTENDANCE INFORMATION
        "subject":
            storedSubject,

        "teacher":
            sessionData["teacher"]
                ?.toString()
                .trim() ??
            qrTeacher,

        "date":
            sessionData["date"]
                ?.toString()
                .trim() ??
            qrDate,

        "time":
            sessionData["time"]
                ?.toString()
                .trim() ??
            qrTime,

        "status":
            "Present",

        "createdAt":
            Timestamp.now(),
      });

      // ========================================================
      // 12. SUCCESS
      // ========================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance Marked Successfully ✅",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      scanned = false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(
            seconds: 4,
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
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height;

    final bool isSmallScreen =
        screenHeight < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Attendance QR",
        ),
        backgroundColor:
            Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.flash_on,
            ),
            onPressed: () {
              controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cameraswitch,
            ),
            onPressed: () {
              controller.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ======================================================
          // CAMERA
          // ======================================================

          Expanded(
            flex:
                isSmallScreen ? 5 : 4,
            child: MobileScanner(
              controller:
                  controller,
              onDetect:
                  (capture) {
                if (scanned) return;

                if (capture
                    .barcodes
                    .isEmpty) {
                  return;
                }

                final code =
                    capture
                        .barcodes
                        .first
                        .rawValue;

                if (code != null &&
                    code.isNotEmpty) {
                  markAttendance(
                    code,
                  );
                }
              },
            ),
          ),

          // ======================================================
          // INFORMATION
          // ======================================================

          Expanded(
            flex:
                isSmallScreen ? 2 : 1,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Icon(
                    Icons
                        .qr_code_scanner,
                    size:
                        isSmallScreen
                            ? 45
                            : 60,
                    color:
                        Colors.blue,
                  ),
                  SizedBox(
                    height:
                        isSmallScreen
                            ? 8
                            : 15,
                  ),
                  Text(
                    "Scan the teacher's Attendance QR",
                    textAlign:
                        TextAlign
                            .center,
                    style:
                        TextStyle(
                      fontSize:
                          isSmallScreen
                              ? 16
                              : 18,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  SizedBox(
                    height:
                        isSmallScreen
                            ? 6
                            : 10,
                  ),
                  const Text(
                    "Attendance will be recorded automatically.",
                    textAlign:
                        TextAlign
                            .center,
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                      fontSize:
                          14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}