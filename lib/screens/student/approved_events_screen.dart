import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApprovedEventsScreen extends StatelessWidget {
  const ApprovedEventsScreen({super.key});

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Date not available";

    final date = timestamp.toDate();

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Time not available";

    final date = timestamp.toDate();

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved Events"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("event_requests")
            .where("status", isEqualTo: "Approved")
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading approved events:\n${snapshot.error}",
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

          final events = snapshot.data?.docs ?? [];

          if (events.isEmpty) {
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
                    "No Approved Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Approved events will appear here.",
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
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data =
                  events[index].data()
                      as Map<String, dynamic>;

              final title =
                  data["title"]?.toString() ??
                      "Untitled Event";

              final category =
                  data["category"]?.toString() ??
                      "Other";

              final venue =
                  data["venue"]?.toString() ??
                      "Venue not available";

              final description =
                  data["description"]?.toString() ??
                      "No description";

              final participants =
                  data["expectedParticipants"]
                          ?.toString() ??
                      "Not specified";

              final eventDate =
                  data["eventDate"] is Timestamp
                      ? data["eventDate"] as Timestamp
                      : null;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(
                  bottom: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor:
                                Colors.green,
                            child: Icon(
                              Icons.event_available,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              title,
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.green
                                  .withValues(
                                alpha: 0.1,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              "Approved",
                              style: TextStyle(
                                color:
                                    Colors.green,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "Category: $category",
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDate(eventDate),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatTime(eventDate),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(venue),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Expected Participants: "
                            "$participants",
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Description",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          color: Colors.grey
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Text(
                          description,
                        ),
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