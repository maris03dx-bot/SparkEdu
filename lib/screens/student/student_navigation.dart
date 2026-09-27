import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import '../communication/communication_home.dart';
import '../../ai/spark_ai_screen.dart';
import '../../utils/logout_helper.dart';

class StudentNavigation extends StatefulWidget {
  const StudentNavigation({super.key});

  @override
  State<StudentNavigation> createState() => _StudentNavigationState();
}

class _StudentNavigationState extends State<StudentNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    CommunicationHome(),
    EventsScreen(),
    SparkAIScreen(),
    ProfileScreen(),
  ];

  final List<String> titles = [
    "Home",
    "Communication",
    "Events",
    "SparkAI",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        // LOGOUT BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              LogoutHelper.showLogoutDialog(context);
            },
          ),
        ],
      ),

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Events",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "SparkAI",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}