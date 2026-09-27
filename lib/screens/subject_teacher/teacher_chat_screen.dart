import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherChatScreen extends StatefulWidget {
  final String otherUserName;
  final String otherUserId;

  const TeacherChatScreen({
    super.key,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<TeacherChatScreen> createState() =>
      _TeacherChatScreenState();
}

// ============================================================
// LOCAL MESSAGE
// ============================================================

class _LocalMessage {
  final String id;
  final String message;
  final DateTime time;

  String status;

  _LocalMessage({
    required this.id,
    required this.message,
    required this.time,
    required this.status,
  });
}

// ============================================================
// TEACHER CHAT STATE
// ============================================================

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  bool sending = false;

  bool markingSeen = false;

  final List<_LocalMessage> localMessages = [];

  // ==========================================================
  // SAME CHAT ID FOR STUDENT AND TEACHER
  // ==========================================================

  String getChatId(String user1, String user2) {
    final ids = [user1, user2];

    ids.sort();

    return '${ids[0]}_${ids[1]}';
  }

  // ==========================================================
  // FORMAT DATE AND TIME
  // Example:
  // 09/08/2026 • 5:43 PM
  // ==========================================================

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');

    final month = dateTime.month.toString().padLeft(2, '0');

    final year = dateTime.year.toString();

    final hour = dateTime.hour % 12 == 0
        ? 12
        : dateTime.hour % 12;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12
        ? 'PM'
        : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    final currentUser = auth.currentUser;

    if (text.isEmpty || currentUser == null) {
      return;
    }

    final teacherId = currentUser.uid;

    final studentId = widget.otherUserId;

    final chatId = getChatId(
      teacherId,
      studentId,
    );

    // --------------------------------------------------------
    // CREATE MESSAGE REFERENCE
    // --------------------------------------------------------

    final messageRef = firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    // --------------------------------------------------------
    // LOCAL MESSAGE
    // --------------------------------------------------------

    final localMessage = _LocalMessage(
      id: messageRef.id,
      message: text,
      time: DateTime.now(),
      status: 'sending',
    );

    setState(() {
      sending = true;
      localMessages.add(localMessage);
    });

    messageController.clear();

    try {
      // ======================================================
      // CREATE / UPDATE CHAT DOCUMENT
      // ======================================================

      await firestore
          .collection('direct_chats')
          .doc(chatId)
          .set(
        {
          'studentId': studentId,
          'teacherId': teacherId,
          'lastMessage': text,
          'lastMessageTime':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ======================================================
      // SAVE MESSAGE
      // ======================================================

      await messageRef.set(
        {
          'senderId': teacherId,
          'receiverId': studentId,
          'message': text,
          'timestamp':
              FieldValue.serverTimestamp(),

          // Successfully saved in Firestore.
          'status': 'sent',

          // Student has not seen it yet.
          'seen': false,
        },
      );

      // ======================================================
      // MESSAGE SUCCESSFULLY SENT
      // ======================================================

      if (mounted) {
        setState(() {
          localMessage.status = 'sent';
        });
      }
    } catch (e) {
      // ======================================================
      // MESSAGE FAILED
      // ======================================================

      if (mounted) {
        setState(() {
          localMessage.status = 'failed';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message not sent. Check your internet connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  // ==========================================================
  // MARK STUDENT MESSAGES AS SEEN
  // ==========================================================

  Future<void> markMessagesAsSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) async {
    if (markingSeen) {
      return;
    }

    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return;
    }

    // --------------------------------------------------------
    // FIND UNSEEN MESSAGES RECEIVED BY TEACHER
    // --------------------------------------------------------

    final unreadMessages = messages.where((doc) {
      final data = doc.data();

      final receiverId =
          data['receiverId']?.toString() ?? '';

      final seen = data['seen'] == true;

      return receiverId == currentUser.uid && !seen;
    }).toList();

    if (unreadMessages.isEmpty) {
      return;
    }

    markingSeen = true;

    try {
      final batch = firestore.batch();

      for (final doc in unreadMessages) {
        batch.update(
          doc.reference,
          {
            'seen': true,
            'seenAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Failed to mark messages as seen: $e',
      );
    } finally {
      markingSeen = false;
    }
  }

  // ==========================================================
  // GET MESSAGE TIME
  // ==========================================================

  DateTime getMessageTime(
    Map<String, dynamic> data,
  ) {
    final timestamp = data['timestamp'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    // Used while server timestamp is still pending.
    return DateTime.now();
  }

  // ==========================================================
  // MESSAGE TICKS
  // ==========================================================

  Widget messageTicks({
    required bool isMe,
    required bool seen,
    required String status,
  }) {
    if (!isMe) {
      return const SizedBox.shrink();
    }

    // --------------------------------------------------------
    // ONE TICK
    // Message is still sending or failed.
    // --------------------------------------------------------

    if (status == 'sending' ||
        status == 'failed') {
      return const Icon(
        Icons.check,
        size: 16,
        color: Colors.white70,
      );
    }

    // --------------------------------------------------------
    // TWO YELLOW TICKS
    // Student has seen the message.
    // --------------------------------------------------------

    if (seen) {
      return const Icon(
        Icons.done_all,
        size: 17,
        color: Colors.yellow,
      );
    }

    // --------------------------------------------------------
    // TWO WHITE TICKS
    // Message successfully reached Firestore.
    // --------------------------------------------------------

    return const Icon(
      Icons.done_all,
      size: 17,
      color: Colors.white,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.currentUser;

    // --------------------------------------------------------
    // USER NOT LOGGED IN
    // --------------------------------------------------------

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not logged in',
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // SAME CHAT ID
    // --------------------------------------------------------

    final chatId = getChatId(
      currentUser.uid,
      widget.otherUserId,
    );

    // --------------------------------------------------------
    // FIRESTORE MESSAGE STREAM
    // --------------------------------------------------------

    final messagesStream = firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: false,
        )
        .snapshots();

    // ========================================================
    // UI
    // ========================================================

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // ==================================================
          // PRIVATE CHAT INFORMATION
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.blue,
                  size: 22,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Private conversation between teacher and student.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // MESSAGES
          // ==================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,

              builder: (context, snapshot) {
                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error:\n${snapshot.error}',
                        textAlign: TextAlign.center,
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
                    child: CircularProgressIndicator(),
                  );
                }

                // ------------------------------------------------
                // FIRESTORE MESSAGES
                // ------------------------------------------------

                final messages =
                    snapshot.data?.docs ??
                        <
                            QueryDocumentSnapshot<
                                Map<String, dynamic>>>[];

                // ------------------------------------------------
                // MARK STUDENT MESSAGES AS SEEN
                // ------------------------------------------------

                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  if (mounted) {
                    markMessagesAsSeen(messages);
                  }
                });

                // ------------------------------------------------
                // FIRESTORE MESSAGE IDS
                // ------------------------------------------------

                final firestoreMessageIds =
                    messages
                        .map(
                          (doc) => doc.id,
                        )
                        .toSet();

                // =================================================
                // DISPLAY LIST
                // =================================================

                final List<Map<String, dynamic>>
                    displayItems = [];

                // ------------------------------------------------
                // ADD FIRESTORE MESSAGES
                // ------------------------------------------------

                for (final doc in messages) {
                  final data = doc.data();

                  displayItems.add(
                    {
                      'id': doc.id,

                      'message':
                          data['message'] ?? '',

                      'senderId':
                          data['senderId'] ?? '',

                      'seen':
                          data['seen'] == true,

                      'status':
                          data['status'] ?? 'sent',

                      'time':
                          getMessageTime(data),

                      'local': false,
                    },
                  );
                }

                // ------------------------------------------------
                // ADD LOCAL PENDING MESSAGES
                // ------------------------------------------------

                for (final local in localMessages) {
                  if (!firestoreMessageIds
                      .contains(local.id)) {
                    displayItems.add(
                      {
                        'id': local.id,

                        'message':
                            local.message,

                        'senderId':
                            currentUser.uid,

                        'seen': false,

                        'status':
                            local.status,

                        'time':
                            local.time,

                        'local': true,
                      },
                    );
                  }
                }

                // ------------------------------------------------
                // SORT BY TIME
                // ------------------------------------------------

                displayItems.sort(
                  (a, b) {
                    final DateTime aTime =
                        a['time'] as DateTime;

                    final DateTime bTime =
                        b['time'] as DateTime;

                    return aTime.compareTo(bTime);
                  },
                );

                // ------------------------------------------------
                // EMPTY CHAT
                // ------------------------------------------------

                if (displayItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a conversation',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // =================================================
                // MESSAGE LIST
                // =================================================

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(12),

                  itemCount:
                      displayItems.length,

                  itemBuilder:
                      (context, index) {
                    final data =
                        displayItems[index];

                    final String message =
                        data['message']
                            .toString();

                    final String senderId =
                        data['senderId']
                            .toString();

                    final bool isMe =
                        senderId ==
                            currentUser.uid;

                    final bool seen =
                        data['seen'] == true;

                    final String status =
                        data['status']
                            .toString();

                    final DateTime messageTime =
                        data['time'] as DateTime;

                    // =================================================
                    // MESSAGE BUBBLE
                    // =================================================

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
                                  0.82,
                        ),

                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),

                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          11,
                          12,
                          8,
                        ),

                        decoration:
                            BoxDecoration(
                          color: isMe
                              ? const Color(
                                  0xFF2196F3,
                                )
                              : Colors
                                  .grey
                                  .shade300,

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,

                          children: [
                            // =====================================
                            // MESSAGE TEXT
                            // =====================================

                            Align(
                              alignment:
                                  Alignment.centerLeft,

                              child: Text(
                                message,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            // =====================================
                            // DATE + TIME + TICKS
                            // =====================================

                            Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Text(
                                  formatDateTime(
                                    messageTime,
                                  ),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),

                                if (isMe) ...[
                                  const SizedBox(
                                    width: 5,
                                  ),

                                  messageTicks(
                                    isMe: isMe,
                                    seen: seen,
                                    status: status,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ==================================================
          // MESSAGE INPUT
          // ==================================================

          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              child: Row(
                children: [
                  // ============================================
                  // TEXT FIELD
                  // ============================================

                  Expanded(
                    child: TextField(
                      controller:
                          messageController,

                      textInputAction:
                          TextInputAction.send,

                      minLines: 1,
                      maxLines: 4,

                      onSubmitted: (_) {
                        if (!sending) {
                          sendMessage();
                        }
                      },

                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            25,
                          ),
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

                  // ============================================
                  // SEND BUTTON
                  // ============================================

                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF2196F3),

                    child: IconButton(
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color:
                                  Colors.white,
                            ),

                      onPressed: sending
                          ? null
                          : sendMessage,
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