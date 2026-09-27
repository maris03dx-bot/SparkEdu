import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnonymousDoubtsTeacherScreen extends StatelessWidget {
  const AnonymousDoubtsTeacherScreen({
    super.key,
  });

  // ==========================================================
  // GET CURRENT TEACHER PROFILE
  //
  // Your users collection uses Auto-ID documents.
  // Therefore we search by the "uid" field.
  // ==========================================================

  Future<Map<String, dynamic>?> getTeacherProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final result = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first.data();
  }

  // ==========================================================
  // NORMALIZE TEACHER NAME
  // ==========================================================

  String normalizeTeacherName(String name) {
    String value = name.trim().toLowerCase();

    value = value.replaceAll(
      RegExp(r'\bdr\.?\s*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\bprof\.?\s*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\bmr\.?\s*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\bms\.?\s*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\bmiss\.?\s*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return value.trim();
  }

  // ==========================================================
  // CHECK WHETHER SUBJECT BELONGS TO TEACHER
  // ==========================================================

  bool isSubjectAssignedToTeacher({
    required String subjectTeacher,
    required String teacherName,
  }) {
    final subjectTeacherNormalized =
        normalizeTeacherName(
      subjectTeacher,
    );

    final teacherNameNormalized =
        normalizeTeacherName(
      teacherName,
    );

    return subjectTeacherNormalized ==
        teacherNameNormalized;
  }

  // ==========================================================
  // SEND TEACHER MESSAGE
  //
  // Teacher messages are public chat messages.
  // No student identity is attached.
  // ==========================================================

  Future<void> sendTeacherMessage({
    required BuildContext context,
    required String subject,
    required String message,
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final teacherProfile =
          await getTeacherProfile();

      if (teacherProfile == null) {
        throw Exception(
          "Teacher profile not found.",
        );
      }

      final teacherName =
          teacherProfile["name"]
                  ?.toString()
                  .trim() ??
              "Teacher";

      await FirebaseFirestore.instance
          .collection(
            "anonymous_doubt_messages",
          )
          .add({
        // ------------------------------------------------------
        // SUBJECT
        // ------------------------------------------------------

        "subject": subject,

        // ------------------------------------------------------
        // MESSAGE
        // ------------------------------------------------------

        "message": cleanMessage,

        // ------------------------------------------------------
        // SENDER TYPE
        // ------------------------------------------------------

        "senderType": "teacher",

        // ------------------------------------------------------
        // INTERNAL TEACHER INFORMATION
        //
        // This remains internal.
        // Students only display "Teacher".
        // ------------------------------------------------------

        "teacherUid": user.uid,
        "teacherName": teacherName,

        // ------------------------------------------------------
        // CREATED TIME
        // ------------------------------------------------------

        "createdAt":
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.red,
          content: Text(
            "Failed to send message:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // FORMAT TIME
  // ==========================================================

  String formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return "";
    }

    final date =
        timestamp.toDate();

    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute
            .toString()
            .padLeft(
          2,
          "0",
        );

    final period =
        date.hour >= 12
            ? "PM"
            : "AM";

    return "$hour:$minute $period";
  }

  // ==========================================================
  // OPEN SUBJECT CHAT
  // ==========================================================

  Widget buildTeacherChat(
    BuildContext context,
    String subject,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$subject Anonymous Doubts",
        ),
        centerTitle: true,
        backgroundColor:
            Colors.blue,
        foregroundColor:
            Colors.white,
      ),
      body: _TeacherAnonymousChat(
        subject: subject,
        sendMessage:
            sendTeacherMessage,
        formatTime:
            formatTime,
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<
        Map<String, dynamic>?>(
      future:
          getTeacherProfile(),
      builder:
          (
        context,
        teacherSnapshot,
      ) {
        // ====================================================
        // LOADING TEACHER
        // ====================================================

        if (teacherSnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            appBar:
                AppBar(
              title:
                  const Text(
                "Anonymous Doubts",
              ),
              backgroundColor:
                  Colors.blue,
              foregroundColor:
                  Colors.white,
            ),
            body:
                const Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        // ====================================================
        // ERROR
        // ====================================================

        if (teacherSnapshot.hasError) {
          return Scaffold(
            appBar:
                AppBar(
              title:
                  const Text(
                "Anonymous Doubts",
              ),
              backgroundColor:
                  Colors.blue,
              foregroundColor:
                  Colors.white,
            ),
            body:
                Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    Text(
                  "Error loading teacher profile:\n\n"
                  "${teacherSnapshot.error}",
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),
          );
        }

        final teacher =
            teacherSnapshot.data;

        if (teacher == null) {
          return Scaffold(
            appBar:
                AppBar(
              title:
                  const Text(
                "Anonymous Doubts",
              ),
              backgroundColor:
                  Colors.blue,
              foregroundColor:
                  Colors.white,
            ),
            body:
                const Center(
              child:
                  Text(
                "Teacher profile not found.",
                style:
                    TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          );
        }

        final String teacherName =
            teacher["name"]
                    ?.toString()
                    .trim() ??
                "";

        final String department =
            teacher["department"]
                    ?.toString()
                    .trim() ??
                "";

        if (teacherName.isEmpty) {
          return Scaffold(
            appBar:
                AppBar(
              title:
                  const Text(
                "Anonymous Doubts",
              ),
              backgroundColor:
                  Colors.blue,
              foregroundColor:
                  Colors.white,
            ),
            body:
                const Center(
              child:
                  Text(
                "Teacher name is missing.",
              ),
            ),
          );
        }

        // ====================================================
        // LOAD SUBJECTS
        //
        // We load by department first and then compare teacher
        // names locally.
        //
        // This handles:
        //
        // users → "Kumar"
        // subjects → "Dr. Kumar"
        // ====================================================

        Query<
                Map<String, dynamic>>
            subjectQuery =
            FirebaseFirestore.instance
                .collection(
          "subjects",
        );

        if (department.isNotEmpty) {
          subjectQuery =
              subjectQuery.where(
            "department",
            isEqualTo:
                department,
          );
        }

        return Scaffold(
          appBar:
              AppBar(
            title:
                const Text(
              "Anonymous Doubts",
            ),
            centerTitle:
                true,
            backgroundColor:
                Colors.blue,
            foregroundColor:
                Colors.white,
          ),
          body:
              StreamBuilder<
                  QuerySnapshot<
                      Map<String,
                          dynamic>>>(
            stream:
                subjectQuery
                    .snapshots(),
            builder:
                (
              context,
              subjectSnapshot,
            ) {
              // ==================================================
              // LOADING
              // ==================================================

              if (subjectSnapshot
                      .connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              // ==================================================
              // ERROR
              // ==================================================

              if (subjectSnapshot
                  .hasError) {
                return Center(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child:
                        Text(
                      "Error loading subjects:\n\n"
                      "${subjectSnapshot.error}",
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                );
              }

              // ==================================================
              // FILTER SUBJECTS FOR CURRENT TEACHER
              // ==================================================

              final assignedSubjects =
                  subjectSnapshot
                          .data
                          ?.docs
                          .where(
                            (
                              doc,
                            ) {
                              final data =
                                  doc.data();

                              final subjectTeacher =
                                  data[
                                          "teacher"]
                                      ?.toString()
                                      .trim() ??
                                  "";

                              return isSubjectAssignedToTeacher(
                                subjectTeacher:
                                    subjectTeacher,
                                teacherName:
                                    teacherName,
                              );
                            },
                          )
                          .toList() ??
                      [];

              // ==================================================
              // REMOVE DUPLICATE SUBJECT NAMES
              // ==================================================

              final Map<
                      String,
                      QueryDocumentSnapshot<
                          Map<String,
                              dynamic>>>
                  uniqueSubjects =
                  {};

              for (final doc
                  in assignedSubjects) {
                final data =
                    doc.data();

                final subjectName =
                    data["name"]
                            ?.toString()
                            .trim() ??
                        "";

                if (subjectName
                    .isNotEmpty) {
                  uniqueSubjects[
                          subjectName] =
                      doc;
                }
              }

              final subjects =
                  uniqueSubjects
                      .values
                      .toList();

              // ==================================================
              // NO SUBJECTS
              // ==================================================

              if (subjects.isEmpty) {
                return Center(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons
                              .menu_book_outlined,
                          size:
                              75,
                          color:
                              Colors.grey,
                        ),
                        const SizedBox(
                          height:
                              15,
                        ),
                        const Text(
                          "No Assigned Subjects",
                          style:
                              TextStyle(
                            fontSize:
                                21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height:
                              10,
                        ),
                        Text(
                          "No subjects are assigned to "
                          "$teacherName"
                          "${department.isEmpty ? "" : " ($department)"}",
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ==================================================
              // SUBJECT LIST
              // ==================================================

              return ListView.builder(
                padding:
                    const EdgeInsets.all(
                  15,
                ),
                itemCount:
                    subjects.length,
                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final data =
                      subjects[index]
                          .data();

                  final String subjectName =
                      data["name"]
                              ?.toString()
                              .trim() ??
                          "Subject";

                  final String code =
                      data["code"]
                              ?.toString()
                              .trim() ??
                          "N/A";

                  final String year =
                      data["year"]
                              ?.toString()
                              .trim() ??
                          "";

                  final String section =
                      data["section"]
                              ?.toString()
                              .trim() ??
                          "";

                  return Card(
                    elevation:
                        4,
                    margin:
                        const EdgeInsets.only(
                      bottom:
                          12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child:
                        ListTile(
                      contentPadding:
                          const EdgeInsets.all(
                        14,
                      ),
                      leading:
                          Container(
                        width:
                            52,
                        height:
                            52,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.blue
                                  .withValues(
                            alpha:
                                0.10,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .visibility_off_rounded,
                          color:
                              Colors.blue,
                          size:
                              28,
                        ),
                      ),
                      title:
                          Text(
                        subjectName,
                        style:
                            const TextStyle(
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const SizedBox(
                            height:
                                4,
                          ),
                          Text(
                            "Code: $code",
                          ),
                          if (year.isNotEmpty ||
                              section.isNotEmpty)
                            const SizedBox(
                              height:
                                  3,
                            ),
                          if (year.isNotEmpty ||
                              section.isNotEmpty)
                            Text(
                              "Class: "
                              "$year"
                              "${section.isEmpty ? "" : " • Section $section"}",
                            ),
                          const SizedBox(
                            height:
                                4,
                          ),
                          const Text(
                            "Open anonymous group chat",
                            style:
                                TextStyle(
                              color:
                                  Colors.blue,
                              fontSize:
                                  12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size:
                            17,
                      ),
                      onTap:
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    buildTeacherChat(
                              context,
                              subjectName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// =================================================================
// TEACHER CHAT WIDGET
// =================================================================

class _TeacherAnonymousChat
    extends StatefulWidget {
  final String subject;

  final Future<void> Function({
    required BuildContext context,
    required String subject,
    required String message,
  }) sendMessage;

  final String Function(
    Timestamp?,
  ) formatTime;

  const _TeacherAnonymousChat({
    required this.subject,
    required this.sendMessage,
    required this.formatTime,
  });

  @override
  State<
      _TeacherAnonymousChat> createState() =>
      _TeacherAnonymousChatState();
}

class _TeacherAnonymousChatState
    extends State<
        _TeacherAnonymousChat> {
  final TextEditingController
      messageController =
      TextEditingController();

  bool sending = false;

  // ==========================================================
  // SEND
  // ==========================================================

  Future<void> handleSend() async {
    if (sending) {
      return;
    }

    final message =
        messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      sending = true;
    });

    try {
      await widget.sendMessage(
        context:
            context,
        subject:
            widget.subject,
        message:
            message,
      );

      if (!mounted) {
        return;
      }

      messageController.clear();
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  // ==========================================================
  // LOAD PRIVATE STUDENT IDENTITY
  //
  // New structure:
  //
  // anonymous_doubt_messages/{messageId}/private/student
  //
  // Legacy messages are supported as a fallback.
  // ==========================================================

  Future<Map<String, dynamic>>
      getStudentIdentity(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        messageDoc,
  ) async {
    final data =
        messageDoc.data();

    // ========================================================
    // NEW SECURE STRUCTURE
    // ========================================================

    try {
      final privateStudentSnapshot =
          await messageDoc.reference
              .collection(
                "private",
              )
              .doc(
                "student",
              )
              .get();

      if (privateStudentSnapshot
          .exists) {
        final privateData =
            privateStudentSnapshot
                .data();

        if (privateData != null) {
          return {
            "studentName":
                privateData[
                        "studentName"]
                    ?.toString()
                    .trim() ??
                "",
            "registerNo":
                privateData[
                        "registerNo"]
                    ?.toString()
                    .trim() ??
                "",
          };
        }
      }
    } catch (_) {
      // ------------------------------------------------------
      // The Firestore security rules will later control access
      // to the private identity document.
      //
      // If access is denied, we return unavailable identity
      // instead of crashing the chat screen.
      // ------------------------------------------------------

      return {
        "studentName": "",
        "registerNo": "",
      };
    }

    // ========================================================
    // LEGACY STRUCTURE
    //
    // Existing old messages may still contain:
    //
    // studentName
    // registerNo
    // studentUid
    //
    // Keep this fallback so old chat history still works.
    // ========================================================

    return {
      "studentName":
          data["studentName"]
                  ?.toString()
                  .trim() ??
              "",
      "registerNo":
          data["registerNo"]
                  ?.toString()
                  .trim() ??
              "",
    };
  }

  // ==========================================================
  // STUDENT MESSAGE
  //
  // Teacher sees identity.
  // Students do not see this screen.
  // ==========================================================

  Widget buildStudentMessage(
    BuildContext context,
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        messageDoc,
  ) {
    final data =
        messageDoc.data();

    final String message =
        data["message"]
                ?.toString() ??
            "";

    final Timestamp? timestamp =
        data["createdAt"]
                is Timestamp
            ? data["createdAt"]
                as Timestamp
            : null;

    return FutureBuilder<
        Map<String, dynamic>>(
      future:
          getStudentIdentity(
        messageDoc,
      ),
      builder:
          (
        context,
        identitySnapshot,
      ) {
        String studentName =
            "Name not available";

        String registerNo =
            "Register No not available";

        if (identitySnapshot
                .connectionState ==
            ConnectionState.done) {
          final identity =
              identitySnapshot.data;

          if (identity !=
              null) {
            final storedName =
                identity[
                            "studentName"]
                        ?.toString()
                        .trim() ??
                    "";

            final storedRegisterNo =
                identity[
                            "registerNo"]
                        ?.toString()
                        .trim() ??
                    "";

            if (storedName
                .isNotEmpty) {
              studentName =
                  storedName;
            }

            if (storedRegisterNo
                .isNotEmpty) {
              registerNo =
                  storedRegisterNo;
            }
          }
        }

        return Align(
          alignment:
              Alignment.centerLeft,
          child:
              Container(
            constraints:
                BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(
                            context,
                          ).width *
                      0.86,
            ),
            margin:
                const EdgeInsets.only(
              left:
                  10,
              right:
                  30,
              bottom:
                  10,
            ),
            padding:
                const EdgeInsets.all(
              13,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              border:
                  Border.all(
                color:
                    Colors.red.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha:
                        0.04,
                  ),
                  blurRadius:
                      4,
                ),
              ],
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                // ==============================================
                // ANONYMOUS LABEL
                // ==============================================

                Row(
                  children: [
                    const Icon(
                      Icons
                          .visibility_off,
                      size:
                          17,
                      color:
                          Colors.red,
                    ),
                    const SizedBox(
                      width:
                          6,
                    ),
                    const Text(
                      "Anonymous Student",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.red,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      5,
                ),

                // ==============================================
                // TEACHER-ONLY IDENTITY
                // ==============================================

                Text(
                  "Name: $studentName",
                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    color:
                        Colors.grey,
                  ),
                ),

                Text(
                  "Register No: $registerNo",
                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height:
                      7,
                ),

                // ==============================================
                // MESSAGE
                // ==============================================

                Text(
                  message,
                  style:
                      const TextStyle(
                    fontSize:
                        15,
                  ),
                ),

                if (timestamp !=
                    null)
                  Align(
                    alignment:
                        Alignment
                            .bottomRight,
                    child:
                        Text(
                      widget.formatTime(
                        timestamp,
                      ),
                      style:
                          const TextStyle(
                        fontSize:
                            10,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // TEACHER MESSAGE
  // ==========================================================

  Widget buildTeacherMessage(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String message =
        data["message"]
                ?.toString() ??
            "";

    final Timestamp? timestamp =
        data["createdAt"] is Timestamp
            ? data["createdAt"]
                as Timestamp
            : null;

    return Align(
      alignment:
          Alignment.centerRight,
      child:
          Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(
                    context,
                  ).width *
                  0.82,
        ),
        margin:
            const EdgeInsets.only(
          left:
              40,
          right:
              10,
          bottom:
              10,
        ),
        padding:
            const EdgeInsets.all(
          13,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.blue.shade50,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border:
              Border.all(
            color:
                Colors.blue.shade100,
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  size:
                      17,
                  color:
                      Colors.blue.shade700,
                ),
                const SizedBox(
                  width:
                      6,
                ),
                Text(
                  "Teacher",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.blue.shade700,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height:
                  6,
            ),
            Text(
              message,
              style:
                  const TextStyle(
                fontSize:
                    15,
              ),
            ),
            if (timestamp !=
                null)
              Align(
                alignment:
                    Alignment.bottomRight,
                child:
                    Text(
                  widget.formatTime(
                    timestamp,
                  ),
                  style:
                      const TextStyle(
                    fontSize:
                        10,
                    color:
                        Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD CHAT
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final messagesStream =
        FirebaseFirestore.instance
            .collection(
              "anonymous_doubt_messages",
            )
            .where(
              "subject",
              isEqualTo:
                  widget.subject,
            )
            .snapshots();

    return Scaffold(
      appBar:
          AppBar(
        title:
            Text(
          "${widget.subject} Anonymous Doubts",
        ),
        backgroundColor:
            Colors.blue,
        foregroundColor:
            Colors.white,
      ),
      body:
          Column(
        children: [
          // ==================================================
          // INFO
          // ==================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              12,
            ),
            color:
                Colors.blue.withValues(
              alpha:
                  0.08,
            ),
            child:
                const Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Icon(
                  Icons
                      .visibility_off,
                  color:
                      Colors.blue,
                ),
                SizedBox(
                  width:
                      10,
                ),
                Expanded(
                  child:
                      Text(
                    "You can see each student's name and register number. "
                    "Students see only anonymous identities.",
                    style:
                        TextStyle(
                      fontSize:
                          12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // CHAT
          // ==================================================

          Expanded(
            child:
                StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
              stream:
                  messagesStream,
              builder:
                  (
                context,
                snapshot,
              ) {
                if (snapshot
                    .hasError) {
                  return Center(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child:
                          Text(
                        "Error loading chat:\n"
                        "${snapshot.error}",
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data?.docs
                            .toList() ??
                        [];

                // ==================================================
                // SORT BY TIME
                // ==================================================

                messages.sort(
                  (
                    a,
                    b,
                  ) {
                    final aData =
                        a.data();

                    final bData =
                        b.data();

                    final aTime =
                        aData[
                            "createdAt"];

                    final bTime =
                        bData[
                            "createdAt"];

                    if (aTime
                            is Timestamp &&
                        bTime
                            is Timestamp) {
                      return aTime
                          .compareTo(
                        bTime,
                      );
                    }

                    return 0;
                  },
                );

                // ==================================================
                // EMPTY
                // ==================================================

                if (messages.isEmpty) {
                  return const Center(
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .forum_outlined,
                          size:
                              65,
                          color:
                              Colors.grey,
                        ),
                        SizedBox(
                          height:
                              12,
                        ),
                        Text(
                          "No messages yet",
                          style:
                              TextStyle(
                            fontSize:
                                19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height:
                              6,
                        ),
                        Text(
                          "You can start the discussion.",
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.only(
                    top:
                        15,
                    bottom:
                        15,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final data =
                        messages[index]
                            .data();

                    final senderType =
                        data[
                                "senderType"]
                            ?.toString() ??
                        "student";

                    if (senderType ==
                        "teacher") {
                      return buildTeacherMessage(
                        context,
                        data,
                      );
                    }

                    return buildStudentMessage(
                      context,
                      messages[index],
                    );
                  },
                );
              },
            ),
          ),

          // ==================================================
          // INPUT
          // ==================================================

          SafeArea(
            child:
                Container(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                10,
                8,
                10,
                8,
              ),
              color:
                  Colors.white,
              child:
                  Row(
                children: [
                  Expanded(
                    child:
                        TextField(
                      controller:
                          messageController,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      minLines:
                          1,
                      maxLines:
                          4,
                      decoration:
                          InputDecoration(
                        hintText:
                            "Type a message...",
                        prefixIcon:
                            const Icon(
                          Icons
                              .chat_bubble_outline,
                        ),
                        filled:
                            true,
                        fillColor:
                            Colors.grey
                                .withValues(
                          alpha:
                              0.06,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            25,
                          ),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              16,
                          vertical:
                              10,
                        ),
                      ),
                      onSubmitted:
                          (_) {
                        handleSend();
                      },
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  CircleAvatar(
                    radius:
                        25,
                    backgroundColor:
                        Colors.blue,
                    child:
                        IconButton(
                      onPressed:
                          sending
                              ? null
                              : handleSend,
                      icon:
                          sending
                              ? const SizedBox(
                                  width:
                                      20,
                                  height:
                                      20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color:
                                      Colors.white,
                                ),
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

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}