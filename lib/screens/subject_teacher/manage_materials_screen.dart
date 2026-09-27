import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageMaterialsScreen extends StatelessWidget {
  const ManageMaterialsScreen({super.key});

  // ==========================================================
  // MATERIAL ICON
  // ==========================================================

  IconData getMaterialIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.endsWith(".pdf") ||
        lowerTitle.contains("pdf") ||
        lowerTitle.contains("notes")) {
      return Icons.picture_as_pdf;
    }

    if (lowerTitle.endsWith(".ppt") ||
        lowerTitle.endsWith(".pptx") ||
        lowerTitle.contains("ppt")) {
      return Icons.slideshow;
    }

    if (lowerTitle.endsWith(".doc") ||
        lowerTitle.endsWith(".docx")) {
      return Icons.description;
    }

    return Icons.insert_drive_file;
  }

  // ==========================================================
  // MATERIAL ICON COLOR
  // ==========================================================

  Color getMaterialColor(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.endsWith(".pdf") ||
        lowerTitle.contains("pdf") ||
        lowerTitle.contains("notes")) {
      return Colors.red;
    }

    if (lowerTitle.endsWith(".ppt") ||
        lowerTitle.endsWith(".pptx") ||
        lowerTitle.contains("ppt")) {
      return Colors.orange;
    }

    if (lowerTitle.endsWith(".doc") ||
        lowerTitle.endsWith(".docx")) {
      return Colors.blue;
    }

    return Colors.grey;
  }

  // ==========================================================
  // DELETE MATERIAL
  // ==========================================================

  Future<void> deleteMaterial(
    BuildContext context,
    DocumentSnapshot document,
  ) async {
    final data =
        document.data() as Map<String, dynamic>? ?? {};

    final String title =
        data["title"]?.toString() ?? "this material";

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete Material?",
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("study_materials")
          .doc(document.id)
          .delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Material deleted successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to delete material: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // MATERIAL CARD
  // ==========================================================

  Widget buildMaterialCard(
    BuildContext context,
    DocumentSnapshot document,
  ) {
    final Map<String, dynamic> data =
        document.data() as Map<String, dynamic>? ?? {};

    final String title =
        data["title"]?.toString().trim().isNotEmpty == true
            ? data["title"].toString().trim()
            : "Study Material";

    final String subject =
        data["subject"]?.toString().trim().isNotEmpty == true
            ? data["subject"].toString().trim()
            : "Subject not available";

    final IconData icon =
        getMaterialIcon(title);

    final Color color =
        getMaterialColor(title);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Icon(
          icon,
          color: color,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            subject,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () {
            deleteMaterial(
              context,
              document,
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Materials",
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("study_materials")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading materials:\n\n"
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ----------------------------------------------------
          // MATERIALS
          // ----------------------------------------------------

          final materials =
              snapshot.data?.docs ?? [];

          // ----------------------------------------------------
          // EMPTY
          // ----------------------------------------------------

          if (materials.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      "No study materials found",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      "Study materials will appear "
                      "here when they are uploaded.",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // MATERIAL LIST
          // ----------------------------------------------------

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              30,
            ),
            itemCount: materials.length,
            itemBuilder: (
              context,
              index,
            ) {
              return buildMaterialCard(
                context,
                materials[index],
              );
            },
          );
        },
      ),
    );
  }
}