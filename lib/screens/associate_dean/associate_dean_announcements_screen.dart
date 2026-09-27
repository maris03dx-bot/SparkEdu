import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssociateDeanAnnouncementsScreen extends StatefulWidget {
  const AssociateDeanAnnouncementsScreen({super.key});

  @override
  State<AssociateDeanAnnouncementsScreen> createState() =>
      _AssociateDeanAnnouncementsScreenState();
}

class _AssociateDeanAnnouncementsScreenState
    extends State<AssociateDeanAnnouncementsScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  Future<void> addAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection("announcements")
        .add({
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),
      "createdAt": Timestamp.now(),
      "expiryAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      "isPinned": false,
    });

    titleController.clear();
    messageController.clear();

    if (mounted) Navigator.pop(context);
  }

  Future<void> deleteAnnouncement(String id) async {
    await FirebaseFirestore.instance
        .collection("announcements")
        .doc(id)
        .delete();
  }

  Future<void> togglePin(
    String id,
    bool currentValue,
  ) async {
    await FirebaseFirestore.instance
        .collection("announcements")
        .doc(id)
        .update({
      "isPinned": !currentValue,
    });
  }

  void showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text(
          "Are you sure you want to delete this announcement?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await deleteAnnouncement(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Announcement"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Message",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: addAnnouncement,
            child: const Text("Publish"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("announcements")
            .orderBy("isPinned", descending: true)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return const Center(
              child: Text(
                "No Announcements",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              final bool isPinned =
                  data["isPinned"] ?? false;

              return Card(
                elevation: 5,
                margin:
                    const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPinned
                        ? Colors.orange
                        : Colors.blue,
                    child: Icon(
                      isPinned
                          ? Icons.push_pin
                          : Icons.campaign,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data["title"] ?? "",
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isPinned)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                          child: const Text(
                            "PINNED",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(top: 8),
                    child: Text(
                      data["message"] ?? "",
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isPinned
                            ? "Unpin"
                            : "Pin",
                        icon: Icon(
                          isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          togglePin(
                            doc.id,
                            isPinned,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: "Delete",
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          showDeleteDialog(
                            doc.id,
                          );
                        },
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