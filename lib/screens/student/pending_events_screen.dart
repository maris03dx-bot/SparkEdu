import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PendingEventsScreen extends StatelessWidget {
  const PendingEventsScreen({super.key});

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return "Date not available";
    }

    final date = timestamp.toDate();

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return "Time not available";
    }

    final date = timestamp.toDate();

    final hour =
        date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String getApprovalText(
    Map<String, dynamic> data,
  ) {
    final status =
        data["status"]?.toString() ?? "";

    if (status == "Pending Mentor Approval") {
      return "Pending Mentor Approval";
    }

    if (status == "Pending Dean Approval") {
      return "Pending Associate Dean Approval";
    }

    return status.isEmpty
        ? "Pending Approval"
        : status;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(
    Map<String, dynamic> data,
  ) {
    final status =
        data["status"]?.toString() ?? "";

    if (status == "Pending Dean Approval") {
      return Colors.blue;
    }

    return Colors.orange;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Events"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("event_requests")
            .where(
              "status",
              whereIn: [
                "Pending Mentor Approval",
                "Pending Dean Approval",
              ],
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading pending events:\n"
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------------
          // GET EVENTS
          // ------------------------------------------------------

          final events =
              snapshot.data?.docs ?? [];

          // ------------------------------------------------------
          // NO EVENTS
          // ------------------------------------------------------

          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 75,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 15),

                    Text(
                      "No Pending Events",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "There are no event proposals "
                      "waiting for approval.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ------------------------------------------------------
          // EVENT LIST
          // ------------------------------------------------------

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: events.length,

            itemBuilder: (context, index) {
              final doc = events[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              // ------------------------------------------------
              // DATA
              // ------------------------------------------------

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
                      ? data["eventDate"]
                          as Timestamp
                      : null;

              final approvalText =
                  getApprovalText(data);

              final statusColor =
                  getStatusColor(data);

              // ------------------------------------------------
              // CARD
              // ------------------------------------------------

              return Card(
                elevation: 4,

                margin:
                    const EdgeInsets.only(
                  bottom: 15,
                ),

                shape:
                    RoundedRectangleBorder(
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
                      // ==========================================
                      // TITLE + STATUS
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          CircleAvatar(
                            backgroundColor:
                                statusColor,

                            child: const Icon(
                              Icons.event,
                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

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
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // CURRENT APPROVAL STATUS
                      // ==========================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        decoration:
                            BoxDecoration(
                          color: statusColor
                              .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          border:
                              Border.all(
                            color:
                                statusColor
                                    .withValues(
                              alpha: 0.30,
                            ),
                          ),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              data["status"] ==
                                      "Pending Dean Approval"
                                  ? Icons
                                      .admin_panel_settings
                                  : Icons
                                      .supervisor_account,
                              color:
                                  statusColor,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                approvalText,
                                style:
                                    TextStyle(
                                  color:
                                      statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==========================================
                      // CATEGORY
                      // ==========================================

                      Text(
                        "Category: $category",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.blue,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==========================================
                      // DATE
                      // ==========================================

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Text(
                            formatDate(
                              eventDate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // TIME
                      // ==========================================

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Text(
                            formatTime(
                              eventDate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // VENUE
                      // ==========================================

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child: Text(
                              venue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // PARTICIPANTS
                      // ==========================================

                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 20,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Text(
                            "Expected Participants: "
                            "$participants",
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // DESCRIPTION
                      // ==========================================

                      const Text(
                        "Description",
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(12),

                        decoration:
                            BoxDecoration(
                          color: Colors.grey
                              .withValues(
                            alpha: 0.08,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),

                        child: Text(
                          description,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // APPROVAL FLOW
                      // ==========================================

                      _buildApprovalFlow(
                        data,
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

  // ============================================================
  // APPROVAL FLOW UI
  // ============================================================

  Widget _buildApprovalFlow(
    Map<String, dynamic> data,
  ) {
    final mentorStatus =
        data["mentorStatus"]?.toString() ??
            "Pending";

    final deanStatus =
        data["deanStatus"]?.toString() ??
            "Pending";

    final mentorApproved =
        mentorStatus == "Approved";

    final deanApproved =
        deanStatus == "Approved";

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "Approval Progress",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        // --------------------------------------------------------
        // MENTOR
        // --------------------------------------------------------

        Row(
          children: [
            Icon(
              mentorApproved
                  ? Icons.check_circle
                  : Icons.pending,
              color: mentorApproved
                  ? Colors.green
                  : Colors.orange,
            ),

            const SizedBox(width: 10),

            Text(
              mentorApproved
                  ? "Mentor Approved"
                  : "Pending Mentor Approval",
              style: TextStyle(
                color: mentorApproved
                    ? Colors.green
                    : Colors.orange,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // --------------------------------------------------------
        // DEAN
        // --------------------------------------------------------

        Row(
          children: [
            Icon(
              deanApproved
                  ? Icons.check_circle
                  : Icons.pending,
              color: deanApproved
                  ? Colors.green
                  : Colors.blue,
            ),

            const SizedBox(width: 10),

            Text(
              deanApproved
                  ? "Associate Dean Approved"
                  : "Pending Associate Dean Approval",
              style: TextStyle(
                color: deanApproved
                    ? Colors.green
                    : Colors.blue,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}