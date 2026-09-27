import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() =>
      _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // ==========================================================
  // TEACHER INFORMATION
  // ==========================================================

  String teacherUid = '';
  String teacherName = '';
  String employeeId = '';
  String teacherDepartment = '';
  String teacherSubject = '';

  bool isLoadingTeacher = true;

  // ==========================================================
  // ASSIGNMENT VARIABLES
  // ==========================================================

  DateTime? dueDate;

  bool isSaving = false;

  File? selectedPdf;

  String? selectedPdfName;

  double uploadProgress = 0.0;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    loadTeacherProfile();
  }

  // ==========================================================
  // LOAD LOGGED-IN TEACHER
  // ==========================================================

  Future<void> loadTeacherProfile() async {
  try {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoadingTeacher = false;
      });

      return;
    }

    teacherUid = user.uid;

    // Find the teacher by Firebase Authentication UID.
    final querySnapshot = await _firestore
        .collection('users')
        .where(
          'uid',
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoadingTeacher = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Teacher profile not found.\n'
            'Logged-in UID: ${user.uid}',
          ),
        ),
      );

      return;
    }

    final data =
        querySnapshot.docs.first.data();

    final role =
        (data['role'] ?? '').toString().trim();

    if (role != 'Subject Teacher') {
      if (!mounted) return;

      setState(() {
        isLoadingTeacher = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'This account is not registered as a Subject Teacher.\n'
            'Role found: $role',
          ),
        ),
      );

      return;
    }

    teacherName =
        (data['name'] ?? '').toString().trim();

    employeeId =
        (data['employeeId'] ?? '').toString().trim();

    teacherDepartment =
        (data['department'] ?? '').toString().trim();

    teacherSubject =
        (data['subject'] ?? '').toString().trim();

    if (!mounted) return;

    setState(() {
      isLoadingTeacher = false;
    });

    // Helpful confirmation while testing.
    if (teacherSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Teacher profile found, but the subject field is empty.',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingTeacher = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Unable to load teacher information:\n$e',
        ),
      ),
    );
  }
}

  // ==========================================================
  // PICK DUE DATE
  // ==========================================================

  Future<void> pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  // ==========================================================
  // PICK PDF
  // ==========================================================

  Future<void> pickPDF() async {
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
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Unable to access the selected PDF.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        selectedPdf = File(path);
        selectedPdfName = result.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF selected: ${result.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Unable to select PDF: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // UPLOAD PDF TO FIREBASE STORAGE
  // ==========================================================

  Future<String> uploadPdfToStorage() async {
    if (selectedPdf == null ||
        selectedPdfName == null ||
        selectedPdfName!.trim().isEmpty) {
      return '';
    }

    final fileName = selectedPdfName!.trim();

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final safeFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final storagePath =
        'assignments/$teacherUid/$timestamp-$safeFileName';

    final storageRef =
        FirebaseStorage.instance.ref().child(storagePath);

    final uploadTask =
        storageRef.putFile(selectedPdf!);

    uploadTask.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        if (!mounted) return;

        if (snapshot.totalBytes > 0) {
          setState(() {
            uploadProgress =
                snapshot.bytesTransferred /
                    snapshot.totalBytes;
          });
        }
      },
    );

    final snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  // ==========================================================
  // CREATE ASSIGNMENT
  // ==========================================================

  Future<void> createAssignment() async {
    final title =
        titleController.text.trim();

    final description =
        descriptionController.text.trim();

    // ========================================================
    // VALIDATION
    // ========================================================

    if (teacherUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Teacher account information is unavailable.',
          ),
        ),
      );

      return;
    }

    if (teacherSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'No subject is assigned to your teacher profile.',
          ),
        ),
      );

      return;
    }

    if (title.isEmpty ||
        description.isEmpty ||
        dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Please complete all fields.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
      uploadProgress = 0.0;
    });

    try {
      // ======================================================
      // PDF UPLOAD
      // ======================================================

      String pdfUrl = '';

      bool pdfUploaded = false;

      if (selectedPdf != null) {
        if (mounted) {
          setState(() {
            uploadProgress = 0.0;
          });
        }

        pdfUrl = await uploadPdfToStorage();

        pdfUploaded = pdfUrl.isNotEmpty;
      }

      // ======================================================
      // CREATE FIRESTORE ASSIGNMENT
      // ======================================================

      await _firestore
          .collection('assignments')
          .add({
        // ====================================================
        // TEACHER OWNERSHIP
        // ====================================================

        'teacherUid': teacherUid,
        'teacherName': teacherName,
        'employeeId': employeeId,
        'department': teacherDepartment,

        // ====================================================
        // SUBJECT
        // ====================================================

        'subject': teacherSubject,

        // ====================================================
        // ASSIGNMENT INFORMATION
        // ====================================================

        'title': title,
        'description': description,

        'dueDate': Timestamp.fromDate(
          dueDate!,
        ),

        // ====================================================
        // PDF INFORMATION
        // ====================================================

        'pdfName': selectedPdfName ?? '',
        'pdfUrl': pdfUrl,
        'pdfUploaded': pdfUploaded,

        // ====================================================
        // CREATED TIME
        // ====================================================

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            pdfUploaded
                ? 'Assignment and PDF uploaded successfully.'
                : 'Assignment created successfully.',
          ),
        ),
      );

      // ======================================================
      // CLEAR FORM
      // ======================================================

      titleController.clear();
      descriptionController.clear();

      setState(() {
        dueDate = null;
        selectedPdf = null;
        selectedPdfName = null;
        uploadProgress = 0.0;
        isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
        uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Failed to create assignment:\n$e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  // ==========================================================
  // SUBJECT CARD
  // ==========================================================

  Widget buildSubjectSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subject',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  teacherSubject.isEmpty
                      ? 'No subject assigned'
                      : teacherSubject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TEACHER INFORMATION CARD
  // ==========================================================

  Widget buildTeacherInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.indigo,
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName.isEmpty
                      ? 'Subject Teacher'
                      : teacherName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employeeId.isEmpty
                      ? teacherDepartment
                      : '$employeeId • $teacherDepartment',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECTED PDF CARD
  // ==========================================================

  Widget buildPdfSection() {
    final hasPdf =
        selectedPdfName != null &&
        selectedPdfName!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
        ),
      ),
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
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assignment PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    isSaving ? null : pickPDF,
                child: Text(
                  hasPdf
                      ? 'Change'
                      : 'Select PDF',
                ),
              ),
            ],
          ),
          if (hasPdf) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedPdfName!,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (isSaving && selectedPdf != null) ...[
              LinearProgressIndicator(
                value: uploadProgress > 0
                    ? uploadProgress
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                uploadProgress > 0
                    ? 'Uploading PDF: '
                        '${(uploadProgress * 100).toStringAsFixed(0)}%'
                    : 'Uploading PDF...',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ] else ...[
              const Text(
                'The selected PDF will be uploaded to Firebase Storage.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Assignment',
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoadingTeacher
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ==================================================
                  // TEACHER INFORMATION
                  // ==================================================

                  buildTeacherInfoSection(),

                  const SizedBox(height: 16),

                  // ==================================================
                  // SUBJECT
                  // ==================================================

                  buildSubjectSection(),

                  const SizedBox(height: 20),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  buildTextField(
                    controller: titleController,
                    label: 'Assignment Title',
                    icon: Icons.assignment,
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  buildTextField(
                    controller:
                        descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 5,
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // DUE DATE
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        dueDate == null
                            ? 'Select Due Date'
                            : DateFormat(
                                'dd MMM yyyy',
                              ).format(
                                dueDate!,
                              ),
                      ),
                      trailing:
                          ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : pickDueDate,
                        child: const Text(
                          'Choose',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // PDF
                  // ==================================================

                  buildPdfSection(),

                  const SizedBox(height: 35),

                  // ==================================================
                  // CREATE BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
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
                            15,
                          ),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : createAssignment,
                      icon: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.add_task,
                            ),
                      label: Text(
                        isSaving
                            ? selectedPdf != null
                                ? 'Uploading & Saving...'
                                : 'Saving...'
                            : 'Create Assignment',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // STORAGE NOTICE
                  // ==================================================

                  Text(
                    selectedPdf != null
                        ? 'Your PDF will be securely stored in Firebase Storage.'
                        : 'PDF is optional. You can create an assignment without a PDF.',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}