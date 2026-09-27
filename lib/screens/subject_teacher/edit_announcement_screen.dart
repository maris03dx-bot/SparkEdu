import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const EditAnnouncementScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<EditAnnouncementScreen> createState() =>
      _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState
    extends State<EditAnnouncementScreen> {
  late TextEditingController titleController;
  late TextEditingController messageController;

  bool isSaving = false;

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

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(text: widget.data["title"]);

    messageController =
        TextEditingController(text: widget.data["message"]);

    expiryEnabled =
        widget.data["expiryEnabled"] ?? false;

    expiryDays =
        widget.data["expiryDays"] ?? 7;
  }

  Future<void> updateAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final createdAt =
        widget.data["createdAt"] as Timestamp;

    final expiryAt = Timestamp.fromDate(
      createdAt.toDate().add(
        Duration(
          days: expiryEnabled ? expiryDays : 7,
        ),
      ),
    );

    await FirebaseFirestore.instance
        .collection("announcements")
        .doc(widget.documentId)
        .update({
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),
      "expiryEnabled": expiryEnabled,
      "expiryDays": expiryEnabled
          ? expiryDays
          : 7,
      "expiryAt": expiryAt,
      "updatedAt": Timestamp.now(),
    });

    setState(() {
      isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Announcement Updated Successfully",
        ),
      ),
    );

    Navigator.pop(context);
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
        title: const Text("Edit Announcement"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Announcement",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SwitchListTile(
              title: const Text(
                "Enable Custom Expiry",
              ),
              subtitle: Text(
                expiryEnabled
                    ? "Announcement expires after selected days"
                    : "Default expiry: 7 days",
              ),
              value: expiryEnabled,
              onChanged: (value) {
                setState(() {
                  expiryEnabled = value;
                });
              },
            ),

            if (expiryEnabled)
              DropdownButtonFormField<int>(
                initialValue: expiryDays,
                decoration: const InputDecoration(
                  labelText: "Expiry Days",
                  border: OutlineInputBorder(),
                ),
                items: dayOptions.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text("$day Days"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    expiryDays = value!;
                  });
                },
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    isSaving ? null : updateAnnouncement,
                child: isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}