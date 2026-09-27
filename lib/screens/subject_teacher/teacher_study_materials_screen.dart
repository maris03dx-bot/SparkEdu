import 'package:flutter/material.dart';

import 'upload_material_screen.dart';
import 'manage_materials_screen.dart';

class TeacherStudyMaterialsScreen
    extends StatelessWidget {
  const TeacherStudyMaterialsScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Study Materials",
        ),
        centerTitle: true,
        backgroundColor:
            Colors.blue,
        foregroundColor:
            Colors.white,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            "Study Materials",
            style:
                TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            "Share and manage learning resources for your students.",
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading:
                  CircleAvatar(
                backgroundColor:
                    Colors.orange
                        .withValues(
                  alpha: 0.12,
                ),
                child:
                    const Icon(
                  Icons.upload_file,
                  color:
                      Colors.orange,
                ),
              ),
              title:
                  const Text(
                "Upload Material",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  const Text(
                "Upload notes and learning resources",
              ),
              trailing:
                  const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UploadMaterialScreen(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading:
                  CircleAvatar(
                backgroundColor:
                    Colors.teal
                        .withValues(
                  alpha: 0.12,
                ),
                child:
                    const Icon(
                  Icons.folder,
                  color:
                      Colors.teal,
                ),
              ),
              title:
                  const Text(
                "Manage Materials",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  const Text(
                "View and manage uploaded materials",
              ),
              trailing:
                  const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ManageMaterialsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}