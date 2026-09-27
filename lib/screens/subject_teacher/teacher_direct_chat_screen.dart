import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'teacher_chat_screen.dart';

class TeacherDirectChatScreen extends StatelessWidget {
  const TeacherDirectChatScreen({super.key});

  // ==========================================================
  // GET STUDENT PROFILE BY FIREBASE UID
  // ==========================================================

  Future<Map<String, dynamic>?> getStudentProfile(
    String studentUid,
  ) async {
    if (studentUid.trim().isEmpty) {
      return null;
    }

    final result = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: studentUid,
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first.data();
  }

  // ==========================================================
  // GET STUDENT NAME
  // ==========================================================

  Future<String> getStudentName(
    String studentUid,
    String storedName,
  ) async {
    final profile =
        await getStudentProfile(studentUid);

    final profileName =
        profile?["name"]
                ?.toString()
                .trim() ??
            "";

    if (profileName.isNotEmpty) {
      return profileName;
    }

    final oldStoredName =
        storedName.trim();

    if (oldStoredName.isNotEmpty &&
        oldStoredName != "Student") {
      return oldStoredName;
    }

    return "Name not available";
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

    final time = timestamp.toDate();

    final int hour =
        time.hour % 12 == 0
            ? 12
            : time.hour % 12;

    final String minute =
        time.minute
            .toString()
            .padLeft(2, "0");

    final String period =
        time.hour >= 12
            ? "PM"
            : "AM";

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login first.",
          ),
        ),
      );
    }

    final teacherId =
        currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Direct Messages",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        // ======================================================
        // GET ALL CHATS FOR THIS TEACHER
        //
        // No orderBy here, so no composite index is required.
        // ======================================================

        stream: FirebaseFirestore.instance
            .collection("direct_chats")
            .where(
              "teacherId",
              isEqualTo: teacherId,
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  "Error:\n"
                  "${snapshot.error}",
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final chats =
              snapshot.data?.docs.toList() ??
                  [];

          // ====================================================
          // NO CHATS
          // ====================================================

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Colors.grey,
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  Text(
                    "No direct messages yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // ====================================================
          // LOCAL SORT BY UPDATED TIME
          // ====================================================

          chats.sort(
            (a, b) {
              final aData =
                  a.data()
                      as Map<String, dynamic>;

              final bData =
                  b.data()
                      as Map<String, dynamic>;

              final Timestamp? aTime =
                  aData["updatedAt"]
                      is Timestamp
                  ? aData["updatedAt"]
                      as Timestamp
                  : null;

              final Timestamp? bTime =
                  bData["updatedAt"]
                      is Timestamp
                  ? bData["updatedAt"]
                      as Timestamp
                  : null;

              if (aTime == null &&
                  bTime == null) {
                return 0;
              }

              if (aTime == null) {
                return 1;
              }

              if (bTime == null) {
                return -1;
              }

              return bTime.compareTo(
                aTime,
              );
            },
          );

          // ====================================================
          // CHAT LIST
          // ====================================================

          return ListView.builder(
            padding:
                const EdgeInsets.all(10),

            itemCount:
                chats.length,

            itemBuilder:
                (context, index) {
              final chatDoc =
                  chats[index];

              final data =
                  chatDoc.data()
                      as Map<String, dynamic>;

              // =================================================
              // STUDENT FIREBASE UID
              // =================================================

              final String studentId =
                  data["studentId"]
                          ?.toString()
                          .trim() ??
                      "";

              // =================================================
              // OLD STORED NAME
              //
              // Used only as a fallback for old chat documents.
              // =================================================

              final String storedStudentName =
                  data["studentName"]
                          ?.toString()
                          .trim() ??
                      "";

              // =================================================
              // LAST MESSAGE
              // =================================================

              final String lastMessage =
                  data["lastMessage"]
                          ?.toString()
                          .trim() ??
                      "";

              // =================================================
              // LAST MESSAGE TIME
              // =================================================

              final Timestamp? lastMessageTime =
                  data["lastMessageTime"]
                          is Timestamp
                      ? data["lastMessageTime"]
                          as Timestamp
                      : null;

              // =================================================
              // STUDENT NOT FOUND
              // =================================================

              if (studentId.isEmpty) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 7,
                  ),
                  elevation: 3,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: const ListTile(
                    leading:
                        CircleAvatar(
                      radius: 27,
                      backgroundColor:
                          Colors.grey,
                      child: Icon(
                        Icons.person,
                        color:
                            Colors.white,
                      ),
                    ),
                    title: Text(
                      "Student profile unavailable",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "This chat does not contain a student UID.",
                    ),
                  ),
                );
              }

              // =================================================
              // FETCH REAL STUDENT NAME
              // =================================================

              return FutureBuilder<String>(
                future:
                    getStudentName(
                  studentId,
                  storedStudentName,
                ),

                builder: (
                  context,
                  nameSnapshot,
                ) {
                  final String studentName =
                      nameSnapshot.data ??
                          "Loading...";

                  return Card(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 5,
                      vertical: 7,
                    ),

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),

                    child: ListTile(
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),

                      // =========================================
                      // STUDENT ICON
                      // =========================================

                      leading:
                          const CircleAvatar(
                        radius: 27,
                        backgroundColor:
                            Colors.blue,
                        child: Icon(
                          Icons.person,
                          color:
                              Colors.white,
                          size: 30,
                        ),
                      ),

                      // =========================================
                      // STUDENT NAME
                      // =========================================

                      title: Text(
                        studentName,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      // =========================================
                      // LAST MESSAGE
                      // =========================================

                      subtitle:
                          Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 5,
                        ),
                        child:
                            Text(
                          lastMessage.isEmpty
                              ? "Start a conversation"
                              : lastMessage,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // =========================================
                      // TIME + CHAT ICON
                      // =========================================

                      trailing:
                          Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .end,
                        children: [
                          if (lastMessageTime !=
                              null)
                            Text(
                              formatTime(
                                lastMessageTime,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),

                          const SizedBox(
                            height: 5,
                          ),

                          const Icon(
                            Icons
                                .chat_outlined,
                            color:
                                Colors.blue,
                          ),
                        ],
                      ),

                      // =========================================
                      // OPEN CHAT
                      // =========================================

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherChatScreen(
                              otherUserName:
                                  studentName,
                              otherUserId:
                                  studentId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}