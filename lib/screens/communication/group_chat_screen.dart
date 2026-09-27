import 'package:flutter/material.dart';
import 'subject_screen.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subject Group Chat"),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.groups),
          label: const Text("Open Subject Groups"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}