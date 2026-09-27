import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssociateDeanEventRequestsScreen extends StatelessWidget {
  const AssociateDeanEventRequestsScreen({super.key});

  Future<void> approveEvent(
    BuildContext context,
    String documentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("event_requests")
          .doc(documentId)
          .update({
        "deanStatus": "Approved",
        "status": "Approved",
        "approvedAt": Timestamp.now(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Event approved successfully"),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to approve event: $e"),
        ),
      );
    }
  }

  Future<void> rejectEvent(
    BuildContext context,
    String documentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("event_requests")
          .doc(documentId)
          .update({
        "deanStatus": "Rejected",
        "status": "Rejected",
        "rejectedAt": Timestamp.now(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Event rejected"),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to reject event: $e"),
        ),
      );
    }
  }

  void showEventDetails(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) {
    final Timestamp? eventDate = data["eventDate"] is Timestamp
        ? data["eventDate"] as Timestamp
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            data["title"] ?? "Event",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Description",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(data["description"] ?? "No description"),

                const SizedBox(height: 15),

                Text(
                  "Venue",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(data["venue"] ?? "Not specified"),

                const SizedBox(height: 15),

                Text(
                  "Event Date",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  eventDate == null
                      ? "Not specified"
                      : "${eventDate.toDate().day}/"
                          "${eventDate.toDate().month}/"
                          "${eventDate.toDate().year}",
                ),

                const SizedBox(height: 15),

                Text(
                  "Student",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(data["studentName"] ?? "Student"),

                const SizedBox(height: 5),

                Text(
                  "Student ID: ${data["studentId"] ?? "Unknown"}",
                ),

                const SizedBox(height: 15),

                Text(
                  "Mentor Status: ${data["mentorStatus"] ?? "Unknown"}",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Close"),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await rejectEvent(
                  context,
                  documentId,
                );
              },
              child: const Text(
                "Reject",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await approveEvent(
                  context,
                  documentId,
                );
              },
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );
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
              isEqualTo: "Approved",
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading event requests:\n${snapshot.error}",
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

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No event requests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Mentor-approved events will appear here.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final document = requests[index];

              final data =
                  document.data() as Map<String, dynamic>;

              final String deanStatus =
                  data["deanStatus"] ?? "Pending";

              // Already processed requests are hidden.
              if (deanStatus != "Pending") {
                return const SizedBox.shrink();
              }

              final Timestamp? eventDate =
                  data["eventDate"] is Timestamp
                      ? data["eventDate"] as Timestamp
                      : null;

              return Card(
                elevation: 5,
                margin:
                    const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Colors.orange,
                            child: Icon(
                              Icons.event,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              data["title"] ??
                                  "Untitled Event",
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text(
                        data["description"] ??
                            "No description",
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data["venue"] ??
                                  "Venue not specified",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            eventDate == null
                                ? "Date not specified"
                                : "${eventDate.toDate().day}/"
                                    "${eventDate.toDate().month}/"
                                    "${eventDate.toDate().year}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${data["studentName"] ?? "Student"} "
                              "(${data["studentId"] ?? "Unknown"})",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "✓ Approved by Mentor",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showEventDetails(
                                  context,
                                  document.id,
                                  data,
                                );
                              },
                              icon: const Icon(
                                Icons.visibility,
                              ),
                              label:
                                  const Text("View"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showEventDetails(
                                  context,
                                  document.id,
                                  data,
                                );
                              },
                              icon: const Icon(
                                Icons.check,
                              ),
                              label:
                                  const Text("Review"),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue,
                                foregroundColor:
                                    Colors.white,
                              ),
                            ),
                          ),
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
    );
  }
}