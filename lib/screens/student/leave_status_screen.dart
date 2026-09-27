import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveStatusScreen extends StatelessWidget {
  const LeaveStatusScreen({super.key});

  // ============================================================
  // GET CURRENT STUDENT PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final query = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

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

  // ============================================================
  // STATUS ICON
  // ============================================================

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

  // ============================================================
  // DATE ROW
  // ============================================================

  Widget dateRow({
    required IconData icon,
    required String label,
    required String date,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),

        const SizedBox(width: 10),

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            date,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final screenWidth =
        MediaQuery.of(context).size.width;

    final double titleSize =
        screenWidth < 360 ? 18 : 20;

    final double bodySize =
        screenWidth < 360 ? 13 : 14;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login first.",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Leave Status",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getStudentProfile(),

          builder: (
            context,
            profileSnapshot,
          ) {
            // ==================================================
            // PROFILE LOADING
            // ==================================================

            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            // ==================================================
            // PROFILE ERROR
            // ==================================================

            if (profileSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Text(
                    "Error loading profile:\n\n"
                    "${profileSnapshot.error}",
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            }

            final profile =
                profileSnapshot.data;

            if (profile == null) {
              return const Center(
                child: Text(
                  "Student profile not found.",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            // ==================================================
            // REAL STUDENT NAME
            // ==================================================

            final String studentName =
                profile["name"]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? profile["name"]
                        .toString()
                        .trim()
                    : "Student";

            // ==================================================
            // REGISTER NUMBER
            // ==================================================

            final String registerNo =
                profile["registerNo"]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? profile["registerNo"]
                        .toString()
                        .trim()
                    : "Not available";

            // ==================================================
            // LEAVE REQUEST STREAM
            // ==================================================

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("leave_requests")
                  .where(
                    "studentId",
                    isEqualTo: user.uid,
                  )
                  .snapshots(),

              builder: (
                context,
                snapshot,
              ) {
                // =================================================
                // ERROR
                // =================================================

                if (snapshot.hasError) {
                  return Center(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(20),
                      child: Text(
                        "Error loading leave status:\n\n"
                        "${snapshot.error}",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              bodySize,
                          color:
                              Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                // =================================================
                // LOADING
                // =================================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final requests =
                    snapshot.data?.docs ?? [];

                // =================================================
                // NO REQUESTS
                // =================================================

                if (requests.isEmpty) {
                  return Center(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(25),
                      child:
                          Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor:
                                Colors.blue
                                    .withValues(
                              alpha: 0.1,
                            ),
                            child:
                                const Icon(
                              Icons.person,
                              size: 38,
                              color:
                                  Colors.blue,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            studentName,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            "Register No: $registerNo",
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 25,
                          ),

                          Icon(
                            Icons.event_busy,
                            size: 70,
                            color:
                                Colors.grey.shade400,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          Text(
                            "No Leave Requests",
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontSize:
                                  titleSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            "Your submitted leave requests "
                            "will appear here.",
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontSize:
                                  bodySize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // =================================================
                // SORT REQUESTS NEWEST FIRST
                // =================================================

                final sortedRequests =
                    requests.toList();

                sortedRequests.sort(
                  (a, b) {
                    final aData =
                        a.data()
                            as Map<String, dynamic>;

                    final bData =
                        b.data()
                            as Map<String, dynamic>;

                    final aTime =
                        aData["createdAt"];

                    final bTime =
                        bData["createdAt"];

                    if (aTime is Timestamp &&
                        bTime is Timestamp) {
                      return bTime.compareTo(
                        aTime,
                      );
                    }

                    return 0;
                  },
                );

                // =================================================
                // REQUEST LIST
                // =================================================

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(15),

                  itemCount:
                      sortedRequests.length,

                  itemBuilder:
                      (context, index) {
                    final doc =
                        sortedRequests[index];

                    final data =
                        doc.data()
                            as Map<String,
                                dynamic>;

                    // =============================================
                    // STATUS
                    // =============================================

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

                    // =============================================
                    // REASON
                    // =============================================

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

                    // =============================================
                    // FROM DATE
                    // =============================================

                    DateTime? fromDate;

                    if (data["fromDate"]
                        is Timestamp) {
                      fromDate =
                          (data["fromDate"]
                                  as Timestamp)
                              .toDate();
                    }

                    // =============================================
                    // TO DATE
                    // =============================================

                    DateTime? toDate;

                    if (data["toDate"]
                        is Timestamp) {
                      toDate =
                          (data["toDate"]
                                  as Timestamp)
                              .toDate();
                    }

                    // =============================================
                    // CREATED DATE
                    // =============================================

                    DateTime? createdAt;

                    if (data["createdAt"]
                        is Timestamp) {
                      createdAt =
                          (data["createdAt"]
                                  as Timestamp)
                              .toDate();
                    }

                    // =============================================
                    // DATE TEXT
                    // =============================================

                    final String fromDateText =
                        fromDate == null
                            ? "Not specified"
                            : DateFormat(
                                "dd MMM yyyy",
                              ).format(
                                fromDate,
                              );

                    final String toDateText =
                        toDate == null
                            ? "Not specified"
                            : DateFormat(
                                "dd MMM yyyy",
                              ).format(
                                toDate,
                              );

                    final Color color =
                        statusColor(
                      status,
                    );

                    // =============================================
                    // CARD
                    // =============================================

                    return Card(
                      elevation: 4,

                      margin:
                          const EdgeInsets.only(
                        bottom: 15,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            // =====================================
                            // STUDENT HEADER
                            // =====================================

                            Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .all(12),

                              decoration:
                                  BoxDecoration(
                                color: Colors.blue
                                    .withValues(
                                  alpha: 0.06,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Colors.blue,
                                    child:
                                        const Icon(
                                      Icons.person,
                                      color:
                                          Colors.white,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          studentName,
                                          maxLines:
                                              2,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 3,
                                        ),

                                        Text(
                                          "Register No: "
                                          "$registerNo",
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =====================================
                            // LEAVE REQUEST TITLE
                            // =====================================

                            Text(
                              "Leave Request",
                              style:
                                  TextStyle(
                                fontSize:
                                    titleSize,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // =====================================
                            // REASON
                            // =====================================

                            const Text(
                              "Reason",
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize:
                                    15,
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
                                color: Colors
                                    .grey
                                    .withValues(
                                  alpha: 0.06,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),

                              child: Text(
                                reason,
                                softWrap:
                                    true,
                                style:
                                    TextStyle(
                                  fontSize:
                                      bodySize,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // =====================================
                            // FROM DATE
                            // =====================================

                            dateRow(
                              icon: Icons
                                  .calendar_today,
                              label: "From:",
                              date:
                                  fromDateText,
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            // =====================================
                            // TO DATE
                            // =====================================

                            dateRow(
                              icon:
                                  Icons.event,
                              label: "To:",
                              date:
                                  toDateText,
                            ),

                            if (createdAt !=
                                null) ...[
                              const SizedBox(
                                height: 10,
                              ),

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Icon(
                                    Icons
                                        .access_time,
                                    size: 19,
                                    color:
                                        Colors.grey,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                    child: Text(
                                      "Submitted: "
                                      "${DateFormat(
                                        "dd MMM yyyy • hh:mm a",
                                      ).format(
                                        createdAt,
                                      )}",
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(
                              height: 18,
                            ),

                            // =====================================
                            // STATUS
                            // =====================================

                            Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .all(12),

                              decoration:
                                  BoxDecoration(
                                color:
                                    color.withValues(
                                  alpha: 0.1,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),

                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Icon(
                                    statusIcon(
                                      status,
                                    ),
                                    color:
                                        color,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                    child:
                                        Text(
                                      "Status: "
                                      "$status",
                                      softWrap:
                                          true,
                                      style:
                                          TextStyle(
                                        color:
                                            color,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize:
                                            16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}