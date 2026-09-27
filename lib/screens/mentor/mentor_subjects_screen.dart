import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MentorSubjectsScreen extends StatefulWidget {
  const MentorSubjectsScreen({super.key});

  @override
  State<MentorSubjectsScreen> createState() =>
      _MentorSubjectsScreenState();
}

class _MentorSubjectsScreenState extends State<MentorSubjectsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers = [];

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  // ==========================================================
  // LOAD SUBJECT TEACHERS
  // ==========================================================

  Future<void> loadTeachers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore
              .collection("users")
              .where(
                "role",
                isEqualTo: "Subject Teacher",
              )
              .get();

      if (!mounted) return;

      setState(() {
        teachers = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading teachers: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to load subject teachers: $e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // ADD / EDIT SUBJECT
  // ==========================================================

  Future<void> showSubjectDialog({
    DocumentSnapshot<Map<String, dynamic>>? existingSubject,
  }) async {
    if (!mounted) return;

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SubjectDialog(
          firestore: firestore,
          teachers: teachers,
          existingSubject: existingSubject,
        );
      },
    );

    if (!mounted) return;

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            existingSubject == null
                ? "Subject created and teacher assigned."
                : "Subject updated successfully.",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DELETE SUBJECT
  // ==========================================================

  Future<void> deleteSubject(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String subjectName =
        data["name"]?.toString().trim() ??
            "this subject";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Subject"),
          content: Text(
            "Are you sure you want to delete \"$subjectName\"?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await firestore
          .collection("subjects")
          .doc(document.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Subject deleted successfully.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Could not delete subject: $e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // SUBJECT CARD
  // ==========================================================

  Widget buildSubjectCard(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String code =
        data["code"]?.toString().trim() ?? "";

    final String name =
        data["name"]?.toString().trim() ??
            "Unnamed Subject";

    final String teacher =
        data["teacher"]?.toString().trim() ??
            "No Teacher";

    final String department =
        data["department"]?.toString().trim() ?? "";

    final String year =
        data["year"]?.toString().trim() ?? "";

    final String section =
        data["section"]?.toString().trim() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.deepPurple,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      showSubjectDialog(
                        existingSubject: document,
                      );
                    } else if (value == "delete") {
                      deleteSubject(document);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          SizedBox(width: 10),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue
                    .withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teacher,
                      maxLines: 1,
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

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (department.isNotEmpty)
                  _buildInfoChip(
                    Icons.business_rounded,
                    department,
                  ),
                if (year.isNotEmpty)
                  _buildInfoChip(
                    Icons.school_rounded,
                    "Year $year",
                  ),
                if (section.isNotEmpty)
                  _buildInfoChip(
                    Icons.groups_rounded,
                    "Section $section",
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7FC),

      appBar: AppBar(
        title: const Text(
          "Subjects",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: isLoading
            ? null
            : () {
                showSubjectDialog();
              },
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Subject"),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection("subjects")
                  .orderBy(
                    "createdAt",
                    descending: true,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Text(
                        "Unable to load subjects.\n\n${snapshot.error}",
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .menu_book_outlined,
                            size: 70,
                            color:
                                Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No subjects created yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Create a subject and assign it to a Subject Teacher.",
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: loadTeachers,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ),
                    itemCount: documents.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return buildSubjectCard(
                        documents[index],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// SUBJECT DIALOG
// ============================================================================

class _SubjectDialog extends StatefulWidget {
  final FirebaseFirestore firestore;

  final List<
      QueryDocumentSnapshot<Map<String, dynamic>>> teachers;

  final DocumentSnapshot<Map<String, dynamic>>?
      existingSubject;

  const _SubjectDialog({
    required this.firestore,
    required this.teachers,
    this.existingSubject,
  });

  @override
  State<_SubjectDialog> createState() =>
      _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  late final TextEditingController codeController;
  late final TextEditingController nameController;
  late final TextEditingController departmentController;
  late final TextEditingController yearController;
  late final TextEditingController sectionController;

  String? selectedTeacherUid;
  String? selectedTeacherName;

  bool isSaving = false;

  bool get isEditing =>
      widget.existingSubject != null;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> data =
        widget.existingSubject?.data() ?? {};

    codeController = TextEditingController(
      text: data["code"]?.toString() ?? "",
    );

    nameController = TextEditingController(
      text: data["name"]?.toString() ?? "",
    );

    departmentController = TextEditingController(
      text: data["department"]?.toString() ?? "",
    );

    yearController = TextEditingController(
      text: data["year"]?.toString() ?? "",
    );

    sectionController = TextEditingController(
      text: data["section"]?.toString() ?? "",
    );

    selectedTeacherUid =
        data["teacherUid"]?.toString().trim();

    selectedTeacherName =
        data["teacher"]?.toString().trim();

    _resolveTeacher();
  }

  // ==========================================================
  // RESOLVE TEACHER
  // ==========================================================

  void _resolveTeacher() {
    if (selectedTeacherUid != null &&
        selectedTeacherUid!.isNotEmpty) {
      final bool exists = widget.teachers.any(
        (teacher) {
          final Map<String, dynamic> data =
              teacher.data();

          final String uid =
              data["uid"]?.toString().trim() ??
                  teacher.id;

          return uid == selectedTeacherUid;
        },
      );

      if (exists) {
        return;
      }

      selectedTeacherUid = null;
    }

    if (selectedTeacherName == null ||
        selectedTeacherName!.trim().isEmpty) {
      return;
    }

    for (final teacher in widget.teachers) {
      final Map<String, dynamic> data =
          teacher.data();

      final String name =
          data["name"]?.toString().trim() ?? "";

      if (name.toLowerCase() ==
          selectedTeacherName!
              .trim()
              .toLowerCase()) {
        selectedTeacherUid =
            data["uid"]?.toString().trim() ??
                teacher.id;

        selectedTeacherName = name;

        return;
      }
    }
  }

  // ==========================================================
  // GET TEACHER NAME
  // ==========================================================

  String _getTeacherName(String uid) {
    for (final teacher in widget.teachers) {
      final Map<String, dynamic> data =
          teacher.data();

      final String teacherUid =
          data["uid"]?.toString().trim() ??
              teacher.id;

      if (teacherUid == uid) {
        return data["name"]?.toString().trim() ??
            "Subject Teacher";
      }
    }

    return "Subject Teacher";
  }

  // ==========================================================
  // SAVE SUBJECT
  // ==========================================================

  Future<void> _saveSubject() async {
    final String code =
        codeController.text.trim();

    final String name =
        nameController.text.trim();

    final String department =
        departmentController.text.trim();

    final String year =
        yearController.text.trim();

    final String section =
        sectionController.text.trim();

    if (code.isEmpty ||
        name.isEmpty ||
        department.isEmpty ||
        year.isEmpty ||
        section.isEmpty) {
      _showMessage(
        "Please fill all subject details.",
        Colors.orange,
      );
      return;
    }

    if (selectedTeacherUid == null ||
        selectedTeacherUid!.trim().isEmpty) {
      _showMessage(
        "Please select a Subject Teacher.",
        Colors.orange,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String teacherUid =
          selectedTeacherUid!.trim();

      final String teacherName =
          selectedTeacherName?.trim().isNotEmpty ==
                  true
              ? selectedTeacherName!.trim()
              : _getTeacherName(teacherUid);

      final Map<String, dynamic> subjectData = {
        "code": code,
        "name": name,
        "teacher": teacherName,

        // IMPORTANT:
        // This connects the subject directly
        // to the Firebase Authentication UID.
        "teacherUid": teacherUid,

        "department": department,
        "year": year,
        "section": section,
        "updatedAt":
            FieldValue.serverTimestamp(),
      };

      if (widget.existingSubject == null) {
        subjectData["createdAt"] =
            FieldValue.serverTimestamp();

        await widget.firestore
            .collection("subjects")
            .add(subjectData);
      } else {
        await widget.firestore
            .collection("subjects")
            .doc(widget.existingSubject!.id)
            .update(subjectData);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint(
        "Error saving subject: $e",
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        "Could not save subject: $e",
        Colors.red,
      );
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message),
      ),
    );
  }

  // ==========================================================
  // BUILD DIALOG
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      title: Text(
        isEditing
            ? "Edit Subject"
            : "Create Subject",
      ),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ========================================================
              // SUBJECT CODE
              // ========================================================

              TextField(
                controller: codeController,
                enabled: !isSaving,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Subject Code",
                  hintText: "Example: CS101",
                  prefixIcon:
                      Icon(Icons.code_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // ========================================================
              // SUBJECT NAME
              // ========================================================

              TextField(
                controller: nameController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: "Subject Name",
                  hintText:
                      "Example: Data Structures",
                  prefixIcon:
                      Icon(Icons.menu_book_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // ========================================================
              // SUBJECT TEACHER
              // ========================================================

              DropdownButtonFormField<String>(
                initialValue: selectedTeacherUid,
                isExpanded: true,
                menuMaxHeight: 280,
                decoration: const InputDecoration(
                  labelText: "Subject Teacher",
                  prefixIcon:
                      Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
                items: widget.teachers.map(
                  (
                    QueryDocumentSnapshot<
                        Map<String, dynamic>> teacher,
                  ) {
                    final Map<String, dynamic> data =
                        teacher.data();

                    final String uid =
                        data["uid"]?.toString().trim() ??
                            teacher.id;

                    final String name =
                        data["name"]?.toString().trim() ??
                            "Unnamed Teacher";

                    final String employeeId =
                        data["employeeId"]
                                ?.toString()
                                .trim() ??
                            "";

                    final String department =
                        data["department"]
                                ?.toString()
                                .trim() ??
                            "";

                    String displayName = name;

                    if (employeeId.isNotEmpty) {
                      displayName =
                          "$displayName • $employeeId";
                    }

                    if (department.isNotEmpty) {
                      displayName =
                          "$displayName • $department";
                    }

                    return DropdownMenuItem<String>(
                      value: uid,
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ).toList(),
                onChanged: isSaving
                    ? null
                    : (String? value) {
                        if (value == null) {
                          return;
                        }

                        final String name =
                            _getTeacherName(value);

                        setState(() {
                          selectedTeacherUid =
                              value;
                          selectedTeacherName =
                              name;
                        });
                      },
              ),

              const SizedBox(height: 14),

              // ========================================================
              // DEPARTMENT
              // ========================================================

              TextField(
                controller: departmentController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: "Department",
                  hintText: "Example: CSE",
                  prefixIcon:
                      Icon(Icons.business_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // ========================================================
              // YEAR
              // ========================================================

              TextField(
                controller: yearController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: "Year",
                  hintText: "Example: II",
                  prefixIcon:
                      Icon(Icons.school_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // ========================================================
              // SECTION
              // ========================================================

              TextField(
                controller: sectionController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: "Section",
                  hintText: "Example: A",
                  prefixIcon:
                      Icon(Icons.groups_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),

      // ==========================================================
      // ACTIONS
      // ==========================================================

      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: isSaving
              ? null
              : _saveSubject,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditing
                      ? "Save"
                      : "Create",
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    departmentController.dispose();
    yearController.dispose();
    sectionController.dispose();

    super.dispose();
  }
}