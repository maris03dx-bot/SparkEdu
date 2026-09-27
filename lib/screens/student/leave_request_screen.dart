import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() =>
      _LeaveRequestScreenState();
}

class _LeaveRequestScreenState
    extends State<LeaveRequestScreen> {
  final TextEditingController reasonController =
      TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  bool isLoading = false;

  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  // ==========================================================
  // GET CURRENT STUDENT PROFILE
  // ==========================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    // Your users collection uses Auto-ID documents.
    // Firebase Auth UID is stored in the "uid" field.
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

  // ==========================================================
  // PICK FROM DATE
  // ==========================================================

  Future<void> pickFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        fromDate = date;

        if (toDate != null &&
            toDate!.isBefore(date)) {
          toDate = null;
        }
      });
    }
  }

  // ==========================================================
  // PICK TO DATE
  // ==========================================================

  Future<void> pickToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          fromDate ?? DateTime.now(),
      firstDate:
          fromDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        toDate = date;
      });
    }
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  Future<void> pickCameraImage() async {
    if (isLoading) {
      return;
    }

    final XFile? image =
        await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (image != null && mounted) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // ==========================================================
  // GALLERY
  // ==========================================================

  Future<void> pickGalleryImage() async {
    if (isLoading) {
      return;
    }

    final XFile? image =
        await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image != null && mounted) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // ==========================================================
  // UPLOAD IMAGE
  // ==========================================================

  Future<String?> uploadImage() async {
    if (selectedImage == null) {
      return null;
    }

    final fileName =
        const Uuid().v4();

    final ref =
        FirebaseStorage.instance
            .ref()
            .child("leave_letters")
            .child("$fileName.jpg");

    await ref.putFile(
      selectedImage!,
    );

    return await ref.getDownloadURL();
  }

  // ==========================================================
  // SUBMIT LEAVE
  // ==========================================================

  Future<void> submitLeave() async {
    // ========================================================
    // VALIDATE FORM
    // ========================================================

    if (fromDate == null ||
        toDate == null ||
        reasonController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please complete all fields",
          ),
        ),
      );

      return;
    }

    // ========================================================
    // CURRENT USER
    // ========================================================

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "User is not logged in",
          ),
        ),
      );

      return;
    }

    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ======================================================
      // GET STUDENT PROFILE
      // ======================================================

      final studentData =
          await getStudentData();

      if (studentData == null) {
        throw Exception(
          "Student profile not found.",
        );
      }

      // ======================================================
      // REAL STUDENT NAME
      //
      // Firestore "name" is the source of truth.
      // ======================================================

      final String studentName =
          studentData["name"]
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? studentData["name"]
                  .toString()
                  .trim()
              : "Student";

      // ======================================================
      // REGISTER NUMBER
      //
      // Use registerNo as the preferred student identifier.
      // ======================================================

      final String registerNo =
          studentData["registerNo"]
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? studentData["registerNo"]
                  .toString()
                  .trim()
              : studentData["rollNo"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? studentData["rollNo"]
                      .toString()
                      .trim()
                  : "";

      // ======================================================
      // UPLOAD IMAGE
      // ======================================================

      String? imageUrl;

      if (selectedImage != null) {
        imageUrl =
            await uploadImage();
      }

      // ======================================================
      // SAVE LEAVE REQUEST
      // ======================================================

      await FirebaseFirestore.instance
          .collection("leave_requests")
          .add({
        // ----------------------------------------------------
        // STUDENT INFORMATION
        // ----------------------------------------------------

        // Firebase UID kept internally for identifying
        // the logged-in student.
        "studentId": user.uid,

        // Real Firestore name.
        "studentName": studentName,

        // Register number.
        "registerNo": registerNo,

        // ----------------------------------------------------
        // LEAVE DETAILS
        // ----------------------------------------------------

        "fromDate":
            Timestamp.fromDate(
          fromDate!,
        ),

        "toDate":
            Timestamp.fromDate(
          toDate!,
        ),

        "reason":
            reasonController.text.trim(),

        // ----------------------------------------------------
        // STATUS
        // ----------------------------------------------------

        "status": "Pending",

        // ----------------------------------------------------
        // TIME
        // ----------------------------------------------------

        "createdAt":
            FieldValue.serverTimestamp(),

        // ----------------------------------------------------
        // OPTIONAL LETTER
        // ----------------------------------------------------

        "letterImage": imageUrl,
      });

      if (!mounted) {
        return;
      }

      // ======================================================
      // CLEAR FORM
      // ======================================================

      reasonController.clear();

      setState(() {
        isLoading = false;
        fromDate = null;
        toDate = null;
        selectedImage = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Leave request submitted successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to submit leave request:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Leave Request"),
        backgroundColor:
            Colors.blue,
        centerTitle: true,
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child:
            Column(
          children: [
            // ==================================================
            // FROM DATE
            // ==================================================

            Card(
              child:
                  ListTile(
                leading:
                    const Icon(
                  Icons.calendar_today,
                  color:
                      Colors.blue,
                ),
                title:
                    Text(
                  fromDate == null
                      ? "Select From Date"
                      : "${fromDate!.day}/"
                          "${fromDate!.month}/"
                          "${fromDate!.year}",
                ),
                trailing:
                    ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : pickFromDate,
                  child:
                      const Text(
                    "Choose",
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // TO DATE
            // ==================================================

            Card(
              child:
                  ListTile(
                leading:
                    const Icon(
                  Icons.event,
                  color:
                      Colors.blue,
                ),
                title:
                    Text(
                  toDate == null
                      ? "Select To Date"
                      : "${toDate!.day}/"
                          "${toDate!.month}/"
                          "${toDate!.year}",
                ),
                trailing:
                    ElevatedButton(
                  onPressed:
                      fromDate == null ||
                              isLoading
                          ? null
                          : pickToDate,
                  child:
                      const Text(
                    "Choose",
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // REASON
            // ==================================================

            TextField(
              controller:
                  reasonController,
              enabled:
                  !isLoading,
              maxLines: 5,
              decoration:
                  InputDecoration(
                labelText:
                    "Reason",
                hintText:
                    "Enter your leave reason",
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                prefixIcon:
                    const Icon(
                  Icons.description,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // UPLOAD TITLE
            // ==================================================

            const Align(
              alignment:
                  Alignment.centerLeft,
              child:
                  Text(
                "Upload Leave Letter (Optional)",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize:
                      16,
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // CAMERA + GALLERY
            // ==================================================

            LayoutBuilder(
              builder:
                  (
                context,
                constraints,
              ) {
                final isSmallScreen =
                    constraints.maxWidth <
                        360;

                if (isSmallScreen) {
                  return Column(
                    children: [
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              isLoading
                                  ? null
                                  : pickCameraImage,
                          icon:
                              const Icon(
                            Icons.camera_alt,
                          ),
                          label:
                              const Text(
                            "Camera",
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              isLoading
                                  ? null
                                  : pickGalleryImage,
                          icon:
                              const Icon(
                            Icons.photo,
                          ),
                          label:
                              const Text(
                            "Gallery",
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : pickCameraImage,
                        icon:
                            const Icon(
                          Icons.camera_alt,
                        ),
                        label:
                            const Text(
                          "Camera",
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : pickGalleryImage,
                        icon:
                            const Icon(
                          Icons.photo,
                        ),
                        label:
                            const Text(
                          "Gallery",
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // IMAGE PREVIEW
            // ==================================================

            if (selectedImage != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child:
                    Image.file(
                  selectedImage!,
                  height: 220,
                  width:
                      double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // SUBMIT BUTTON
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              height: 55,

              child:
                  ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : submitLeave,

                icon:
                    isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                          ),

                label:
                    Text(
                  isLoading
                      ? "Submitting..."
                      : "Submit Leave Request",
                  style:
                      const TextStyle(
                    fontSize: 18,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue,
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
          ],
        ),
      ),
    );
  }
}