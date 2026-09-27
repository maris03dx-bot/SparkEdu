import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class MentorTeachersScreen extends StatefulWidget {
  const MentorTeachersScreen({super.key});

  @override
  State<MentorTeachersScreen> createState() => _MentorTeachersScreenState();
}

class _MentorTeachersScreenState extends State<MentorTeachersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> teachersStream;

  String? mentorUid;
  String mentorName = '';
  bool isLoadingMentor = true;

  @override
  void initState() {
    super.initState();

    teachersStream = firestore
        .collection('users')
        .where('role', isEqualTo: 'Subject Teacher')
        .snapshots();

    loadMentorProfile();
  }

  Future<void> loadMentorProfile() async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        if (mounted) {
          setState(() {
            isLoadingMentor = false;
          });
        }
        return;
      }

      final snapshot = await firestore
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .where('role', isEqualTo: 'Mentor')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        if (!mounted) return;

        setState(() {
          mentorUid = currentUser.uid;
          mentorName = (data['name'] ?? '').toString();
          isLoadingMentor = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          mentorUid = currentUser.uid;
          mentorName = currentUser.displayName ?? 'Mentor';
          isLoadingMentor = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mentor profile: $e');

      if (!mounted) return;

      setState(() {
        isLoadingMentor = false;
      });
    }
  }

  Future<String?> createTeacherAccount({
    required String name,
    required String employeeId,
    required String email,
    required String phone,
    required String department,
    required String designation,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedEmployeeId = employeeId.trim();

    // Check duplicate email in Firestore.
    final emailSnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (emailSnapshot.docs.isNotEmpty) {
      return 'A user with this email already exists.';
    }

    // Check duplicate employee ID.
    final employeeSnapshot = await firestore
        .collection('users')
        .where('employeeId', isEqualTo: normalizedEmployeeId)
        .limit(1)
        .get();

    if (employeeSnapshot.docs.isNotEmpty) {
      return 'This employee ID is already registered.';
    }

    late final FirebaseApp secondaryApp;

    try {
      /*
       * Create a second Firebase app so the Mentor's current
       * Firebase Authentication session is not signed out.
       */
      secondaryApp = await Firebase.initializeApp(
        name: 'teacherCreationApp',
        options: Firebase.app().options,
      );

      final FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential? credential;

      try {
        credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        final User? teacherUser = credential.user;

        if (teacherUser == null) {
          return 'Firebase Authentication did not create the teacher account.';
        }

        final String realTeacherUid = teacherUser.uid;

        /*
         * IMPORTANT:
         *
         * Firestore document ID = Firebase Authentication UID
         *
         * This keeps users/{uid} and Firebase Auth synchronized.
         */
        await firestore.collection('users').doc(realTeacherUid).set({
          'uid': realTeacherUid,
          'name': name.trim(),
          'employeeId': normalizedEmployeeId,
          'email': normalizedEmail,
          'phone': phone.trim(),
          'department': department.trim(),
          'designation': designation.trim(),
          'role': 'Subject Teacher',

          'accountStatus': 'Active',
          'passwordStatus': 'Temporary',
          'mustChangePassword': true,

          'createdByMentorUid': mentorUid,
          'createdByMentorName': mentorName,

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return null;
      } catch (e) {
        /*
         * If Auth account was created but Firestore failed,
         * remove the newly created Auth account so we don't
         * leave an orphan account.
         */
        if (credential?.user != null) {
          try {
            await credential!.user!.delete();
          } catch (deleteError) {
            debugPrint(
              'Could not remove partially created Auth account: $deleteError',
            );
          }
        }

        rethrow;
      } finally {
        try {
          await secondaryAuth.signOut();
        } catch (e) {
          debugPrint('Secondary Auth sign-out error: $e');
        }

        try {
          await secondaryApp.delete();
        } catch (e) {
          debugPrint('Secondary Firebase app delete error: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered in Firebase Authentication.';

        case 'invalid-email':
          return 'The email address is invalid.';

        case 'weak-password':
          return 'The password is too weak. Use at least 6 characters.';

        case 'operation-not-allowed':
          return 'Email/password authentication is not enabled in Firebase.';

        default:
          return e.message ?? 'Firebase Authentication error occurred.';
      }
    } catch (e) {
      debugPrint('Teacher creation error: $e');

      return 'Unable to create teacher account. Please try again.';
    }
  }

  Future<void> showCreateTeacherDialog() async {
    final pageContext = context;

    final nameController = TextEditingController();
    final employeeIdController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final departmentController = TextEditingController();
    final designationController = TextEditingController();
    final passwordController = TextEditingController();

    bool isSaving = false;
    bool obscurePassword = true;

    try {
      await showDialog<void>(
        context: pageContext,
        barrierDismissible: !isSaving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Create Subject Teacher'),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Teacher Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: employeeIdController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: departmentController,
                          textCapitalization: TextCapitalization.characters,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            hintText: 'Example: CSE',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: designationController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Designation',
                            hintText: 'Example: Assistant Professor',
                            prefixIcon: Icon(Icons.work_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: 'Initial Password',
                            hintText: 'Minimum 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'The teacher should change this password after first login.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final employeeId =
                                employeeIdController.text.trim();
                            final email = emailController.text.trim();
                            final phone = phoneController.text.trim();
                            final department =
                                departmentController.text.trim();
                            final designation =
                                designationController.text.trim();
                            final password = passwordController.text;

                            if (name.isEmpty ||
                                employeeId.isEmpty ||
                                email.isEmpty ||
                                phone.isEmpty ||
                                department.isEmpty ||
                                designation.isEmpty ||
                                password.isEmpty) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all teacher details.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (password.length < 6) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password must contain at least 6 characters.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            final String? error = await createTeacherAccount(
                              name: name,
                              employeeId: employeeId,
                              email: email,
                              phone: phone,
                              department: department,
                              designation: designation,
                              password: password,
                            );

                            if (!dialogContext.mounted) {
  return;
}

if (error != null) {
  setDialogState(() {
    isSaving = false;
  });

  if (!pageContext.mounted) {
    return;
  }

  ScaffoldMessenger.of(pageContext).showSnackBar(
    SnackBar(
      content: Text(error),
      backgroundColor: Colors.red,
    ),
  );

  return;
}

// Success: close the dialog directly.
// There is no need to rebuild it before closing.
Navigator.of(dialogContext).pop();

if (!pageContext.mounted) {
  return;
}

ScaffoldMessenger.of(pageContext).showSnackBar(
  const SnackBar(
    content: Text(
      'Subject Teacher account created successfully.',
    ),
    backgroundColor: Colors.green,
  ),
);
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(
                      isSaving ? 'Creating...' : 'Create Teacher',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      employeeIdController.dispose();
      emailController.dispose();
      phoneController.dispose();
      departmentController.dispose();
      designationController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> deleteTeacherProfile(
    QueryDocumentSnapshot<Map<String, dynamic>> teacherDoc,
  ) async {
    final data = teacherDoc.data();

    final teacherName = (data['name'] ?? 'Subject Teacher').toString();
    final teacherUid = (data['uid'] ?? teacherDoc.id).toString();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Teacher Profile?'),
          content: Text(
            'This will permanently delete the Firestore profile for '
            '$teacherName.\n\n'
            'The Firebase Authentication account will remain because '
            'another user cannot securely delete an Auth account from '
            'the Flutter client.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete Profile'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      /*
       * Prevent deleting a teacher who is still connected to a subject.
       * This avoids leaving subjects pointing to a missing teacher UID.
       */
      final subjectSnapshot = await firestore
          .collection('subjects')
          .where('teacherUid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      if (!mounted) {
        return;
      }

      if (subjectSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$teacherName is still assigned to a subject. '
              'Remove or reassign the subject first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await firestore.collection('users').doc(teacherDoc.id).delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$teacherName profile deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting teacher profile: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete teacher profile.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildTeacherCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final String name = (data['name'] ?? 'Unnamed Teacher').toString();
    final String employeeId =
        (data['employeeId'] ?? 'Not available').toString();
    final String email = (data['email'] ?? 'Not available').toString();
    final String phone = (data['phone'] ?? 'Not available').toString();
    final String department =
        (data['department'] ?? 'Not available').toString();
    final String designation =
        (data['designation'] ?? 'Subject Teacher').toString();
    final String status = (data['accountStatus'] ?? 'Active').toString();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        designation,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Teacher actions',
                  onSelected: (value) {
                    if (value == 'delete') {
                      deleteTeacherProfile(document);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Delete Profile'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _teacherInfoRow(
              Icons.badge_outlined,
              'Employee ID',
              employeeId,
            ),
            _teacherInfoRow(
              Icons.account_tree_outlined,
              'Department',
              department,
            ),
            _teacherInfoRow(
              Icons.email_outlined,
              'Email',
              email,
            ),
            _teacherInfoRow(
              Icons.phone_outlined,
              'Phone',
              phone,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teacherInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Teachers'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoadingMentor ? null : showCreateTeacherDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Teacher'),
      ),
      body: isLoadingMentor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: const Icon(Icons.school_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mentor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mentorName.isEmpty ? 'Mentor' : mentorName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: teachersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError && !snapshot.hasData) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Unable to load subject teachers.\n\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final teachers = [
                        ...snapshot.data!.docs,
                      ];

                      teachers.sort((a, b) {
                        final nameA =
                            (a.data()['name'] ?? '').toString().toLowerCase();
                        final nameB =
                            (b.data()['name'] ?? '').toString().toLowerCase();

                        return nameA.compareTo(nameB);
                      });

                      if (teachers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No Subject Teachers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tap "Add Teacher" to create the first subject teacher account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.groups_outlined),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Total Subject Teachers',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  teachers.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                100,
                              ),
                              itemCount: teachers.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                return buildTeacherCard(teachers[index]);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}