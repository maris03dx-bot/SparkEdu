import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  State<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends State<AnnouncementManagementScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool isPinned = false;
  DateTime? expiryDate;

  Future<void> pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  Future<void> publishAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty ||
        expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields"),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("announcements")
        .add({
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),
      "isPinned": isPinned,
      "createdAt": Timestamp.now(),
      "expiryAt": Timestamp.fromDate(expiryDate!),
    });

    titleController.clear();
    messageController.clear();

    setState(() {
      isPinned = false;
      expiryDate = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Announcement Published"),
      ),
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    await FirebaseFirestore.instance
        .collection("announcements")
        .doc(id)
        .delete();
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
        title: const Text("Manage Announcements"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Announcement Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Announcement Message",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            SwitchListTile(
              title: const Text("Pin this Announcement"),
              value: isPinned,
              onChanged: (value) {
                setState(() {
                  isPinned = value;
                });
              },
            ),

            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                expiryDate == null
                    ? "Select Expiry Date"
                    : expiryDate!
                        .toString()
                        .split(" ")
                        .first,
              ),
              trailing: ElevatedButton(
                onPressed: pickExpiryDate,
                child: const Text("Choose"),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.campaign),
                label: const Text(
                  "Publish Announcement",
                ),
                onPressed: publishAnnouncement,
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Published Announcements",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("announcements")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text(
                    "No Announcements",
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];

                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          data["isPinned"]
                              ? Icons.push_pin
                              : Icons.campaign,
                          color: data["isPinned"]
                              ? Colors.orange
                              : Colors.blue,
                        ),
                        title: Text(data["title"]),
                        subtitle: Text(data["message"]),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            deleteAnnouncement(doc.id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}