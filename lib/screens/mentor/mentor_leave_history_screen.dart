import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MentorLeaveHistoryScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const MentorLeaveHistoryScreen({
    super.key,
    required this.studentData,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String studentId = studentData["rollNo"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("${studentData["name"]}'s Leave History"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("leave_requests")
            .where("studentId", isEqualTo: studentId)
            .orderBy("createdAt", descending: true)
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
                "No leave requests found",
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

              final from =
                  (data["fromDate"] as Timestamp).toDate();

              final to =
                  (data["toDate"] as Timestamp).toDate();

              final status = data["status"] ?? "Pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: getStatusColor(status),
                    child: const Icon(
                      Icons.event_available,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data["reason"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${DateFormat('dd MMM yyyy').format(from)} - ${DateFormat('dd MMM yyyy').format(to)}",
                  ),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
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