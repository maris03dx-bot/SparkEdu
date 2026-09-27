import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MentorEventRequestsScreen extends StatelessWidget {
  const MentorEventRequestsScreen({super.key});

  Future<void> updateRequest(
    BuildContext context,
    String documentId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("event_requests")
          .doc(documentId)
          .update({
        "mentorStatus": status,
        "status": status == "Approved"
            ? "Pending Dean Approval"
            : "Rejected by Mentor",
        "mentorReviewedAt": Timestamp.now(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              status == "Approved" ? Colors.green : Colors.red,
          content: Text(
            status == "Approved"
                ? "Event approved. Sent for Dean approval."
                : "Event request rejected.",
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to update request: $e"),
        ),
      );
    }
  }

  void showRequestDetails(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  data["title"] ?? "Event",
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _detailRow(
                  Icons.category,
                  "Category",
                  data["category"] ?? "Not specified",
                ),

                _detailRow(
                  Icons.calendar_today,
                  "Date",
                  _formatDate(data["eventDate"]),
                ),

                _detailRow(
                  Icons.access_time,
                  "Time",
                  _formatTime(data["eventDate"]),
                ),

                _detailRow(
                  Icons.location_on,
                  "Venue",
                  data["venue"] ?? "Not specified",
                ),

                _detailRow(
                  Icons.people,
                  "Expected Participants",
                  "${data["expectedParticipants"] ?? "Not specified"}",
                ),

                _detailRow(
                  Icons.person,
                  "Student",
                  data["studentName"] ?? "Student",
                ),

                _detailRow(
                  Icons.badge,
                  "Student ID",
                  data["studentId"] ?? "Not specified",
                ),

                const SizedBox(height: 15),

                const Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  data["description"] ?? "No description",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          updateRequest(
                            context,
                            documentId,
                            "Rejected",
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          updateRequest(
                            context,
                            documentId,
                            "Approved",
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    }

    return "Not specified";
  }

  static String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;

      final minute =
          date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? "PM" : "AM";

      return "$hour:$minute $period";
    }

    return "Not specified";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Requests"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("event_requests")
            .where(
              "mentorStatus",
              isEqualTo: "Pending",
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading requests:\n${snapshot.error}",
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

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No Pending Event Requests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "New event proposals will appear here.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin:
                    const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(15),

                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 25,
                    child: Icon(
                      Icons.event,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    data["title"] ?? "Event",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                          data["category"] ??
                              "Category not specified",
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Venue: ${data["venue"] ?? "Not specified"}",
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Student: ${data["studentName"] ?? "Student"}",
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Pending Approval",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: () {
                    showRequestDetails(
                      context,
                      doc.id,
                      data,
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