import 'package:flutter/material.dart';

import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';
import 'anonymous_subject_screen.dart';
import 'announcements_screen.dart';

class CommunicationHome extends StatelessWidget {
  const CommunicationHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),

      // =========================================================
      // NO APP BAR HERE
      //
      // StudentNavigation already provides the main AppBar.
      // Keeping another AppBar here causes:
      //
      // Communication
      // Communication
      //
      // =========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          20,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6B4FD3),
                    Color(0xFF8A63D8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 42,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Stay Connected",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "Connect with teachers and classmates through SparkEdu.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // =====================================================
            // SECTION TITLE
            // =====================================================

            const Text(
              "Communication",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17152B),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Choose how you want to communicate.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            // =====================================================
            // DIRECT CHAT
            // =====================================================

            buildCommunicationCard(
              context: context,
              icon: Icons.chat_bubble_rounded,
              iconColor: const Color(0xFF6B4FD3),
              title: "Direct Chat",
              subtitle:
                  "Chat privately with your subject teacher",
              screen: const DirectChatScreen(),
            ),

            // =====================================================
            // SUBJECT GROUP CHAT
            // =====================================================

            buildCommunicationCard(
              context: context,
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF2196F3),
              title: "Subject Group Chat",
              subtitle:
                  "Discuss subjects with your classmates",
              screen: const GroupChatScreen(),
            ),

            // =====================================================
            // ANONYMOUS DOUBTS
            // =====================================================

            buildCommunicationCard(
              context: context,
              icon: Icons.visibility_off_rounded,
              iconColor: const Color(0xFFE91E63),
              title: "Anonymous Doubts",
              subtitle:
                  "Ask questions anonymously by subject",
              screen: const AnonymousSubjectScreen(),
            ),

            // =====================================================
            // ANNOUNCEMENTS
            // =====================================================

            buildCommunicationCard(
              context: context,
              icon: Icons.campaign_rounded,
              iconColor: const Color(0xFFFF9800),
              title: "Announcements",
              subtitle:
                  "View important teacher announcements",
              screen: const AnnouncementsScreen(),
            ),

            const SizedBox(height: 15),

            // =====================================================
            // ANONYMOUS CHAT INFORMATION
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FA),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(
                  color: const Color(0xFFD8CEF3),
                ),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Color(0xFF6B4FD3),
                    size: 25,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      "In Anonymous Doubts, other students see only an anonymous sender. Subject teachers can see the student's name and register number.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A4263),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // COMMUNICATION CARD
  // =============================================================

  Widget buildCommunicationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => screen,
              ),
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                // =================================================
                // ICON
                // =================================================

                Container(
                  width: 55,
                  height: 55,

                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                // =================================================
                // TEXT
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17152B),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // ARROW
                // =================================================

                Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EEF8),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: Color(0xFF6B4FD3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}