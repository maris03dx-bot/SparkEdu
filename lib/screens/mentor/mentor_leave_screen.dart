import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MentorLeaveScreen extends StatelessWidget {
  const MentorLeaveScreen({super.key});

  // ==========================================================
  // UPDATE LEAVE STATUS
  // ==========================================================

  Future<void> updateStatus(
    BuildContext context,
    String documentId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("leave_requests")
          .doc(documentId)
          .update({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              status == "Approved"
                  ? Colors.green
                  : Colors.red,
          content: Text(
            "Leave $status Successfully",
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to update leave:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;

      case "Rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  // ==========================================================
  // STATUS ICON
  // ==========================================================

  IconData statusIcon(String status) {
    switch (status) {
      case "Approved":
        return Icons.check_circle;

      case "Rejected":
        return Icons.cancel;

      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Requests",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("leave_requests")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ==================================================
          // ERROR
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading leave requests:\n"
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ==================================================
          // LOADING
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests =
              snapshot.data?.docs ?? [];

          // ==================================================
          // NO REQUESTS
          // ==================================================

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No Leave Requests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Student leave requests will appear here.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // ==================================================
          // REQUEST LIST
          // ==================================================

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: requests.length,

            itemBuilder: (context, index) {
              final doc = requests[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              // ==================================================
              // STUDENT NAME
              // ==================================================

              final String studentName =
                  data["studentName"]
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true
                      ? data["studentName"]
                          .toString()
                          .trim()
                      : "Name not available";

              // ==================================================
              // REGISTER NUMBER
              //
              // New leave requests store "registerNo".
              //
              // Old documents may not have it, so we support
              // a few existing field names without displaying
              // the Firebase UID.
              // ==================================================

              String registerNo =
                  data["registerNo"]
                          ?.toString()
                          .trim() ??
                      "";

              if (registerNo.isEmpty) {
                registerNo =
                    data["registerNumber"]
                            ?.toString()
                            .trim() ??
                        "";
              }

              if (registerNo.isEmpty) {
                registerNo = "Not available";
              }

              // ==================================================
              // REASON
              // ==================================================

              final String reason =
                  data["reason"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? data["reason"]
                      .toString()
                      .trim()
                  : "No reason provided";

              // ==================================================
              // STATUS
              // ==================================================

              final String status =
                  data["status"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? data["status"]
                      .toString()
                      .trim()
                  : "Pending";

              // ==================================================
              // FROM DATE
              // ==================================================

              DateTime? from;

              if (data["fromDate"] is Timestamp) {
                from =
                    (data["fromDate"]
                            as Timestamp)
                        .toDate();
              }

              // ==================================================
              // TO DATE
              // ==================================================

              DateTime? to;

              if (data["toDate"] is Timestamp) {
                to =
                    (data["toDate"]
                            as Timestamp)
                        .toDate();
              }

              // ==================================================
              // CREATED DATE
              // ==================================================

              DateTime? createdAt;

              if (data["createdAt"] is Timestamp) {
                createdAt =
                    (data["createdAt"]
                            as Timestamp)
                        .toDate();
              }

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 15,
                ),
                elevation: 5,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==========================================
                      // STUDENT INFORMATION
                      //
                      // ONLY NAME + REGISTER NUMBER
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Colors.blue,
                            child: Icon(
                              Icons.person,
                              color:
                                  Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  studentName,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Icon(
                                      Icons.badge_outlined,
                                      size: 17,
                                      color:
                                          Colors.grey,
                                    ),

                                    const SizedBox(
                                      width: 5,
                                    ),

                                    Expanded(
                                      child: Text(
                                        "Register No: "
                                        "$registerNo",
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==========================================
                      // REASON
                      // ==========================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          12,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey
                                  .withValues(
                            alpha: 0.08,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Text(
                              "Reason",
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    15,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              reason,
                              style:
                                  const TextStyle(
                                fontSize:
                                    15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // FROM DATE
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Icon(
                            Icons
                                .calendar_today,
                            size: 20,
                            color:
                                Colors.blue,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          const Text(
                            "From:",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              from == null
                                  ? "Not specified"
                                  : DateFormat(
                                      "dd MMM yyyy",
                                    ).format(
                                      from,
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // TO DATE
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Icon(
                            Icons.event,
                            size: 20,
                            color:
                                Colors.blue,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          const Text(
                            "To:",
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              to == null
                                  ? "Not specified"
                                  : DateFormat(
                                      "dd MMM yyyy",
                                    ).format(
                                      to,
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // ==========================================
                      // SUBMITTED DATE
                      // ==========================================

                      if (createdAt != null) ...[
                        const SizedBox(
                          height: 8,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color:
                                  Colors.grey,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Text(
                              "Submitted: "
                              "${DateFormat(
                                "dd MMM yyyy • hh:mm a",
                              ).format(
                                createdAt,
                              )}",
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // STATUS
                      // ==========================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          12,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              statusColor(
                            status,
                          ).withValues(
                            alpha: 0.1,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              statusIcon(
                                status,
                              ),
                              color:
                                  statusColor(
                                status,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Text(
                              "Status: $status",
                              style:
                                  TextStyle(
                                color:
                                    statusColor(
                                  status,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // APPROVE / REJECT
                      // ==========================================

                      if (status ==
                          "Pending")
                        Row(
                          children: [
                            Expanded(
                              child:
                                  ElevatedButton
                                      .icon(
                                onPressed: () {
                                  updateStatus(
                                    context,
                                    doc.id,
                                    "Approved",
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.check,
                                ),
                                label:
                                    const Text(
                                  "Approve",
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.green,
                                  foregroundColor:
                                      Colors.white,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical:
                                        12,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  ElevatedButton
                                      .icon(
                                onPressed: () {
                                  updateStatus(
                                    context,
                                    doc.id,
                                    "Rejected",
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.close,
                                ),
                                label:
                                    const Text(
                                  "Reject",
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.red,
                                  foregroundColor:
                                      Colors.white,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical:
                                        12,
                                  ),
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