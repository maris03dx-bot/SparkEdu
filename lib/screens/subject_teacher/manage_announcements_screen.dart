import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'edit_announcement_screen.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState
    extends State<ManageAnnouncementsScreen> {
  // ==========================================================
  // CREATE ANNOUNCEMENT CONTROLLERS
  // ==========================================================

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController messageController =
      TextEditingController();

  bool isCreating = false;

  bool expiryEnabled = false;

  int expiryDays = 7;

  final List<int> dayOptions = [
    1,
    3,
    7,
    15,
    30,
    45,
    60,
  ];

  // ==========================================================
  // CREATE ANNOUNCEMENT
  // ==========================================================

  Future<void> createAnnouncement() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    // ========================================================
    // VALIDATION
    // ========================================================

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please enter both title and announcement message.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isCreating = true;
    });

    try {
      // ======================================================
      // CREATED TIME
      // ======================================================

      final DateTime createdTime = DateTime.now();

      // ======================================================
      // EXPIRY
      // ======================================================

      final int selectedExpiryDays =
          expiryEnabled ? expiryDays : 7;

      final DateTime expiryTime = createdTime.add(
        Duration(days: selectedExpiryDays),
      );

      // ======================================================
      // SAVE TO FIRESTORE
      // ======================================================

      await FirebaseFirestore.instance
          .collection("announcements")
          .add({
        "title": title,
        "message": message,

        "createdAt":
            FieldValue.serverTimestamp(),

        "expiryAt":
            Timestamp.fromDate(expiryTime),

        "editableUntil":
            Timestamp.fromDate(expiryTime),

        "expiryEnabled":
            expiryEnabled,

        "expiryDays":
            selectedExpiryDays,

        "isPinned": false,

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ======================================================
      // CLEAR FORM
      // ======================================================

      titleController.clear();
      messageController.clear();

      setState(() {
        expiryEnabled = false;
        expiryDays = 7;
        isCreating = false;
      });

      // ======================================================
      // SUCCESS MESSAGE
      // ======================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Announcement Published Successfully",
          ),
        ),
      );

      // Close the create form
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to create announcement:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // SHOW CREATE ANNOUNCEMENT SCREEN
  // ==========================================================

  Future<void> openCreateAnnouncement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateAnnouncementPage(
          titleController: titleController,
          messageController: messageController,
          expiryEnabled: expiryEnabled,
          expiryDays: expiryDays,
          dayOptions: dayOptions,
          isCreating: isCreating,
          onExpiryChanged: (value) {
            setState(() {
              expiryEnabled = value;
            });
          },
          onExpiryDaysChanged: (value) {
            setState(() {
              expiryDays = value;
            });
          },
          onCreate: createAnnouncement,
        ),
      ),
    );
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return "Not Available";
    }

    return DateFormat(
      'dd MMM yyyy • hh:mm a',
    ).format(timestamp.toDate());
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Announcements",
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            tooltip: "Create Announcement",
            icon: const Icon(
              Icons.add_circle_outline,
            ),
            onPressed:
                isCreating ? null : openCreateAnnouncement,
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("announcements")
            .orderBy(
              "isPinned",
              descending: true,
            )
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
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

          final announcements =
              snapshot.data?.docs ?? [];

          // ====================================================
          // EMPTY STATE
          // ====================================================

          if (announcements.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildCreateButton(),

                const SizedBox(height: 40),

                const Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Colors.grey,
                ),

                const SizedBox(height: 15),

                const Text(
                  "No announcements found",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Create your first announcement using the button above.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          }

          // ====================================================
          // ANNOUNCEMENT LIST
          // ====================================================

          return ListView(
            padding: const EdgeInsets.all(15),

            children: [
              _buildCreateButton(),

              const SizedBox(height: 20),

              ...announcements.map(
                (doc) {
                  return _buildAnnouncementCard(
                    context,
                    doc,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // CREATE BUTTON
  // ==========================================================

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            isCreating ? null : openCreateAnnouncement,

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          "Create Announcement",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ANNOUNCEMENT CARD
  // ==========================================================

  Widget _buildAnnouncementCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final Timestamp? createdAt =
        data["createdAt"] is Timestamp
            ? data["createdAt"] as Timestamp
            : null;

    final Timestamp? expiryAt =
        data["expiryAt"] is Timestamp
            ? data["expiryAt"] as Timestamp
            : null;

    final Timestamp? editableUntil =
        data["editableUntil"] is Timestamp
            ? data["editableUntil"] as Timestamp
            : null;

    final bool isPinned =
        data["isPinned"] ?? false;

    final DateTime now = DateTime.now();

    final bool canEdit =
        editableUntil != null
            ? now.isBefore(
                editableUntil.toDate(),
              )
            : false;

    final bool isExpired =
        expiryAt != null
            ? now.isAfter(
                expiryAt.toDate(),
              )
            : false;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),

      elevation: 5,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // TITLE
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: Text(
                    data["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                if (isPinned)
                  const Icon(
                    Icons.push_pin,
                    color: Colors.orange,
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // MESSAGE
            // ==================================================

            Text(
              data["message"] ?? "",
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),

            const Divider(
              height: 25,
            ),

            // ==================================================
            // CREATED
            // ==================================================

            Text(
              "Published : ${formatTimestamp(createdAt)}",
            ),

            const SizedBox(height: 5),

            // ==================================================
            // EXPIRY
            // ==================================================

            Text(
              "Expires : ${expiryAt != null ? formatTimestamp(expiryAt) : "Default (7 Days)"}",
            ),

            const SizedBox(height: 10),

            // ==================================================
            // STATUS
            // ==================================================

            Text(
              isExpired
                  ? "Status : Expired"
                  : "Status : Active",

              style: TextStyle(
                color: isExpired
                    ? Colors.red
                    : Colors.green,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ACTIONS
            // ==================================================

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: [
                // ------------------------------------------------
                // PIN / UNPIN
                // ------------------------------------------------

                ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        isPinned
                            ? const Color
                                .fromARGB(
                                255,
                                207,
                                205,
                                67,
                              )
                            : const Color
                                .fromARGB(
                                255,
                                0,
                                233,
                                8,
                              ),
                    foregroundColor:
                        Colors.black,
                  ),

                  onPressed: () async {
                    try {
                      await FirebaseFirestore
                          .instance
                          .collection(
                            "announcements",
                          )
                          .doc(doc.id)
                          .update({
                        "isPinned":
                            !isPinned,
                        "updatedAt":
                            FieldValue
                                .serverTimestamp(),
                      });

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            isPinned
                                ? "Announcement Unpinned"
                                : "Announcement Pinned",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          backgroundColor:
                              Colors.red,
                          content: Text(
                            "Unable to update announcement:\n$e",
                          ),
                        ),
                      );
                    }
                  },

                  icon: Icon(
                    isPinned
                        ? Icons.push_pin
                        : Icons
                            .push_pin_outlined,
                  ),

                  label: Text(
                    isPinned
                        ? "Unpin"
                        : "Pin",
                  ),
                ),

                // ------------------------------------------------
                // EDIT
                // ------------------------------------------------

                if (canEdit)
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.edit,
                    ),

                    label: const Text(
                      "Edit",
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAnnouncementScreen(
                            documentId:
                                doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                  ),

                // ------------------------------------------------
                // DELETE
                // ------------------------------------------------

                ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                  ),

                  icon: const Icon(
                    Icons.delete,
                  ),

                  label: const Text(
                    "Delete",
                  ),

                  onPressed: () async {
                    final delete =
                        await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          AlertDialog(
                        title: const Text(
                          "Delete Announcement",
                        ),

                        content:
                            const Text(
                          "Are you sure you want to delete this announcement?",
                        ),

                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                              context,
                              false,
                            ),
                            child:
                                const Text(
                              "Cancel",
                            ),
                          ),

                          ElevatedButton(
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.red,
                              foregroundColor:
                                  Colors.white,
                            ),

                            onPressed: () =>
                                Navigator.pop(
                              context,
                              true,
                            ),

                            child:
                                const Text(
                              "Delete",
                            ),
                          ),
                        ],
                      ),
                    );

                    if (delete != true) {
                      return;
                    }

                    try {
                      await FirebaseFirestore
                          .instance
                          .collection(
                            "announcements",
                          )
                          .doc(doc.id)
                          .delete();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Announcement Deleted Successfully",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          backgroundColor:
                              Colors.red,
                          content: Text(
                            "Unable to delete announcement:\n$e",
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CREATE ANNOUNCEMENT PAGE
// ============================================================================

class _CreateAnnouncementPage
    extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController messageController;

  final bool expiryEnabled;
  final int expiryDays;

  final List<int> dayOptions;

  final bool isCreating;

  final ValueChanged<bool> onExpiryChanged;

  final ValueChanged<int> onExpiryDaysChanged;

  final VoidCallback onCreate;

  const _CreateAnnouncementPage({
    required this.titleController,
    required this.messageController,
    required this.expiryEnabled,
    required this.expiryDays,
    required this.dayOptions,
    required this.isCreating,
    required this.onExpiryChanged,
    required this.onExpiryDaysChanged,
    required this.onCreate,
  });

  @override
  State<_CreateAnnouncementPage> createState() =>
      _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState
    extends State<_CreateAnnouncementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Announcement",
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // TITLE
            // ==================================================

            TextField(
              controller:
                  widget.titleController,

              enabled:
                  !widget.isCreating,

              decoration:
                  InputDecoration(
                labelText: "Title",
                hintText:
                    "Enter announcement title",
                prefixIcon:
                    const Icon(
                  Icons.title,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // MESSAGE
            // ==================================================

            TextField(
              controller:
                  widget.messageController,

              enabled:
                  !widget.isCreating,

              maxLines: 7,

              decoration:
                  InputDecoration(
                labelText:
                    "Announcement",
                hintText:
                    "Write your announcement here...",
                prefixIcon:
                    const Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: 100,
                  ),
                  child: Icon(
                    Icons
                        .campaign_outlined,
                  ),
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // EXPIRY
            // ==================================================

            Card(
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                side: BorderSide(
                  color:
                      Colors.grey.shade300,
                ),
              ),

              child: Column(
                children: [
                  SwitchListTile(
                    title:
                        const Text(
                      "Enable Custom Expiry",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    subtitle: Text(
                      widget.expiryEnabled
                          ? "Announcement expires after selected days"
                          : "Default expiry: 7 days",
                    ),

                    value:
                        widget.expiryEnabled,

                    onChanged:
                        widget.isCreating
                            ? null
                            : widget
                                .onExpiryChanged,
                  ),

                  if (widget.expiryEnabled)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),

                      child:
                          DropdownButtonFormField<
                              int>(
                        initialValue:
                            widget.expiryDays,

                        decoration:
                            const InputDecoration(
                          labelText:
                              "Expiry Days",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: widget
                            .dayOptions
                            .map(
                          (day) {
                            return DropdownMenuItem<
                                int>(
                              value: day,
                              child: Text(
                                "$day Days",
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            widget.isCreating
                                ? null
                                : (value) {
                                    if (value !=
                                        null) {
                                      widget
                                          .onExpiryDaysChanged(
                                        value,
                                      );

                                      setState(
                                        () {},
                                      );
                                    }
                                  },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // PUBLISH BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                    widget.isCreating
                        ? null
                        : widget.onCreate,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),

                icon: widget.isCreating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.campaign,
                      ),

                label: Text(
                  widget.isCreating
                      ? "Publishing..."
                      : "Publish Announcement",

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              "New announcements are active immediately. "
              "Default expiry is 7 days.",
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}