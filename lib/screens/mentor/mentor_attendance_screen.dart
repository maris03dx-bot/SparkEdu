import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MentorAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const MentorAttendanceScreen({
    super.key,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    final String studentId = studentData["rollNo"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("${studentData["name"]}'s Attendance"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .where("studentId", isEqualTo: studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No attendance records found",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          int totalPresent = 0;
          int totalClasses = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            totalPresent += (data["present"] ?? 0) as int;
            totalClasses += (data["total"] ?? 0) as int;
          }

          final percentage = totalClasses == 0
              ? 0
              : (totalPresent / totalClasses) * 100;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fact_check,
                          size: 60,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${percentage.toStringAsFixed(1)} %",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Overall Attendance",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.book),
                          ),
                          title: Text(data["subject"] ?? ""),
                          subtitle: Text(
                            "Present: ${data["present"]} / ${data["total"]}",
                          ),
                          trailing: Text(
                            "${(((data["present"] ?? 0) / (data["total"] ?? 1)) * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}