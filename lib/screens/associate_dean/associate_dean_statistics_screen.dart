import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssociateDeanStatisticsScreen extends StatelessWidget {
  const AssociateDeanStatisticsScreen({super.key});

  Future<int> getCount(String collection) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs.length;
  }

  Widget buildCard(
    String title,
    IconData icon,
    Color color,
    AsyncSnapshot<int> snapshot,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 45,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState ==
                ConnectionState.waiting)
              const CircularProgressIndicator()
            else
              Text(
                "${snapshot.data ?? 0}",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collections = [
      {
        "title": "Students",
        "collection": "users",
        "icon": Icons.school,
        "color": Colors.green,
      },
      {
        "title": "Assignments",
        "collection": "assignments",
        "icon": Icons.assignment,
        "color": Colors.indigo,
      },
      {
        "title": "Announcements",
        "collection": "announcements",
        "icon": Icons.campaign,
        "color": Colors.orange,
      },
      {
        "title": "Leave Requests",
        "collection": "leave_requests",
        "icon": Icons.event_available,
        "color": Colors.red,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Statistics"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: collections.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final item = collections[index];

            return FutureBuilder<int>(
              future: getCount(item["collection"] as String),
              builder: (context, snapshot) {
                return buildCard(
                  item["title"] as String,
                  item["icon"] as IconData,
                  item["color"] as Color,
                  snapshot,
                );
              },
            );
          },
        ),
      ),
    );
  }
}