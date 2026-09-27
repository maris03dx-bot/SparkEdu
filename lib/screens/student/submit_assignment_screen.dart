import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const SubmitAssignmentScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<SubmitAssignmentScreen> createState() =>
      _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState
    extends State<SubmitAssignmentScreen> {
  File? selectedPdf;
  String? selectedPdfName;

  bool isUploading = false;

  // ============================================================
  // GET STUDENT DATA
  // ============================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final query = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  // ============================================================
  // PICK PDF
  // ============================================================

  Future<void> pickPDF() async {
    if (isUploading) {
      return;
    }

    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) {
        return;
      }

      final path = result.path;

      if (path == null || path.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to access the selected PDF.",
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        selectedPdf = File(path);
        selectedPdfName = result.name;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to select PDF: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UPLOAD PDF
  // ============================================================

  Future<String> uploadPDF() async {
    if (selectedPdf == null) {
      throw Exception("No PDF selected.");
    }

    final fileName = const Uuid().v4();

    final ref = FirebaseStorage.instance
        .ref()
        .child("assignment_submissions")
        .child("$fileName.pdf");

    await ref.putFile(selectedPdf!);

    return await ref.getDownloadURL();
  }

  // ============================================================
  // SUBMIT ASSIGNMENT
  // ============================================================

  Future<void> submitAssignment() async {
    if (selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a PDF",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isUploading) {
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // ----------------------------------------------------------
      // CURRENT USER
      // ----------------------------------------------------------

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          "Student is not logged in.",
        );
      }

      // ----------------------------------------------------------
      // STUDENT PROFILE
      // ----------------------------------------------------------

      final studentData = await getStudentData();

      if (studentData == null) {
        throw Exception(
          "Student profile not found.",
        );
      }

      // ----------------------------------------------------------
      // REGISTER NUMBER
      // ----------------------------------------------------------

      final String registerNo =
          studentData["registerNo"]?.toString().trim() ?? "";

      if (registerNo.isEmpty) {
        throw Exception(
          "Student Register No not found.",
        );
      }

      // ----------------------------------------------------------
      // CLASS INFORMATION
      // ----------------------------------------------------------

      final String className =
          studentData["className"]?.toString().trim() ?? "";

      final String department =
          studentData["department"]?.toString().trim() ?? "";

      final String year =
          studentData["year"]?.toString().trim() ?? "";

      final String section =
          studentData["section"]?.toString().trim() ?? "";

      // ----------------------------------------------------------
      // REAL STUDENT NAME
      // ----------------------------------------------------------

      final String studentName =
          studentData["name"]?.toString().trim().isNotEmpty == true
              ? studentData["name"].toString().trim()
              : "Student";

      // ----------------------------------------------------------
      // CHECK DUPLICATE SUBMISSION
      // ----------------------------------------------------------

      final existingSubmission =
          await FirebaseFirestore.instance
              .collection(
                "assignment_submissions",
              )
              .where(
                "assignmentId",
                isEqualTo: widget.assignmentId,
              )
              .where(
                "studentId",
                isEqualTo: registerNo,
              )
              .limit(1)
              .get();

      if (existingSubmission.docs.isNotEmpty) {
        throw Exception(
          "You have already submitted this assignment.",
        );
      }

      // ----------------------------------------------------------
      // UPLOAD PDF
      // ----------------------------------------------------------

      final pdfUrl = await uploadPDF();

      // ----------------------------------------------------------
      // SAVE SUBMISSION
      // ----------------------------------------------------------

      await FirebaseFirestore.instance
          .collection(
            "assignment_submissions",
          )
          .add({
        // Assignment
        "assignmentId": widget.assignmentId,
        "assignmentTitle": widget.assignmentTitle,

        // Student identity
        // Register No is the student-facing identifier.
        "studentId": registerNo,
        "studentRegisterNo": registerNo,
        "studentName": studentName,

        // Internal Firebase identity
        // Kept for secure internal linking only.
        "studentUid": user.uid,

        "studentEmail": user.email,

        // Class information
        "className": className,
        "department": department,
        "year": year,
        "section": section,

        // PDF
        "pdfUrl": pdfUrl,
        "pdfName": selectedPdfName,

        // Submission information
        "submittedAt": Timestamp.now(),

        // Teacher evaluation
        "marks": null,
        "remarks": "",
        "status": "Submitted",
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Assignment Submitted Successfully ✅",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

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
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final double titleSize =
        screenWidth < 360 ? 17 : 19;

    final double bodySize =
        screenWidth < 360 ? 13 : 14;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Submit Assignment",
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            Colors.indigo,
                        child: Icon(
                          Icons.assignment,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.assignmentTitle,
                              softWrap: true,
                              style: TextStyle(
                                fontSize:
                                    titleSize,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Upload your assignment as a PDF",
                              softWrap: true,
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    bodySize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Card(
                elevation: 3,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 30,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              "Assignment PDF",
                              style:
                                  TextStyle(
                                fontSize:
                                    titleSize,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey
                                  .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border:
                              Border.all(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color:
                                  Colors.red,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                selectedPdfName ??
                                    "No PDF Selected",
                                softWrap:
                                    true,
                                maxLines: 3,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  fontSize:
                                      bodySize,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              isUploading
                                  ? null
                                  : pickPDF,
                          icon:
                              const Icon(
                            Icons.folder_open,
                          ),
                          label:
                              const Text(
                            "Choose PDF",
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 55,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isUploading
                          ? null
                          : submitAssignment,
                  icon: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.upload_file,
                        ),
                  label: Text(
                    isUploading
                        ? "Uploading..."
                        : "Submit Assignment",
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.indigo,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              if (selectedPdfName != null)
                Center(
                  child: Text(
                    "Only PDF files are accepted.",
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize:
                          bodySize,
                    ),
                  ),
                ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}