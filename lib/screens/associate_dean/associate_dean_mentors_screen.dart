import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'dean_mentor_detail_screen.dart';

class AssociateDeanMentorsScreen extends StatefulWidget {
  const AssociateDeanMentorsScreen({super.key});

  @override
  State<AssociateDeanMentorsScreen> createState() =>
      _AssociateDeanMentorsScreenState();
}

class _AssociateDeanMentorsScreenState
    extends State<AssociateDeanMentorsScreen> {
  String search = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createMentorProfile() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final employeeIdController = TextEditingController();
    final departmentController = TextEditingController();
    final yearController = TextEditingController();
    final sectionController = TextEditingController();

    bool isCreating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createProfile() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isCreating = true;
              });

              try {
                final name = nameController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                final employeeId =
                    employeeIdController.text.trim().toUpperCase();
                final department =
                    departmentController.text.trim().toUpperCase();
                final year = yearController.text.trim();
                final section =
                    sectionController.text.trim().toUpperCase();

                // Check whether the email is already used by another profile.
                final emailQuery = await _firestore
                    .collection("users")
                    .where("email", isEqualTo: email)
                    .limit(1)
                    .get();

                if (emailQuery.docs.isNotEmpty) {
                  throw Exception(
                    "A user profile with this email already exists.",
                  );
                }

                // Check whether the employee ID is already used.
                final employeeQuery = await _firestore
                    .collection("users")
                    .where("employeeId", isEqualTo: employeeId)
                    .limit(1)
                    .get();

                if (employeeQuery.docs.isNotEmpty) {
                  throw Exception(
                    "This Employee ID is already registered.",
                  );
                }

                /*
                 * At this stage we create the Firestore mentor profile.
                 *
                 * A real Firebase Authentication account will be created
                 * later through a secure account-provisioning flow.
                 *
                 * We intentionally do NOT create an Auth account from
                 * Flutter because Firebase Admin credentials must never
                 * be placed inside the mobile application.
                 */
                final mentorDoc = _firestore.collection("users").doc();

                await mentorDoc.set({
                  "uid": mentorDoc.id,
                  "name": name,
                  "email": email,
                  "employeeId": employeeId,
                  "department": department,
                  "year": year,
                  "section": section,
                  "role": "Mentor",
                  "accountStatus": "Profile Created",
                  "mustChangePassword": true,
                  "passwordStatus": "Pending",
                  "createdAt": FieldValue.serverTimestamp(),
                  "updatedAt": FieldValue.serverTimestamp(),
                });

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Mentor profile created successfully.",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  isCreating = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst("Exception: ", ""),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Create Mentor Profile"),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: "Mentor Name",
                            hintText: "Enter mentor name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Enter mentor name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Mentor Email",
                            hintText: "Enter mentor email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ?? "";

                            if (email.isEmpty) {
                              return "Enter mentor email";
                            }

                            final emailRegex = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            );

                            if (!emailRegex.hasMatch(email)) {
                              return "Enter a valid email";
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: employeeIdController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "Employee ID",
                            hintText: "Example: M002",
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Enter Employee ID";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: departmentController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "Department",
                            hintText: "Example: CSE",
                            prefixIcon: Icon(Icons.apartment),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Enter department";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: "Year",
                            hintText: "Example: II",
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Enter academic year";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: sectionController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "Section",
                            hintText: "Example: B2",
                            prefixIcon: Icon(Icons.class_),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Enter section";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "This step creates the mentor profile. "
                                  "The login account and temporary password "
                                  "will be configured through the secure "
                                  "account-provisioning step.",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text("Cancel"),
                ),
                FilledButton.icon(
                  onPressed: isCreating ? null : createProfile,
                  icon: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    isCreating ? "Creating..." : "Create Mentor",
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    employeeIdController.dispose();
    departmentController.dispose();
    yearController.dispose();
    sectionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentors"),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _createMentorProfile,
            tooltip: "Create Mentor",
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMentorProfile,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Create Mentor"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Mentor...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("users")
                  .where("role", isEqualTo: "Mentor")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error loading mentors:\n${snapshot.error}",
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

                final mentors = snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final name =
                      (data["name"] ?? "")
                          .toString()
                          .toLowerCase();

                  final email =
                      (data["email"] ?? "")
                          .toString()
                          .toLowerCase();

                  final department =
                      (data["department"] ?? "")
                          .toString()
                          .toLowerCase();

                  final employeeId =
                      (data["employeeId"] ?? "")
                          .toString()
                          .toLowerCase();

                  return name.contains(search) ||
                      email.contains(search) ||
                      department.contains(search) ||
                      employeeId.contains(search);
                }).toList();

                if (mentors.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Mentors Found",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  itemCount: mentors.length,
                  itemBuilder: (context, index) {
                    final data =
                        mentors[index].data()
                            as Map<String, dynamic>;

                    final name =
                        (data["name"] ?? "No Name")
                            .toString();

                    final email =
                        (data["email"] ?? "N/A")
                            .toString();

                    final department =
                        (data["department"] ?? "N/A")
                            .toString();

                    final employeeId =
                        (data["employeeId"] ?? "N/A")
                            .toString();

                    final accountStatus =
                        (data["accountStatus"] ?? "Unknown")
                            .toString();

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(
                        bottom: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Colors.purple.shade100,
                          child: const Icon(
                            Icons.groups,
                            color: Colors.purple,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Email : $email"),
                              Text(
                                "Employee ID : $employeeId",
                              ),
                              Text(
                                "Department : $department",
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    accountStatus ==
                                            "Profile Created"
                                        ? Icons.info_outline
                                        : Icons.check_circle,
                                    size: 16,
                                    color: accountStatus ==
                                            "Profile Created"
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    accountStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: accountStatus ==
                                              "Profile Created"
                                          ? Colors.orange.shade800
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeanMentorDetailScreen(
                                mentorData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}