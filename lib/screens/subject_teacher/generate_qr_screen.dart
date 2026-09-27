import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  String? department;
  String? year;
  String? section;
  String? className;
  String? subject;

  String qrData = "";
  String? sessionId;

  bool sessionActive = false;
  bool isProcessing = false;

  // ============================================================
  // SUBJECT DATA
  // ============================================================

  List<String> subjects = [];
  bool isLoadingSubjects = true;

  // ============================================================
  // CLASS DATA
  // ============================================================

  List<String> classNames = [];
  bool isLoadingClasses = true;

  // Master class year data.
  //
  // Example:
  //
  // 25CSEB2 -> II
  // 25CSEB3 -> II
  //
  final Map<String, String> _classYearMap = {};

  static const int sessionDurationMinutes = 10;

  Timer? sessionTimer;

  final List<String> departments = [
    "CSE",
    "IT",
    "ECE",
    "EEE",
    "MECH",
  ];

  final List<String> years = [
    "I",
    "II",
    "III",
    "IV",
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadSubjects();
    loadClassNames();
  }

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> loadSubjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("subjects")
          .orderBy("name")
          .get();

      if (!mounted) return;

      final loadedSubjects = snapshot.docs
          .map(
            (doc) => doc.data()["name"]?.toString().trim() ?? "",
          )
          .where(
            (name) => name.isNotEmpty,
          )
          .toList();

      setState(() {
        subjects = loadedSubjects;
        isLoadingSubjects = false;

        if (subject != null && !subjects.contains(subject)) {
          subject = null;
        }
      });
    } catch (e) {
      debugPrint("Error loading subjects: $e");

      if (!mounted) return;

      setState(() {
        subjects = [];
        isLoadingSubjects = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not load subjects: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOAD CLASS NAMES + MASTER CLASS DATA
  // ============================================================

  Future<void> loadClassNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("classes")
          .orderBy("className")
          .get();

      final Set<String> uniqueClasses = {};

      _classYearMap.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final value =
            data["className"]?.toString().trim() ??
                doc.id.trim();

        if (value.isEmpty) {
          continue;
        }

        final normalizedClassName =
            value.toUpperCase();

        uniqueClasses.add(
          normalizedClassName,
        );

        // ======================================================
        // STORE MASTER CLASS YEAR
        // ======================================================

        final masterYear =
            data["year"]?.toString().trim() ?? "";

        if (masterYear.isNotEmpty) {
          _classYearMap[
            normalizedClassName
          ] = masterYear.toUpperCase();
        }
      }

      final loadedClasses =
          uniqueClasses.toList()..sort();

      if (!mounted) return;

      setState(() {
        classNames = loadedClasses;
        isLoadingClasses = false;

        if (className != null &&
            !classNames.contains(
              className!.toUpperCase(),
            )) {
          className = null;
          section = null;
        }

        // ======================================================
        // KEEP SELECTED CLASS VALID FOR SELECTED YEAR
        // ======================================================

        if (className != null &&
            year != null &&
            !_classYearMatches(
              className!,
              year!,
            )) {
          className = null;
          section = null;
        }
      });
    } catch (e) {
      debugPrint(
        "Error loading class names: $e",
      );

      if (!mounted) return;

      setState(() {
        classNames = [];
        _classYearMap.clear();
        isLoadingClasses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not load classes: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // GET TEACHER NAME
  // ============================================================

  Future<String> getTeacherName() async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return "Teacher";
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where(
            "uid",
            isEqualTo: currentUser.uid,
          )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data =
            query.docs.first.data();

        return data["name"]?.toString() ??
            currentUser.displayName ??
            currentUser.email ??
            "Teacher";
      }
    } catch (_) {}

    return currentUser.displayName ??
        currentUser.email ??
        "Teacher";
  }

  // ============================================================
  // EXTRACT DEPARTMENT FROM CLASS NAME
  // ============================================================

  String extractDepartmentFromClassName(
    String value,
  ) {
    final normalized =
        value.trim().toUpperCase();

    for (final item in departments) {
      if (normalized.contains(item)) {
        return item;
      }
    }

    return "";
  }

  // ============================================================
  // EXTRACT SECTION FROM CLASS NAME
  // ============================================================

  String extractSectionFromClassName(
    String value,
  ) {
    final normalized =
        value.trim().toUpperCase();

    final detectedDepartment =
        extractDepartmentFromClassName(
      normalized,
    );

    if (detectedDepartment.isEmpty) {
      return "";
    }

    final departmentIndex =
        normalized.indexOf(
      detectedDepartment,
    );

    if (departmentIndex == -1) {
      return "";
    }

    final sectionStart =
        departmentIndex +
            detectedDepartment.length;

    if (sectionStart >= normalized.length) {
      return "";
    }

    return normalized.substring(
      sectionStart,
    );
  }

  // ============================================================
  // GET CLASS STUDENTS
  // ============================================================

  Future<QuerySnapshot<Map<String, dynamic>>>
      getClassStudents() async {
    return FirebaseFirestore.instance
        .collection("users")
        .where(
          "role",
          isEqualTo: "Student",
        )
        .where(
          "className",
          isEqualTo: className,
        )
        .where(
          "year",
          isEqualTo: year,
        )
        .get();
  }

  // ============================================================
  // GENERATE QR
  // ============================================================

  Future<void> generateQR() async {
    if (department == null ||
        year == null ||
        className == null ||
        subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select Department, Year, Class and Subject",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (sessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "An attendance session is already active.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final selectedDepartment =
          department!;

      final selectedYear = year!;

      final selectedClassName =
          className!;

      final selectedSection =
          extractSectionFromClassName(
        selectedClassName,
      );

      if (selectedSection.isEmpty) {
        throw Exception(
          "Could not determine the section from Class Name $selectedClassName.",
        );
      }

      final now = DateTime.now();

      final newSessionId =
          now.millisecondsSinceEpoch.toString();

      final teacherName =
          await getTeacherName();

      final expiresAt = now.add(
        const Duration(
          minutes: sessionDurationMinutes,
        ),
      );

      // ========================================================
      // QR DATA
      // ========================================================

      final generatedQRData =
          "sessionId=$newSessionId;"
          "className=$selectedClassName;"
          "department=$selectedDepartment;"
          "year=$selectedYear;"
          "section=$selectedSection;"
          "subject=$subject;"
          "teacher=$teacherName;"
          "date=${DateFormat("yyyy-MM-dd").format(now)};"
          "time=${DateFormat("HH:mm").format(now)}";

      // ========================================================
      // CREATE ATTENDANCE SESSION
      // ========================================================

      await FirebaseFirestore.instance
          .collection("attendance_sessions")
          .doc(newSessionId)
          .set({
        "sessionId": newSessionId,

        // MAIN CLASS IDENTIFIER
        "className": selectedClassName,

        // COMPATIBILITY FIELDS
        "department": selectedDepartment,
        "year": selectedYear,
        "section": selectedSection,

        "subject": subject,

        "teacher": teacherName,

        "teacherUid":
            FirebaseAuth.instance.currentUser?.uid,

        "date": DateFormat(
          "yyyy-MM-dd",
        ).format(now),

        "time": DateFormat(
          "HH:mm",
        ).format(now),

        "createdAt": Timestamp.now(),

        "expiresAt": Timestamp.fromDate(
          expiresAt,
        ),

        "active": true,
      });

      if (!mounted) return;

      setState(() {
        sessionId = newSessionId;

        qrData = generatedQRData;

        sessionActive = true;

        isProcessing = false;

        section = selectedSection;

        department = selectedDepartment;
      });

      // ========================================================
      // AUTOMATIC SESSION CLOSE
      // ========================================================

      sessionTimer?.cancel();

      sessionTimer = Timer(
        const Duration(
          minutes: sessionDurationMinutes,
        ),
        () {
          if (mounted && sessionActive) {
            closeSessionAndMarkAbsent(
              automatic: true,
            );
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance QR generated successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to generate QR: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CLOSE SESSION + MARK ABSENT
  // ============================================================

  Future<void> closeSessionAndMarkAbsent({
    bool automatic = false,
  }) async {
    if (!sessionActive ||
        sessionId == null ||
        className == null) {
      return;
    }

    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final firestore =
          FirebaseFirestore.instance;

      final teacherName =
          await getTeacherName();

      final now = DateTime.now();

      final selectedClassName =
          className!;

      final selectedYear =
          year!;

      // ========================================================
      // GET STUDENTS USING CLASS NAME
      // ========================================================

      final studentsQuery = await firestore
          .collection("users")
          .where(
            "role",
            isEqualTo: "Student",
          )
          .where(
            "className",
            isEqualTo: selectedClassName,
          )
          .where(
            "year",
            isEqualTo: selectedYear,
          )
          .get();

      // ========================================================
      // GET PRESENT STUDENTS
      // ========================================================

      final attendanceQuery = await firestore
          .collection("attendance")
          .where(
            "sessionId",
            isEqualTo: sessionId,
          )
          .get();

      final Set<String>
          presentStudentIds = {};

      for (final doc
          in attendanceQuery.docs) {
        final data = doc.data();

        if (data["status"] ==
            "Present") {
          final studentId =
              data["studentId"]
                  ?.toString()
                  .trim();

          if (studentId != null &&
              studentId.isNotEmpty) {
            presentStudentIds.add(
              studentId,
            );
          }
        }
      }

      // ========================================================
      // MARK ABSENT
      // ========================================================

      final List<
          Map<String, dynamic>>
          absentStudents = [];

      for (final studentDoc
          in studentsQuery.docs) {
        final data =
            studentDoc.data();

        // REGISTER NUMBER IS THE PRIMARY
        // STUDENT IDENTIFIER.
        final studentId =
            data["registerNo"]
                    ?.toString()
                    .trim() ??
                studentDoc.id;

        final studentName =
            data["name"]
                    ?.toString()
                    .trim() ??
                "Student";

        final studentDepartment =
            data["department"]
                    ?.toString()
                    .trim() ??
                department;

        final studentYear =
            data["year"]
                    ?.toString()
                    .trim() ??
                selectedYear;

        final studentSection =
            data["section"]
                    ?.toString()
                    .trim() ??
                section;

        final studentClassName =
            data["className"]
                    ?.toString()
                    .trim() ??
                selectedClassName;

        // ======================================================
        // EXTRA SAFETY CHECK
        //
        // Never create an absent record if the student's
        // actual class does not match this session class.
        // ======================================================

        if (studentClassName.toUpperCase() !=
            selectedClassName.toUpperCase()) {
          continue;
        }

        // ======================================================
        // STUDENT DID NOT SCAN
        // ======================================================

        if (!presentStudentIds
            .contains(studentId)) {
          absentStudents.add({
            "attendanceId":
                "${studentId}_$sessionId",

            "sessionId":
                sessionId,

            "studentId":
                studentId,

            "studentName":
                studentName,

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

            "subject":
                subject,

            "teacher":
                teacherName,

            "date":
                DateFormat(
                  "yyyy-MM-dd",
                ).format(now),

            "time":
                DateFormat(
                  "HH:mm",
                ).format(now),

            "status":
                "Absent",

            "createdAt":
                Timestamp.now(),
          });
        }
      }

      // ========================================================
      // WRITE ABSENT RECORDS
      //
      // Firestore batch limit = 500.
      // ========================================================

      for (
        int start = 0;
        start < absentStudents.length;
        start += 500
      ) {
        final end =
            (start + 500 <
                    absentStudents.length)
                ? start + 500
                : absentStudents.length;

        final batch =
            firestore.batch();

        for (
          int i = start;
          i < end;
          i++
        ) {
          final attendanceData =
              absentStudents[i];

          final attendanceRef =
              firestore
                  .collection(
                    "attendance",
                  )
                  .doc(
                    attendanceData[
                        "attendanceId"],
                  );

          batch.set(
            attendanceRef,
            attendanceData,
          );
        }

        await batch.commit();
      }

      // ========================================================
      // CLOSE SESSION
      // ========================================================

      await firestore
          .collection(
            "attendance_sessions",
          )
          .doc(sessionId)
          .update({
        "active": false,

        "closedAt":
            Timestamp.now(),

        "absentCount":
            absentStudents.length,

        "presentCount":
            presentStudentIds.length,

        "className":
            selectedClassName,

        "department":
            department,

        "year":
            selectedYear,

        "section":
            section,
      });

      sessionTimer?.cancel();
      sessionTimer = null;

      if (!mounted) return;

      setState(() {
        sessionActive = false;

        isProcessing = false;
      });

      // ========================================================
      // RESULT
      // ========================================================

      if (automatic) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Session expired. "
              "${absentStudents.length} student(s) "
              "marked Absent.",
            ),
            backgroundColor:
                Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Session closed. "
              "${absentStudents.length} student(s) "
              "marked Absent.",
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Could not mark absent students: $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM CLOSE SESSION
  // ============================================================

  Future<void> confirmCloseSession() async {
    if (!sessionActive) {
      return;
    }

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Close Attendance Session?",
          ),
          content: const Text(
            "Students who have not scanned the QR "
            "will automatically be marked Absent.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                "Close & Mark Absent",
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await closeSessionAndMarkAbsent();
    }
  }

  // ============================================================
  // FILTER AVAILABLE CLASSES
  // ============================================================

  List<String>
      getFilteredClassNames() {
    return classNames.where((item) {
      final detectedDepartment =
          extractDepartmentFromClassName(
        item,
      );

      final detectedSection =
          extractSectionFromClassName(
        item,
      );

      final departmentMatches =
          department == null ||
              detectedDepartment ==
                  department;

      final yearMatches =
          year == null ||
              _classYearMatches(
                item,
                year!,
              );

      if (detectedSection.isEmpty) {
        return false;
      }

      return departmentMatches &&
          yearMatches;
    }).toList();
  }

  // ============================================================
  // CHECK CLASS YEAR
  // ============================================================

  bool _classYearMatches(
    String value,
    String selectedYear,
  ) {
    final normalized =
        value.trim().toUpperCase();

    final masterYear =
        _classYearMap[normalized];

    if (masterYear != null &&
        masterYear.isNotEmpty) {
      return masterYear.toUpperCase() ==
          selectedYear.toUpperCase();
    }

    // If the master document does not contain
    // year information, keep the class visible
    // instead of accidentally hiding it.
    return true;
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final safeValue =
        value != null &&
                items.contains(value)
            ? value
            : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration:
          InputDecoration(
        labelText: hint,
        border:
            const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<String>(
              value: item,
              child:
                  Text(item),
            ),
          )
          .toList(),
      onChanged:
          sessionActive
              ? null
              : onChanged,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    sessionTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final detectedClassDepartment =
        className == null
            ? ""
            : extractDepartmentFromClassName(
                className!,
              );

    final detectedSection =
        className == null
            ? ""
            : extractSectionFromClassName(
                className!,
              );

    final filteredClasses =
        getFilteredClassNames();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Generate Attendance QR",
        ),
        backgroundColor:
            Colors.blue,
        centerTitle: true,
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // DEPARTMENT
            // ==================================================

            buildDropdown(
              "Department",
              department,
              departments,
              (value) {
                setState(() {
                  department =
                      value;

                  if (className != null &&
                      value != null &&
                      extractDepartmentFromClassName(
                            className!,
                          ) !=
                          value) {
                    className =
                        null;
                    section =
                        null;
                  }
                });
              },
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // YEAR
            // ==================================================

            buildDropdown(
              "Year",
              year,
              years,
              (value) {
                setState(() {
                  year =
                      value;

                  if (className != null &&
                      value != null &&
                      !_classYearMatches(
                        className!,
                        value,
                      )) {
                    className =
                        null;
                    section =
                        null;
                  }
                });
              },
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // CLASS NAME
            // ==================================================

            if (isLoadingClasses)
              const Padding(
                padding:
                    EdgeInsets.all(10),
                child:
                    CircularProgressIndicator(),
              )
            else if (classNames.isEmpty)
              Card(
                color:
                    Colors.orange.shade50,
                child:
                    const Padding(
                  padding:
                      EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .warning_amber_rounded,
                        color:
                            Colors.orange,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            Text(
                          "No classes found in the classes collection. "
                          "Run the student Excel importer after adding "
                          "your class information.",
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredClasses.isEmpty)
              Card(
                color:
                    Colors.orange.shade50,
                child:
                    const Padding(
                  padding:
                      EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .warning_amber_rounded,
                        color:
                            Colors.orange,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            Text(
                          "No class is available for the selected "
                          "Department and Year.",
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              buildDropdown(
                "Class Name",
                className,
                filteredClasses,
                (value) {
                  setState(() {
                    className =
                        value;

                    if (value != null) {
                      department =
                          extractDepartmentFromClassName(
                        value,
                      );

                      section =
                          extractSectionFromClassName(
                        value,
                      );
                    }
                  });
                },
              ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // SELECTED CLASS INFORMATION
            // ==================================================

            if (className != null)
              Card(
                color:
                    Colors.blue.shade50,
                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons
                                .school_outlined,
                            color:
                                Colors.blue,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Selected Class",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Class Name: $className",
                      ),
                      Text(
                        "Department: "
                        "$detectedClassDepartment",
                      ),
                      Text(
                        "Section: "
                        "$detectedSection",
                      ),
                      Text(
                        "Year: "
                        "${year ?? "Not selected"}",
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // SUBJECT
            // ==================================================

            if (isLoadingSubjects)
              const Padding(
                padding:
                    EdgeInsets.all(10),
                child:
                    CircularProgressIndicator(),
              )
            else if (subjects.isEmpty)
              Card(
                color:
                    Colors.orange.shade50,
                child:
                    const Padding(
                  padding:
                      EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .warning_amber_rounded,
                        color:
                            Colors.orange,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            Text(
                          "No subjects found. "
                          "Please add a subject from "
                          "Mentor → Subject Management.",
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              buildDropdown(
                "Subject",
                subject,
                subjects,
                (value) {
                  setState(() {
                    subject =
                        value;
                  });
                },
              ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // GENERATE BUTTON
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isProcessing ||
                            sessionActive ||
                            isLoadingSubjects ||
                            isLoadingClasses ||
                            subjects.isEmpty ||
                            classNames.isEmpty
                        ? null
                        : generateQR,
                icon:
                    const Icon(
                  Icons.qr_code,
                ),
                label:
                    Text(
                  isProcessing
                      ? "Processing..."
                      : "Generate QR",
                  style:
                      const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // QR CODE
            // ==================================================

            if (qrData.isNotEmpty)
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    color:
                        Colors.white,
                    child:
                        QrImageView(
                      data:
                          qrData,
                      version:
                          QrVersions.auto,
                      size: 280,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // SESSION STATUS
                  // ==================================================

                  Card(
                    color:
                        sessionActive
                            ? Colors.green
                                .shade50
                            : Colors.grey
                                .shade200,
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      child:
                          Column(
                        children: [
                          Icon(
                            sessionActive
                                ? Icons
                                    .check_circle
                                : Icons.cancel,
                            color:
                                sessionActive
                                    ? Colors
                                        .green
                                    : Colors
                                        .grey,
                            size: 45,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            sessionActive
                                ? "Attendance Session Active"
                                : "Attendance Session Closed",
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  18,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            "Students can scan this QR "
                            "to mark Present.",
                            textAlign:
                                TextAlign.center,
                          ),
                          if (sessionActive) ...[
                            const SizedBox(
                              height: 8,
                            ),
                            const Text(
                              "Session automatically closes "
                              "after 10 minutes.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // SESSION DETAILS
                  // ==================================================

                  Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      child:
                          Column(
                        children: [
                          const Text(
                            "Attendance Session",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  18,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Class Name : $className",
                          ),
                          Text(
                            "Department : $department",
                          ),
                          Text(
                            "Year : $year",
                          ),
                          Text(
                            "Section : $section",
                          ),
                          Text(
                            "Subject : $subject",
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Generated : "
                            "${DateFormat(
                              "dd MMM yyyy • hh:mm a",
                            ).format(
                              DateTime.now(),
                            )}",
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // CLOSE SESSION
                  // ==================================================

                  if (sessionActive)
                    SizedBox(
                      width:
                          double.infinity,
                      height: 55,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            isProcessing
                                ? null
                                : confirmCloseSession,
                        icon:
                            const Icon(
                          Icons
                              .stop_circle,
                        ),
                        label:
                            Text(
                          isProcessing
                              ? "Marking Attendance..."
                              : "Close Session & Mark Absent",
                          style:
                              const TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.red,
                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  // ==================================================
                  // INFORMATION
                  // ==================================================

                  if (sessionActive)
                    const Card(
                      child:
                          Padding(
                        padding:
                            EdgeInsets.all(
                          15,
                        ),
                        child:
                            Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline,
                              color:
                                  Colors.blue,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  Text(
                                "When the session is closed, "
                                "every student in this Class Name "
                                "who did not scan the QR will "
                                "automatically receive an "
                                "Absent record.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}