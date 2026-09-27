import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherAnnouncementScreen extends StatefulWidget {
  const TeacherAnnouncementScreen({super.key});

  @override
  State<TeacherAnnouncementScreen> createState() =>
      _TeacherAnnouncementScreenState();
}

class _TeacherAnnouncementScreenState
    extends State<TeacherAnnouncementScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isLoading = false;

  // 📌 Pin Announcement
  bool isPinned = false;

  // 📂 Announcement Category
  String selectedCategory = "General";

  final List<String> categories = [
    "General",
    "Exam",
    "Event",
    "Academic",
    "Holiday",
    "Urgent",
    "Placement",
  ];

  // Expiry ON/OFF
  bool expiryEnabled = false;

  // Default expiry days
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

  Future<void> publishAnnouncement() async {
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
      isLoading = true;
    });

    final createdAt = Timestamp.now();

    final expiryAt = Timestamp.fromDate(
      createdAt.toDate().add(
        Duration(
          days: expiryEnabled ? expiryDays : 7,
        ),
      ),
    );

    final editableUntil = Timestamp.fromDate(
      createdAt.toDate().add(
        const Duration(hours: 1),
      ),
    );

    await FirebaseFirestore.instance.collection("announcements").add({
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),

      // Dates
      "createdAt": createdAt,
      "expiryAt": expiryAt,
      "editableUntil": editableUntil,

      // Expiry
      "expiryEnabled": expiryEnabled,
      "expiryDays": expiryEnabled ? expiryDays : 7,

      // Pin
      "isPinned": isPinned,

      // Category
      "category": selectedCategory,

      // Teacher Details
      "teacherId": "teacher001",
      "teacherName": "Subject Teacher",
    });

    setState(() {
      isLoading = false;
      expiryEnabled = false;
      expiryDays = 7;
      isPinned = false;
      selectedCategory = "General";
    });

    titleController.clear();
    messageController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Announcement Published Successfully"),
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
        title: const Text("Create Announcement"),
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

            const SizedBox(height: 20),

            // Category
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // Pin Announcement
            SwitchListTile(
              title: const Text(
                "📌 Pin this announcement",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Pinned announcements always appear first for students",
              ),
              value: isPinned,
              onChanged: (value) {
                setState(() {
                  isPinned = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // Expiry Switch
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
                onPressed: isLoading ? null : publishAnnouncement,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Publish",
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