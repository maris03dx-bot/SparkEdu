import 'package:flutter/material.dart';

import '../../utils/logout_helper.dart';
import '../../utils/student_profile_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: StudentProfileHelper.getProfile(),
      builder: (context, snapshot) {
        // ======================================================
        // LOADING
        // ======================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ======================================================
        // ERROR
        // ======================================================

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Error loading profile:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // ======================================================
        // PROFILE NOT FOUND
        // ======================================================

        if (!snapshot.hasData ||
            snapshot.data == null) {
          return const Center(
            child: Text(
              "Student profile not found.",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        // ======================================================
        // STUDENT DETAILS
        // ======================================================

        final String name =
            data["name"]?.toString().trim().isNotEmpty == true
                ? data["name"].toString().trim()
                : "Student";

        final String department =
            data["department"]?.toString().trim().isNotEmpty == true
                ? data["department"].toString().trim()
                : "Not available";

        final String registerNo =
            data["registerNo"]?.toString().trim().isNotEmpty == true
                ? data["registerNo"].toString().trim()
                : "Not available";

        final String year =
            data["year"]?.toString().trim().isNotEmpty == true
                ? data["year"].toString().trim()
                : "Not available";

        final String section =
            data["section"]?.toString().trim().isNotEmpty == true
                ? data["section"].toString().trim()
                : "Not available";

        final String email =
            data["email"]?.toString().trim().isNotEmpty == true
                ? data["email"].toString().trim()
                : "Not available";

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ==================================================
            // PROFILE ICON
            // ==================================================

            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // STUDENT NAME
            // ==================================================

            Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // DEPARTMENT
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.school,
                  color: Colors.blue,
                ),
                title: const Text(
                  "Department",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(department),
              ),
            ),

            // ==================================================
            // REGISTER NUMBER
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.badge,
                  color: Colors.orange,
                ),
                title: const Text(
                  "Register Number",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(registerNo),
              ),
            ),

            // ==================================================
            // YEAR
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.green,
                ),
                title: const Text(
                  "Year",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(year),
              ),
            ),

            // ==================================================
            // SECTION
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.groups,
                  color: Colors.purple,
                ),
                title: const Text(
                  "Section",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(section),
              ),
            ),

            // ==================================================
            // EMAIL
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.red,
                ),
                title: const Text(
                  "Email",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(email),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // LOGOUT
            // ==================================================

            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {
                  LogoutHelper.showLogoutDialog(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}