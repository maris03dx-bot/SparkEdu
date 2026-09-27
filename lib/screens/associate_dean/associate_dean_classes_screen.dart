import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssociateDeanClassesScreen extends StatefulWidget {
  const AssociateDeanClassesScreen({super.key});

  @override
  State<AssociateDeanClassesScreen> createState() =>
      _AssociateDeanClassesScreenState();
}

class _AssociateDeanClassesScreenState
    extends State<AssociateDeanClassesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String search = "";

  // ============================================================
  // MENTOR LIST
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getMentors() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore
            .collection("users")
            .where(
              "role",
              isEqualTo: "Mentor",
            )
            .get();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> mentors =
        snapshot.docs;

    mentors.sort((a, b) {
      final String nameA =
          a.data()["name"]?.toString().toLowerCase() ?? "";

      final String nameB =
          b.data()["name"]?.toString().toLowerCase() ?? "";

      return nameA.compareTo(nameB);
    });

    return mentors;
  }

  // ============================================================
  // SYNC MENTOR TO ALL STUDENTS IN A CLASS
  // ============================================================

  Future<int> syncMentorToClassStudents({
    required String className,
    required String mentorUid,
    required String mentorName,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore
            .collection("users")
            .where(
              "role",
              isEqualTo: "Student",
            )
            .where(
              "className",
              isEqualTo: className,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    final WriteBatch batch = firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> student
        in snapshot.docs) {
      batch.update(
        student.reference,
        {
          "mentorUid": mentorUid,
          "mentorName": mentorName,
          "updatedAt": FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    return snapshot.docs.length;
  }

  // ============================================================
  // REMOVE MENTOR FROM ALL STUDENTS IN A CLASS
  // ============================================================

  Future<int> clearMentorFromClassStudents({
    required String className,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore
            .collection("users")
            .where(
              "role",
              isEqualTo: "Student",
            )
            .where(
              "className",
              isEqualTo: className,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    final WriteBatch batch = firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> student
        in snapshot.docs) {
      batch.update(
        student.reference,
        {
          "mentorUid": "",
          "mentorName": "",
          "updatedAt": FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    return snapshot.docs.length;
  }

  // ============================================================
  // ADD / EDIT CLASS
  // ============================================================

  Future<void> showClassDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final Map<String, dynamic>? data = document?.data();

    final String existingClassName =
        data?["className"]?.toString().trim() ?? "";

    final bool isEditing = document != null;

    final TextEditingController classNameController =
        TextEditingController(
      text: existingClassName,
    );

    final TextEditingController batchController =
        TextEditingController(
      text: data?["batch"]?.toString() ?? "",
    );

    final TextEditingController departmentController =
        TextEditingController(
      text: data?["department"]?.toString() ?? "",
    );

    final TextEditingController yearController =
        TextEditingController(
      text: data?["year"]?.toString() ?? "",
    );

    final TextEditingController sectionController =
        TextEditingController(
      text: data?["section"]?.toString() ?? "",
    );

    String? selectedMentorUid =
        data?["mentorUid"]?.toString().trim();

    String? selectedMentorName =
        data?["mentorName"]?.toString().trim();

    try {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> mentors =
          await getMentors();

      if (!mounted) {
        return;
      }

      if (selectedMentorUid != null &&
          selectedMentorUid.isEmpty) {
        selectedMentorUid = null;
      }

      if (selectedMentorName != null &&
          selectedMentorName.isEmpty) {
        selectedMentorName = null;
      }

      if (selectedMentorUid != null) {
        final bool mentorStillExists = mentors.any(
          (mentor) {
            final String uid =
                mentor.data()["uid"]?.toString().trim() ?? mentor.id;

            return uid == selectedMentorUid;
          },
        );

        if (!mentorStillExists) {
          selectedMentorUid = null;
          selectedMentorName = null;
        }
      }

      await showDialog(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  isEditing ? "Edit Class" : "Add New Class",
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // CLASS NAME
                      // ==================================================

                      TextField(
                        controller: classNameController,
                        enabled: !isEditing,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: "Class Name",
                          hintText: "Example: 25CSEB2",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.class_),
                          helperText: isEditing
                              ? "Class Name cannot be changed after creation"
                              : "Example: 25CSEB2",
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // BATCH
                      // ==================================================

                      TextField(
                        controller: batchController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Batch",
                          hintText: "Example: 25",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // DEPARTMENT
                      // ==================================================

                      TextField(
                        controller: departmentController,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: "Department",
                          hintText: "Example: CSE",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // YEAR
                      // ==================================================

                      TextField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: "Academic Year",
                          hintText: "Example: II",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // SECTION
                      // ==================================================

                      TextField(
                        controller: sectionController,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: "Section",
                          hintText: "Example: B2",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.groups),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // MENTOR
                      // ==================================================

                      DropdownButtonFormField<String>(
                        initialValue: selectedMentorUid ?? "",
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Mentor",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: "",
                            child: Text(
                              "No Mentor Assigned",
                            ),
                          ),
                          ...mentors.map(
                            (mentor) {
                              final Map<String, dynamic> mentorData =
                                  mentor.data();

                              final String uid =
                                  mentorData["uid"]
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? mentorData["uid"].toString().trim()
                                  : mentor.id;

                              final String name =
                                  mentorData["name"]
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? mentorData["name"].toString().trim()
                                  : "Unnamed Mentor";

                              final String department =
                                  mentorData["department"]
                                          ?.toString()
                                          .trim() ??
                                      "";

                              final String displayName =
                                  department.isEmpty
                                  ? name
                                  : "$name • $department";

                              return DropdownMenuItem<String>(
                                value: uid,
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (String? value) {
                                setDialogState(() {
                                  if (value == null || value.isEmpty) {
                                    selectedMentorUid = null;
                                    selectedMentorName = null;
                                    return;
                                  }

                                  selectedMentorUid = value;

                                  QueryDocumentSnapshot<
                                          Map<String, dynamic>>?
                                      selectedMentor;

                                  for (final mentor in mentors) {
                                    final String uid =
                                        mentor.data()["uid"]
                                                ?.toString()
                                                .trim() ??
                                            mentor.id;

                                    if (uid == value) {
                                      selectedMentor = mentor;
                                      break;
                                    }
                                  }

                                  if (selectedMentor != null) {
                                    selectedMentorName =
                                        selectedMentor
                                                .data()["name"]
                                                ?.toString()
                                                .trim() ??
                                            "Mentor";
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                ),
                actions: [
                  // ==================================================
                  // CANCEL
                  // ==================================================

                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text("Cancel"),
                  ),

                  // ==================================================
                  // SAVE
                  // ==================================================

                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final String className =
                                classNameController.text.trim().toUpperCase();

                            final String batch =
                                batchController.text.trim();

                            final String department =
                                departmentController.text
                                    .trim()
                                    .toUpperCase();

                            final String year =
                                yearController.text.trim();

                            final String section =
                                sectionController.text
                                    .trim()
                                    .toUpperCase();

                            // ------------------------------------------
                            // VALIDATION
                            // ------------------------------------------

                            if (className.isEmpty ||
                                batch.isEmpty ||
                                department.isEmpty ||
                                year.isEmpty ||
                                section.isEmpty) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please fill all class fields",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              return;
                            }

                            // ------------------------------------------
                            // CLASS NAME VALIDATION
                            // ------------------------------------------

                            final RegExp classNamePattern = RegExp(
                              r'^[0-9]{2}[A-Z0-9]+$',
                            );

                            if (!classNamePattern.hasMatch(className)) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Invalid Class Name.\n"
                                    "Example: 25CSEB2",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              // ----------------------------------------
                              // NEW CLASS DUPLICATE CHECK
                              // ----------------------------------------

                              if (!isEditing) {
                                final DocumentSnapshot<
                                        Map<String, dynamic>>
                                    existingClass =
                                    await firestore
                                        .collection("classes")
                                        .doc(className)
                                        .get();

                                if (existingClass.exists) {
                                  if (!dialogContext.mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    saving = false;
                                  });

                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Class "$className" already exists.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );

                                  return;
                                }
                              }

                              // ----------------------------------------
                              // SAVE OLD MENTOR INFORMATION
                              // ----------------------------------------

                              final String oldMentorUid =
                                  data?["mentorUid"]
                                          ?.toString()
                                          .trim() ??
                                      "";

                              
                              final String newMentorUid =
                                  selectedMentorUid ?? "";

                              final String newMentorName =
                                  selectedMentorName ?? "";

                              // ----------------------------------------
                              // CLASS DATA
                              // ----------------------------------------

                              final Map<String, dynamic> classData = {
                                "className": className,
                                "batch": batch,
                                "department": department,
                                "year": year,
                                "section": section,
                                "mentorUid": newMentorUid,
                                "mentorName": newMentorName,
                                "updatedAt":
                                    FieldValue.serverTimestamp(),
                              };

                              // ----------------------------------------
                              // UPDATE CLASS
                              // ----------------------------------------

                              if (isEditing) {
                                await firestore
                                    .collection("classes")
                                    .doc(document.id)
                                    .update(classData);
                              }

                              // ----------------------------------------
                              // CREATE CLASS
                              // ----------------------------------------

                              else {
                                await firestore
                                    .collection("classes")
                                    .doc(className)
                                    .set({
                                  ...classData,
                                  "createdAt":
                                      FieldValue.serverTimestamp(),
                                });
                              }

                              // ----------------------------------------
                              // SYNC STUDENTS WITH NEW MENTOR
                              // ----------------------------------------

                              int updatedStudents = 0;

                              if (newMentorUid.isNotEmpty) {
                                updatedStudents =
                                    await syncMentorToClassStudents(
                                  className: className,
                                  mentorUid: newMentorUid,
                                  mentorName: newMentorName,
                                );
                              }

                              // ----------------------------------------
                              // IF MENTOR WAS REMOVED
                              // ----------------------------------------

                              else if (oldMentorUid.isNotEmpty) {
                                updatedStudents =
                                    await clearMentorFromClassStudents(
                                  className: className,
                                );
                              }

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              if (!mounted) {
                                return;
                              }

                              final String message;

                              if (newMentorUid.isNotEmpty) {
                                message = isEditing
                                    ? "Class updated. "
                                      "$updatedStudents student(s) "
                                      "updated with the mentor."
                                    : "Class created. "
                                      "$updatedStudents student(s) "
                                      "updated with the mentor.";
                              } else if (oldMentorUid.isNotEmpty) {
                                message =
                                    "Mentor removed. "
                                    "$updatedStudents student(s) "
                                    "updated.";
                              } else {
                                message = isEditing
                                    ? "Class updated successfully"
                                    : "Class created successfully";
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed: $e",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing ? Icons.save : Icons.add,
                          ),
                    label: Text(
                      saving
                          ? "Saving..."
                          : isEditing
                              ? "Save"
                              : "Create",
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load mentors: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      classNameController.dispose();
      batchController.dispose();
      departmentController.dispose();
      yearController.dispose();
      sectionController.dispose();
    }
  }

  // ============================================================
  // REMOVE MENTOR
  // ============================================================

  Future<void> removeMentor(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String className =
        data["className"]?.toString() ?? document.id;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Remove Mentor?",
          ),
          content: Text(
            'Remove the mentor assigned to "$className"?\n\n'
            "Students in this class will also have their mentor "
            "information cleared.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // ----------------------------------------------------------
      // REMOVE MENTOR FROM CLASS
      // ----------------------------------------------------------

      await firestore
          .collection("classes")
          .doc(document.id)
          .update({
        "mentorUid": "",
        "mentorName": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // ----------------------------------------------------------
      // REMOVE MENTOR FROM ALL STUDENTS IN THIS CLASS
      // ----------------------------------------------------------

      final int updatedStudents =
          await clearMentorFromClassStudents(
        className: className,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Mentor removed successfully. "
            "$updatedStudents student(s) updated.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to remove mentor: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DELETE CLASS
  // ============================================================

  Future<void> deleteClass(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String className =
        data["className"]?.toString() ?? document.id;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete Class?",
          ),
          content: Text(
            'Are you sure you want to delete "$className"?\n\n'
            "This only deletes the class document. "
            "Existing attendance records are not automatically deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await firestore
          .collection("classes")
          .doc(document.id)
          .delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Class deleted successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to delete class: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget buildClassCard(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? {};

    final String className =
        data["className"]?.toString() ?? document.id;

    final String batch =
        data["batch"]?.toString() ?? "N/A";

    final String department =
        data["department"]?.toString() ?? "N/A";

    final String year =
        data["year"]?.toString() ?? "N/A";

    final String section =
        data["section"]?.toString() ?? "N/A";

    final String mentorName =
        data["mentorName"]?.toString().trim() ?? "";

    final bool hasMentor =
        mentorName.isNotEmpty;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showClassDialog(
            document: document,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ======================================================
              // TOP ROW
              // ======================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Colors.blue.shade100,
                    child: const Icon(
                      Icons.class_,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Batch $batch",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          "Tap to edit class",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // MORE MENU
                  // ==================================================

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        showClassDialog(
                          document: document,
                        );
                      }

                      if (value == "remove") {
                        removeMentor(
                          document,
                        );
                      }

                      if (value == "delete") {
                        deleteClass(
                          document,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Edit / Assign Mentor",
                            ),
                          ],
                        ),
                      ),

                      if (hasMentor)
                        const PopupMenuItem<String>(
                          value: "remove",
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_remove,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Remove Mentor",
                              ),
                            ],
                          ),
                        ),

                      const PopupMenuItem<String>(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Delete Class",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Divider(),

              const SizedBox(height: 8),

              // ======================================================
              // CLASS INFORMATION
              // ======================================================

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.account_balance,
                      department,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.school,
                      "Year $year",
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.groups,
                      "Section $section",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ======================================================
              // MENTOR
              // ======================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasMentor
                      ? Colors.green.withValues(
                          alpha: 0.08,
                        )
                      : Colors.orange.withValues(
                          alpha: 0.08,
                        ),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: hasMentor
                        ? Colors.green.withValues(
                            alpha: 0.25,
                          )
                        : Colors.orange.withValues(
                            alpha: 0.25,
                          ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasMentor
                          ? Icons.person
                          : Icons.person_outline,
                      color: hasMentor
                          ? Colors.green
                          : Colors.orange,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        hasMentor
                            ? "Mentor: $mentorName"
                            : "Mentor: Not Assigned",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: hasMentor
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.blue,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Class Management",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ==========================================================
      // ADD CLASS
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          showClassDialog();
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Class",
        ),
      ),

      body: Column(
        children: [
          // ========================================================
          // SEARCH
          // ========================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              5,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Class...",
                prefixIcon: const Icon(
                  Icons.search,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search =
                      value.trim().toLowerCase();
                });
              },
            ),
          ),

          // ========================================================
          // CLASS LIST
          // ========================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection("classes")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Text(
                        "Error loading classes:\n\n"
                        "${snapshot.error}",
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    classes =
                    snapshot.data?.docs
                            .where(
                              (document) {
                                final Map<
                                        String,
                                        dynamic>
                                    data =
                                    document.data();

                                final String className =
                                    data["className"]
                                            ?.toString()
                                            .toLowerCase() ??
                                        document.id
                                            .toLowerCase();

                                final String department =
                                    data["department"]
                                            ?.toString()
                                            .toLowerCase() ??
                                        "";

                                final String year =
                                    data["year"]
                                            ?.toString()
                                            .toLowerCase() ??
                                        "";

                                final String section =
                                    data["section"]
                                            ?.toString()
                                            .toLowerCase() ??
                                        "";

                                final String mentor =
                                    data["mentorName"]
                                            ?.toString()
                                            .toLowerCase() ??
                                        "";

                                return className.contains(
                                          search,
                                        ) ||
                                    department.contains(
                                      search,
                                    ) ||
                                    year.contains(
                                      search,
                                    ) ||
                                    section.contains(
                                      search,
                                    ) ||
                                    mentor.contains(
                                      search,
                                    );
                              },
                            )
                            .toList() ??
                        [];

                classes.sort(
                  (a, b) {
                    final String classA =
                        a.data()["className"]
                                ?.toString() ??
                            a.id;

                    final String classB =
                        b.data()["className"]
                                ?.toString() ??
                            b.id;

                    return classA
                        .toLowerCase()
                        .compareTo(
                          classB.toLowerCase(),
                        );
                  },
                );

                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "No Classes Found",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          search.isEmpty
                              ? "Tap 'Add Class' to create the first class."
                              : "No classes match your search.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    90,
                  ),
                  itemCount: classes.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return buildClassCard(
                      classes[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}