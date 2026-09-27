import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MentorAssignmentScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const MentorAssignmentScreen({
    super.key,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    final String studentId = studentData["rollNo"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("${studentData["name"]}'s Assignments"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("assignment_submissions")
            .where("studentId", isEqualTo: studentId)
            .orderBy("submittedAt", descending: true)
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No assignments submitted",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(
                      Icons.assignment,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data["assignmentTitle"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        "Submitted: ${DateFormat('dd MMM yyyy').format((data["submittedAt"] as Timestamp).toDate())}",
                      ),
                      Text(
                        "Marks: ${data["marks"] ?? "Not Evaluated"}",
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}