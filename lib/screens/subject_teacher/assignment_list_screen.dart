import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'assignment_screen.dart';

class AssignmentListScreen extends StatelessWidget {
  const AssignmentListScreen({super.key});

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No due date';
    }

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ===========================================================================
  // OVERDUE CHECK
  // ===========================================================================

  bool isOverdue(Timestamp? timestamp) {
    if (timestamp == null) {
      return false;
    }

    final dueDate = timestamp.toDate();

    final endOfDueDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );

    return DateTime.now().isAfter(endOfDueDay);
  }

  // ===========================================================================
  // DUE SOON CHECK
  // ===========================================================================

  bool isDueSoon(Timestamp? timestamp) {
    if (timestamp == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final dueDate = timestamp.toDate();

    final dueDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    final difference =
        dueDay.difference(today).inDays;

    return difference >= 0 && difference <= 7;
  }

  // ===========================================================================
  // OPEN PDF
  // ===========================================================================

  Future<void> openPdf(
    BuildContext context,
    String pdfUrl,
  ) async {
    if (pdfUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'PDF link is not available.',
          ),
        ),
      );

      return;
    }

    try {
      final Uri url = Uri.parse(pdfUrl);

      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Unable to open PDF.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Unable to open PDF:\n$e',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // GET TEACHER ASSIGNMENTS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      assignmentStream(String teacherUid) {
    return FirebaseFirestore.instance
        .collection('assignments')
        .where(
          'teacherUid',
          isEqualTo: teacherUid,
        )
        .snapshots();
  }

  // ===========================================================================
  // SORT ASSIGNMENTS
  // ===========================================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      sortAssignments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        docs,
  ) {
    final sorted =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      docs,
    );

    sorted.sort(
      (a, b) {
        final aCreated =
            a.data()['createdAt'];

        final bCreated =
            b.data()['createdAt'];

        if (aCreated is Timestamp &&
            bCreated is Timestamp) {
          return bCreated.compareTo(aCreated);
        }

        if (aCreated is Timestamp) {
          return -1;
        }

        if (bCreated is Timestamp) {
          return 1;
        }

        return 0;
      },
    );

    return sorted;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFFF6F4FB),
        appBar: AppBar(
          title: const Text(
            'Assignments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              const Color(0xFF6B4FD3),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please login again to view assignments.',
          ),
        ),
      );
    }

    final teacherUid = user.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F4FB),

      appBar: AppBar(
        title: const Text(
          'Assignments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color(0xFF6B4FD3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream:
            assignmentStream(teacherUid),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Unable to load assignments.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final rawAssignments =
              snapshot.data?.docs ?? [];

          final assignments =
              sortAssignments(
            rawAssignments,
          );

          int totalAssignments =
              assignments.length;

          int overdueAssignments = 0;

          int dueSoonAssignments = 0;

          for (final doc in assignments) {
            final data = doc.data();

            final Timestamp? dueDate =
                data['dueDate'] is Timestamp
                    ? data['dueDate']
                        as Timestamp
                    : null;

            if (isOverdue(dueDate)) {
              overdueAssignments++;
            } else if (isDueSoon(dueDate)) {
              dueSoonAssignments++;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('assignments')
                  .where(
                    'teacherUid',
                    isEqualTo: teacherUid,
                  )
                  .get();
            },

            child: ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                // ===========================================================
                // CREATE ASSIGNMENT BUTTON
                // ===========================================================

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AssignmentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 24,
                    ),
                    label: const Text(
                      'Create Assignment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6B4FD3,
                      ),
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===========================================================
                // SUMMARY CARDS
                // ===========================================================

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon:
                            Icons.assignment,
                        title: 'Total',
                        value:
                            totalAssignments
                                .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _summaryCard(
                        icon:
                            Icons.schedule,
                        title: 'Due Soon',
                        value:
                            dueSoonAssignments
                                .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _summaryCard(
                        icon: Icons
                            .warning_amber_rounded,
                        title: 'Overdue',
                        value:
                            overdueAssignments
                                .toString(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ===========================================================
                // SECTION TITLE
                // ===========================================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Assignments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFF25213A),
                        ),
                      ),
                    ),

                    Text(
                      '$totalAssignments assignment'
                      '${totalAssignments == 1 ? '' : 's'}',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ===========================================================
                // EMPTY STATE
                // ===========================================================

                if (assignments.isEmpty)
                  _buildEmptyState(context),

                // ===========================================================
                // ASSIGNMENT LIST
                // ===========================================================

                ...assignments.map(
                  (doc) {
                    final data =
                        doc.data();

                    final String subject =
                        (data['subject'] ??
                                'Unknown Subject')
                            .toString();

                    final String title =
                        (data['title'] ??
                                'Untitled Assignment')
                            .toString();

                    final String description =
                        (data['description'] ??
                                '')
                            .toString();

                    final String pdfName =
                        (data['pdfName'] ??
                                '')
                            .toString();

                    final String pdfUrl =
                        (data['pdfUrl'] ??
                                '')
                            .toString();

                    final Timestamp? dueDate =
                        data['dueDate']
                                is Timestamp
                            ? data['dueDate']
                                as Timestamp
                            : null;

                    final bool overdue =
                        isOverdue(dueDate);

                    final bool dueSoon =
                        isDueSoon(dueDate);

                    return _assignmentCard(
                      context: context,
                      subject: subject,
                      title: title,
                      description:
                          description,
                      pdfName: pdfName,
                      pdfUrl: pdfUrl,
                      dueDate: dueDate,
                      overdue: overdue,
                      dueSoon: dueSoon,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SUMMARY CARD
  // ===========================================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF6B4FD3),
            size: 25,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF25213A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(top: 20),
      padding:
          const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 70,
            color:
                Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'No Assignments Yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF25213A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first assignment using the button above.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AssignmentScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Create Assignment',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF6B4FD3),
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ASSIGNMENT CARD
  // ===========================================================================

  Widget _assignmentCard({
    required BuildContext context,
    required String subject,
    required String title,
    required String description,
    required String pdfName,
    required String pdfUrl,
    required Timestamp? dueDate,
    required bool overdue,
    required bool dueSoon,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ===============================================================
            // SUBJECT + STATUS
            // ===============================================================

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF6B4FD3,
                      ).withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                    ),
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF6B4FD3,
                        ),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                if (overdue)
                  _statusBadge(
                    text: 'Overdue',
                    icon: Icons
                        .warning_amber_rounded,
                  )
                else if (dueSoon)
                  _statusBadge(
                    text: 'Due Soon',
                    icon:
                        Icons.schedule,
                  ),
              ],
            ),

            const SizedBox(height: 13),

            // ===============================================================
            // TITLE
            // ===============================================================

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF25213A),
              ),
            ),

            // ===============================================================
            // DESCRIPTION
            // ===============================================================

            if (description
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 15),

            // ===============================================================
            // DUE DATE
            // ===============================================================

            Row(
              children: [
                Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 18,
                  color: overdue
                      ? Colors.red
                      : const Color(
                          0xFF6B4FD3,
                        ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'Due: ${formatDate(dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color: overdue
                        ? Colors.red
                        : Colors.grey
                            .shade700,
                  ),
                ),
              ],
            ),

            // ===============================================================
            // PDF
            // ===============================================================

            if (pdfName
                .trim()
                .isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              InkWell(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                onTap: pdfUrl
                        .trim()
                        .isEmpty
                    ? null
                    : () {
                        openPdf(
                          context,
                          pdfUrl,
                        );
                      },
                child: Container(
                  padding:
                      const EdgeInsets
                          .all(10),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red
                            .withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .picture_as_pdf,
                        color:
                            Colors.red,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          pdfName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                      Icon(
                        pdfUrl
                                .trim()
                                .isEmpty
                            ? Icons
                                .link_off
                            : Icons
                                .open_in_new,
                        color:
                            Colors.grey
                                .shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STATUS BADGE
  // ===========================================================================

  Widget _statusBadge({
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                Colors.orange.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
              color:
                  Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }
}