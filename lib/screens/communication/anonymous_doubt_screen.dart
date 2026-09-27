import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'anonymous_video_call_screen.dart';

class AnonymousDoubtScreen extends StatefulWidget {
  final String subject;

  const AnonymousDoubtScreen({
    super.key,
    required this.subject,
  });

  @override
  State<AnonymousDoubtScreen> createState() =>
      _AnonymousDoubtScreenState();
}

class _AnonymousDoubtScreenState
    extends State<AnonymousDoubtScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  bool isSending = false;

  // ==========================================================
  // GET STUDENT PROFILE
  // ==========================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      getStudentProfile() async {
    final user = auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await firestore
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

    return result.docs.first;
  }

  // ==========================================================
  // SEND MESSAGE
  //
  // Public message:
  // anonymous_doubt_messages/{messageId}
  //
  // Private identity:
  // anonymous_doubt_messages/{messageId}/private/student
  //
  // Student identity is NOT stored in the public message.
  // ==========================================================

  Future<void> sendMessage() async {
    if (isSending) {
      return;
    }

    final message =
        messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    final user = auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please login first.",
          ),
        ),
      );

      return;
    }

    final subject =
        widget.subject.trim();

    if (subject.isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      // ======================================================
      // GET STUDENT PROFILE
      // ======================================================

      final userDoc =
          await getStudentProfile();

      if (userDoc == null) {
        throw Exception(
          "Your user profile was not found in Firestore.",
        );
      }

      final userData =
          userDoc.data();

      final String studentName =
          userData["name"]
                  ?.toString()
                  .trim() ??
              "";

      final String registerNo =
          userData["registerNo"]
                  ?.toString()
                  .trim() ??
              "";

      if (studentName.isEmpty) {
        throw Exception(
          "Student name is missing from your profile.",
        );
      }

      if (registerNo.isEmpty) {
        throw Exception(
          "Register number is missing from your profile.",
        );
      }

      // ======================================================
      // CREATE MESSAGE REFERENCE
      // ======================================================

      final messageRef = firestore
          .collection(
            "anonymous_doubt_messages",
          )
          .doc();

      // ======================================================
      // FIRESTORE BATCH
      //
      // PUBLIC MESSAGE
      // ----------------
      // No student name
      // No register number
      // No student UID
      //
      // PRIVATE IDENTITY
      // ----------------
      // Stored separately under:
      //
      // {messageId}/private/student
      // ======================================================

      final batch =
          firestore.batch();

      // ======================================================
      // PUBLIC ANONYMOUS MESSAGE
      // ======================================================

      batch.set(
        messageRef,
        {
          "subject": subject,
          "message": message,
          "senderType": "student",
          "createdAt":
              FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // PRIVATE STUDENT IDENTITY
      //
      // This document must later be protected by Firestore
      // security rules so students cannot read it.
      // ======================================================

      final privateStudentRef =
          messageRef
              .collection("private")
              .doc("student");

      batch.set(
        privateStudentRef,
        {
          "studentUid": user.uid,
          "studentName": studentName,
          "registerNo": registerNo,
        },
      );

      // ======================================================
      // COMMIT BOTH WRITES TOGETHER
      // ======================================================

      await batch.commit();

      messageController.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          content: Text(
            "Message sent.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to send message:\n$e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
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
  // STUDENT MESSAGE
  // ==========================================================

  Widget buildStudentMessage(
    Map<String, dynamic> data,
  ) {
    final message =
        data["message"]
                ?.toString() ??
            "";

    final timestamp =
        data["createdAt"]
                is Timestamp
            ? data["createdAt"]
                as Timestamp
            : null;

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(context)
                      .width *
                  0.82,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
          left: 10,
          right: 40,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha:
                    0.05,
              ),
              blurRadius:
                  4,
            ),
          ],
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.visibility_off,
                  size: 16,
                  color:
                      Colors.red,
                ),
                SizedBox(
                  width: 6,
                ),
                Text(
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
              height: 6,
            ),
            Text(
              message,
              style:
                  const TextStyle(
                fontSize:
                    15,
              ),
            ),
            if (timestamp != null)
              Align(
                alignment:
                    Alignment.bottomRight,
                child:
                    Text(
                  formatTime(
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
  // TEACHER MESSAGE
  // ==========================================================

  Widget buildTeacherMessage(
    Map<String, dynamic> data,
  ) {
    final message =
        data["message"]
                ?.toString() ??
            "";

    final timestamp =
        data["createdAt"]
                is Timestamp
            ? data["createdAt"]
                as Timestamp
            : null;

    return Align(
      alignment:
          Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(context)
                      .width *
                  0.82,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
          left: 40,
          right: 10,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.green.shade50,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border:
              Border.all(
            color:
                Colors.green.shade100,
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  size: 16,
                  color:
                      Colors.green.shade700,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  "Teacher",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.green.shade700,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              message,
              style:
                  const TextStyle(
                fontSize:
                    15,
              ),
            ),
            if (timestamp != null)
              Align(
                alignment:
                    Alignment.bottomRight,
                child:
                    Text(
                  formatTime(
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
  // OPEN VIDEO CALL
  // ==========================================================

  void openVideoCall() {
    final subject =
        widget.subject.trim();

    if (subject.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnonymousVideoCallScreen(
          subject: subject,
        ),
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
    final user =
        auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body:
            Center(
          child:
              Text(
            "Please login first.",
          ),
        ),
      );
    }

    final messagesStream =
        firestore
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
          widget.subject,
        ),
        centerTitle:
            true,
        backgroundColor:
            Colors.red,
        foregroundColor:
            Colors.white,

        // ======================================================
        // VIDEO CALL BUTTON
        // ======================================================

        actions: [
          IconButton(
            tooltip:
                "Anonymous video call",
            icon:
                const Icon(
              Icons.videocam_rounded,
            ),
            onPressed:
                openVideoCall,
          ),
          const SizedBox(
            width:
                5,
          ),
        ],
      ),

      body:
          Column(
        children: [
          // ====================================================
          // PRIVACY INFO
          // ====================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              12,
            ),
            color:
                Colors.red.withValues(
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
                  Icons.visibility_off,
                  color:
                      Colors.red,
                ),
                SizedBox(
                  width:
                      10,
                ),
                Expanded(
                  child:
                      Text(
                    "Your identity is hidden from other students. "
                    "The subject teacher can see your name and register number.",
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

          // ====================================================
          // CHAT
          // ====================================================

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream:
                  messagesStream,
              builder:
                  (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
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

                if (snapshot.connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data?.docs ?? [];

                // ------------------------------------------------
                // SORT BY CREATED TIME
                // ------------------------------------------------

                messages.sort(
                  (a, b) {
                    final aData =
                        a.data()
                            as Map<String,
                                dynamic>;

                    final bData =
                        b.data()
                            as Map<String,
                                dynamic>;

                    final aTime =
                        aData[
                            "createdAt"];

                    final bTime =
                        bData[
                            "createdAt"];

                    if (aTime is Timestamp &&
                        bTime is Timestamp) {
                      return aTime.compareTo(
                        bTime,
                      );
                    }

                    return 0;
                  },
                );

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
                          "No doubts yet",
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
                          "Ask the first question!",
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
                            .data()
                            as Map<
                                String,
                                dynamic>;

                    final senderType =
                        data[
                                "senderType"]
                            ?.toString();

                    if (senderType ==
                        "teacher") {
                      return buildTeacherMessage(
                        data,
                      );
                    }

                    return buildStudentMessage(
                      data,
                    );
                  },
                );
              },
            ),
          ),

          // ====================================================
          // INPUT
          // ====================================================

          SafeArea(
            child:
                Container(
              padding:
                  const EdgeInsets.fromLTRB(
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
                            "Ask your doubt...",
                        prefixIcon:
                            const Icon(
                          Icons
                              .help_outline,
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
                              BorderRadius.circular(
                            25,
                          ),
                          borderSide:
                              BorderSide.none,
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
                        if (!isSending) {
                          sendMessage();
                        }
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
                        Colors.red,
                    child:
                        IconButton(
                      onPressed:
                          isSending
                              ? null
                              : sendMessage,
                      icon:
                          isSending
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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}