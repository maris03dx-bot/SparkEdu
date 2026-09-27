import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class DirectChatScreen extends StatelessWidget {
  const DirectChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please login first."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Direct Messages"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where(
              "role",
              isEqualTo: "Subject Teacher",
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  "Error:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No data found."),
            );
          }

          final teachers =
              snapshot.data!.docs;

          if (teachers.isEmpty) {
            return const Center(
              child: Text(
                "No Teachers Available",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: teachers.length,

            itemBuilder: (context, index) {
              final teacher =
                  teachers[index].data()
                      as Map<String, dynamic>;

              final String teacherUid =
                  teacher["uid"]?.toString() ??
                      teachers[index].id;

              final String teacherName =
                  teacher["name"]?.toString() ??
                      "Teacher";

              final String subject =
                  teacher["subject"]?.toString() ??
                      "Subject";

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
                      BorderRadius.circular(15),
                ),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),

                  leading:
                      const CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        Colors.blue,

                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  title: Text(
                    teacherName,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),

                    child: Text(
                      subject,
                      style:
                          const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),

                  trailing:
                      const Icon(
                    Icons.chat_outlined,
                    color:
                        Colors.blue,
                  ),

                  onTap: () {
                    if (teacherUid.isEmpty) {
                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Teacher UID is missing",
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(
                          otherUserName:
                              teacherName,
                          otherUserId:
                              teacherUid,
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
  }
}