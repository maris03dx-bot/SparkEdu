import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupDiscussionScreen extends StatefulWidget {
  final String subjectName;

  const GroupDiscussionScreen({
    super.key,
    required this.subjectName,
  });

  @override
  State<GroupDiscussionScreen> createState() =>
      _GroupDiscussionScreenState();
}

class _GroupDiscussionScreenState
    extends State<GroupDiscussionScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final TextEditingController controller =
      TextEditingController();

  bool sending = false;

  // ============================================================
  // GET CURRENT USER DETAILS
  // ============================================================

  Future<Map<String, String>> getCurrentUserDetails() async {
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return {
        "uid": "",
        "name": "User",
        "role": "Student",
      };
    }

    String name =
        currentUser.displayName ??
        currentUser.email ??
        "User";

    String role = "Student";

    try {
      final query = await firestore
          .collection("users")
          .where(
            "uid",
            isEqualTo: currentUser.uid,
          )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();

        name =
            data["name"]?.toString() ??
            name;

        role =
            data["role"]?.toString() ??
            "Student";
      }
    } catch (e) {
      debugPrint(
        "Could not load user details: $e",
      );
    }

    return {
      "uid": currentUser.uid,
      "name": name,
      "role": role,
    };
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    final String message =
        controller.text.trim();

    if (message.isEmpty) {
      return;
    }

    if (sending) {
      return;
    }

    final User? currentUser =
        auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please login before sending messages.",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      sending = true;
    });

    try {
      final userDetails =
          await getCurrentUserDetails();

      await firestore
          .collection("subject_chats")
          .add({
        "subjectName":
            widget.subjectName,

        "senderUid":
            userDetails["uid"],

        "senderName":
            userDetails["name"],

        "senderRole":
            userDetails["role"],

        "text":
            message,

        "createdAt":
            FieldValue.serverTimestamp(),
      });

      controller.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        sending = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        sending = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to send message: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget buildMessage(
    BuildContext context,
    DocumentSnapshot document,
  ) {
    final Map<String, dynamic> data =
        document.data()
                as Map<String, dynamic>? ??
            {};

    final String senderUid =
        data["senderUid"]?.toString() ??
            "";

    final String senderName =
        data["senderName"]?.toString() ??
            "User";

    final String senderRole =
        data["senderRole"]?.toString() ??
            "Student";

    final String text =
        data["text"]?.toString() ??
            "";

    final User? currentUser =
        auth.currentUser;

    final bool isMe =
        currentUser != null &&
        senderUid == currentUser.uid;

    final bool isTeacher =
        senderRole.toLowerCase() ==
                "subject teacher" ||
        senderRole.toLowerCase() ==
                "teacher";

    Timestamp? timestamp;

    if (data["createdAt"] is Timestamp) {
      timestamp =
          data["createdAt"] as Timestamp;
    }

    final String time =
        timestamp != null
            ? _formatTime(
                timestamp.toDate(),
              )
            : "";

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.78,
        ),
        margin:
            const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 10,
        ),
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blue
              : Colors.grey.shade200,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(16),
            topRight:
                const Radius.circular(16),
            bottomLeft:
                Radius.circular(
              isMe ? 16 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMe ? 4 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // SENDER NAME
            // --------------------------------------------------

            if (!isMe)
              Row(
                children: [
                  Icon(
                    isTeacher
                        ? Icons.school
                        : Icons.person,
                    size: 16,
                    color: isTeacher
                        ? Colors.orange
                        : Colors.blue,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Flexible(
                    child: Text(
                      senderName,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: isTeacher
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    senderRole,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

            if (!isMe)
              const SizedBox(
                height: 6,
              ),

            // --------------------------------------------------
            // MESSAGE
            // --------------------------------------------------

            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isMe
                    ? Colors.white
                    : Colors.black87,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            // --------------------------------------------------
            // TIME
            // --------------------------------------------------

            if (time.isNotEmpty)
              Align(
                alignment:
                    Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(
    DateTime dateTime,
  ) {
    int hour =
        dateTime.hour;

    final int minute =
        dateTime.minute;

    final String period =
        hour >= 12
            ? "PM"
            : "AM";

    hour =
        hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return "$hour:${minute.toString().padLeft(2, '0')} $period";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subjectName,
        ),
        backgroundColor:
            Colors.blue,
        foregroundColor:
            Colors.white,
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ======================================================
          // SUBJECT HEADER
          // ======================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            color:
                Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.blue,
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      const Text(
                        "Subject Group Discussion",
                        style: TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // MESSAGES
          // ======================================================

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection(
                    "subject_chats",
                  )
                  .where(
                    "subjectName",
                    isEqualTo:
                        widget.subjectName,
                  )
                  .snapshots(),

              builder:
                  (context, snapshot) {
                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Text(
                        "Error loading messages:\n\n"
                        "${snapshot.error}",
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data?.docs
                            .toList() ??
                        [];

                // ------------------------------------------------
                // SORT MESSAGES
                //
                // We sort in Flutter so we don't need
                // a Firestore composite index.
                // ------------------------------------------------

                messages.sort(
                  (a, b) {
                    final dataA =
                        a.data()
                                as Map<String, dynamic>? ??
                            {};

                    final dataB =
                        b.data()
                                as Map<String, dynamic>? ??
                            {};

                    final Timestamp?
                        timeA =
                        dataA["createdAt"]
                                is Timestamp
                            ? dataA[
                                "createdAt"]
                            as Timestamp
                            : null;

                    final Timestamp?
                        timeB =
                        dataB["createdAt"]
                                is Timestamp
                            ? dataB[
                                "createdAt"]
                            as Timestamp
                            : null;

                    if (timeA == null &&
                        timeB == null) {
                      return 0;
                    }

                    if (timeA == null) {
                      return -1;
                    }

                    if (timeB == null) {
                      return 1;
                    }

                    return timeA
                        .compareTo(
                      timeB,
                    );
                  },
                );

                // ------------------------------------------------
                // EMPTY CHAT
                // ------------------------------------------------

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons
                                .chat_bubble_outline,
                            size: 70,
                            color: Colors
                                .grey
                                .shade400,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Text(
                            "No messages yet",
                            style:
                                TextStyle(
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            "Start the discussion "
                            "for this subject.",
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ------------------------------------------------
                // MESSAGE LIST
                // ------------------------------------------------

                return ListView.builder(
                  padding:
                      const EdgeInsets.only(
                    top: 15,
                    bottom: 15,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    return buildMessage(
                      context,
                      messages[index],
                    );
                  },
                );
              },
            ),
          ),

          // ======================================================
          // MESSAGE INPUT
          // ======================================================

          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                8,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 5,
                    offset:
                        const Offset(
                      0,
                      -2,
                    ),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  // ------------------------------------------------
                  // TEXT FIELD
                  // ------------------------------------------------

                  Expanded(
                    child: TextField(
                      controller:
                          controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction:
                          TextInputAction.newline,
                      decoration:
                          InputDecoration(
                        hintText:
                            "Type a message...",
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            25,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // ------------------------------------------------
                  // SEND BUTTON
                  // ------------------------------------------------

                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Colors.blue,
                    child: IconButton(
                      onPressed:
                          sending
                              ? null
                              : sendMessage,
                      icon: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
}