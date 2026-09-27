import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  State<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState
    extends State<UploadMaterialScreen> {
  final TextEditingController titleController =
      TextEditingController();

  String? selectedSubject;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Study Material"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [

            // ==================================================
            // MATERIAL TITLE
            // ==================================================

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Material Title",
                hintText: "Example: Unit 1 AI Notes",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SUBJECT
            // ==================================================

            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection("subjects")
                  .orderBy("name")
                  .snapshots(),

              builder: (context, snapshot) {

                // ERROR
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Unable to load subjects.",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                // LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final subjects =
                    snapshot.data?.docs ?? [];

                // NO SUBJECTS
                if (subjects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No subjects available. "
                            "Please ask the Mentor to add a subject.",
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // SUBJECT DROPDOWN
                return DropdownButtonFormField<String>(
                  initialValue: selectedSubject,

                  decoration:
                      const InputDecoration(
                    labelText: "Subject",
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.menu_book),
                  ),

                  items: subjects.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final subjectName =
                        data["name"]
                            ?.toString() ??
                        "Unnamed Subject";

                    return DropdownMenuItem<String>(
                      value: subjectName,
                      child: Text(
                        subjectName,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 25),

            // ==================================================
            // CHOOSE FILE
            // ==================================================

            SizedBox(
              height: 60,

              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "File picker will be added later.",
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.upload_file,
                ),

                label: const Text(
                  "Choose PDF / PPT / DOC",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // UPLOAD
            // ==================================================

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {

                  if (titleController.text
                      .trim()
                      .isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter material title.",
                        ),
                        backgroundColor:
                            Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedSubject == null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select a subject.",
                        ),
                        backgroundColor:
                            Colors.red,
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        "Material uploaded successfully "
                        "under $selectedSubject!",
                      ),
                      backgroundColor:
                          Colors.green,
                    ),
                  );
                },

                icon: const Icon(
                  Icons.cloud_upload,
                ),

                label: const Text(
                  "Upload Material",
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