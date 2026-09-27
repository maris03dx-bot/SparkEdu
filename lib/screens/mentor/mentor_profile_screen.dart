import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MentorProfileScreen extends StatelessWidget {
  const MentorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: const Color(0xFF6B4FD3),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Unable to load mentor profile.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4FD3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(
              'uid',
              isEqualTo: currentUser.uid,
            )
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile information.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Mentor profile was not found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final Map<String, dynamic> data =
              snapshot.data!.docs.first.data();

          final String name =
              _value(data['name'], 'Mentor');

          final String email =
              _value(data['email'], currentUser.email ?? '-');

          final String role =
              _value(data['role'], 'Mentor');

          final String employeeId =
              _value(data['employeeId'], '-');

          final String department =
              _value(data['department'], '-');

          final String year =
              _value(data['year'], '-');

          final String section =
              _value(data['section'], '-');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfileHeader(
                  name: name,
                  department: department,
                  role: role,
                ),

                const SizedBox(height: 20),

                _ProfileSection(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.person_outline,
                      title: 'Name',
                      value: name,
                    ),
                    _ProfileInfoTile(
                      icon: Icons.badge_outlined,
                      title: 'Employee ID',
                      value: employeeId,
                    ),
                    _ProfileInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: email,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'Academic Information',
                  icon: Icons.school_outlined,
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.business_outlined,
                      title: 'Department',
                      value: department,
                    ),
                    _ProfileInfoTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Year',
                      value: year,
                    ),
                    _ProfileInfoTile(
                      icon: Icons.groups_outlined,
                      title: 'Section',
                      value: section,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'Account Information',
                  icon: Icons.security_outlined,
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Role',
                      value: role,
                    ),
                    _ProfileInfoTile(
                      icon: Icons.lock_outline,
                      title: 'Account',
                      value: 'Active',
                      valueColor: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Card(
                  color: const Color(0xFFF1EDFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF6B4FD3),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your mentor profile information is managed through your SparkEdu account.',
                            style: TextStyle(
                              color: Color(0xFF55505F),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _value(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String department;
  final String role;

  const _ProfileHeader({
    required this.name,
    required this.department,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(
                Icons.person,
                size: 54,
                color: Color(0xFF6B4FD3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: const TextStyle(
                color: Color(0xFF6B4FD3),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (department != '-') ...[
              const SizedBox(height: 5),
              Text(
                department,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF6B4FD3),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: Icon(
        icon,
        color: Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}