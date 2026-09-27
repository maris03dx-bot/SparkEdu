import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'dean_teacher_detail_screen.dart';

class AssociateDeanTeachersScreen extends StatefulWidget {
  const AssociateDeanTeachersScreen({super.key});

  @override
  State<AssociateDeanTeachersScreen> createState() =>
      _AssociateDeanTeachersScreenState();
}

class _AssociateDeanTeachersScreenState
    extends State<AssociateDeanTeachersScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teachers"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Teacher...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "Subject Teacher")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final teachers = snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final name =
                      (data["name"] ?? "").toString().toLowerCase();

                  final email =
                      (data["email"] ?? "").toString().toLowerCase();

                  final department =
                      (data["department"] ?? "")
                          .toString()
                          .toLowerCase();

                  return name.contains(search) ||
                      email.contains(search) ||
                      department.contains(search);
                }).toList();

                if (teachers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Teachers Found",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final data =
                        teachers[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Colors.orange.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          data["name"] ?? "No Name",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Email : ${data["email"] ?? "N/A"}"),
                              Text(
                                  "Department : ${data["department"] ?? "N/A"}"),
                              Text(
                                  "Subject : ${data["subject"] ?? "Not Assigned"}"),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeanTeacherDetailScreen(
                                teacherData: data,
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
          ),
        ],
      ),
    );
  }
}