import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'leave_status_screen.dart';
import 'leave_request_screen.dart';
import 'qr_scanner_screen.dart';
import 'subjects_screen.dart';
import 'assignment_screen.dart';
import 'attendance_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // ============================================================
  // STUDENT INFORMATION
  // ============================================================

  String? studentId;
  String? studentName;
  String? studentDepartment;
  String? studentYear;
  String? studentSection;

  bool isStudentLoading = true;

  // ============================================================
  // KEEP SCREEN ALIVE
  // ============================================================

  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  // ============================================================
  // LOAD STUDENT DATA
  // ============================================================

  Future<void> loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isStudentLoading = false;
        studentId = null;
        studentName = null;
        studentDepartment = null;
        studentYear = null;
        studentSection = null;
      });

      return;
    }

    try {
      QuerySnapshot<Map<String, dynamic>> userQuery =
          await FirebaseFirestore.instance
              .collection("users")
              .where(
                "email",
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      // ========================================================
      // FALLBACK TO UID
      // ========================================================

      if (userQuery.docs.isEmpty) {
        userQuery = await FirebaseFirestore.instance
            .collection("users")
            .where(
              "uid",
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();
      }

      // ========================================================
      // PROFILE NOT FOUND
      // ========================================================

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          isStudentLoading = false;
          studentId = null;
          studentName = null;
          studentDepartment = null;
          studentYear = null;
          studentSection = null;
        });

        return;
      }

      final data = userQuery.docs.first.data();

      // ========================================================
      // REGISTER NUMBER
      //
      // We use registerNo as the student-facing identifier.
      // Roll No is not used.
      // ========================================================

      final String registerNo =
          data["registerNo"]
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? data["registerNo"]
                  .toString()
                  .trim()
              : data["studentId"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? data["studentId"]
                      .toString()
                      .trim()
                  : "";

      // ========================================================
      // REAL STUDENT NAME
      // ========================================================

      final String name =
          data["name"]
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? data["name"]
                  .toString()
                  .trim()
              : user.displayName
                          ?.trim()
                          .isNotEmpty ==
                      true
                  ? user.displayName!.trim()
                  : "Student";

      // ========================================================
      // OTHER DETAILS
      // ========================================================

      final String department =
          data["department"]
                  ?.toString()
                  .trim() ??
              "";

      final String year =
          data["year"]
                  ?.toString()
                  .trim() ??
              "";

      final String section =
          data["section"]
                  ?.toString()
                  .trim() ??
              "";

      if (!mounted) return;

      setState(() {
        studentId = registerNo;
        studentName = name;
        studentDepartment = department;
        studentYear = year;
        studentSection = section;
        isStudentLoading = false;
      });

      debugPrint("================================");
      debugPrint("STUDENT INFORMATION");
      debugPrint("Student Name: $studentName");
      debugPrint("Register No: $studentId");
      debugPrint("Department: $studentDepartment");
      debugPrint("Year: $studentYear");
      debugPrint("Section: $studentSection");
      debugPrint("================================");
    } catch (e) {
      debugPrint(
        "Error loading student information: $e",
      );

      if (!mounted) return;

      setState(() {
        isStudentLoading = false;
        studentId = null;
        studentName = null;
        studentDepartment = null;
        studentYear = null;
        studentSection = null;
      });
    }
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget buildAttendanceCard() {
    if (isStudentLoading) {
      return const Card(
        elevation: 3,
        child: ListTile(
          leading: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          title: Text(
            "Attendance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Loading attendance...",
          ),
        ),
      );
    }

    if (studentId == null || studentId!.isEmpty) {
      return const Card(
        elevation: 3,
        child: ListTile(
          leading: Icon(
            Icons.error,
            color: Colors.red,
            size: 32,
          ),
          title: Text(
            "Attendance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Student profile not found",
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("attendance")
          .where(
            "studentId",
            isEqualTo: studentId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(
                Icons.error,
                color: Colors.red,
                size: 32,
              ),
              title: const Text(
                "Attendance",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Unable to load attendance\n"
                "${snapshot.error}",
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            elevation: 3,
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              title: Text(
                "Attendance",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Loading attendance...",
              ),
            ),
          );
        }

        final records =
            snapshot.data?.docs ?? [];

        int present = 0;
        final int total = records.length;

        for (final doc in records) {
          final data =
              doc.data() as Map<String, dynamic>;

          final String status =
              data["status"]
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  "";

          if (status == "present") {
            present++;
          }
        }

        double percentage = 0;

        if (total > 0) {
          percentage =
              (present / total) * 100;
        }

        final String attendance =
            "${percentage.toStringAsFixed(0)}%";

        Color attendanceColor = Colors.green;

        if (percentage < 75) {
          attendanceColor = Colors.red;
        } else if (percentage < 90) {
          attendanceColor = Colors.orange;
        }

        return Card(
          elevation: 3,
          child: ListTile(
            leading: Icon(
              Icons.check_circle,
              color: attendanceColor,
              size: 32,
            ),
            title: const Text(
              "Attendance",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "$attendance\n"
              "$present Present / $total Classes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: attendanceColor,
              ),
            ),
            isThreeLine: true,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AttendanceDashboardScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SUBJECT COUNT
  // ============================================================

  Widget buildSubjectCount() {
    if (isStudentLoading) {
      return const Text(
        "Loading subjects...",
      );
    }

    if (studentDepartment == null ||
        studentYear == null ||
        studentSection == null) {
      return const Text(
        "Subjects unavailable",
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("subjects")
          .where(
            "department",
            isEqualTo: studentDepartment,
          )
          .where(
            "year",
            isEqualTo: studentYear,
          )
          .where(
            "section",
            isEqualTo: studentSection,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Text(
            "Loading subjects...",
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "Unable to load subjects",
          );
        }

        final int subjectCount =
            snapshot.data?.docs.length ?? 0;

        return Text(
          "$subjectCount Subject"
          "${subjectCount == 1 ? "" : "s"}",
        );
      },
    );
  }

  // ============================================================
  // ANNOUNCEMENT CARD
  // ============================================================

  Widget buildAnnouncementCard(
    QueryDocumentSnapshot announcement,
    double announcementTitleSize,
  ) {
    final data =
        announcement.data()
            as Map<String, dynamic>;

    final bool isPinned =
        data["isPinned"] == true;

    final String title =
        data["title"]?.toString() ?? "";

    final String message =
        data["message"]?.toString() ?? "";

    Timestamp? timestamp;

    if (data["createdAt"] is Timestamp) {
      timestamp =
          data["createdAt"] as Timestamp;
    }

    String formattedDate =
        "Date unavailable";

    if (timestamp != null) {
      formattedDate = DateFormat(
        "dd MMM yyyy • hh:mm a",
      ).format(
        timestamp.toDate(),
      );
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      elevation: isPinned ? 8 : 5,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
        side: isPinned
            ? const BorderSide(
                color: Colors.orange,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  isPinned
                      ? Icons.push_pin
                      : Icons.campaign,
                  color: isPinned
                      ? Colors.orange
                      : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPinned
                        ? "📌 $title"
                        : title,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:
                          announcementTitleSize,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color: isPinned
                          ? Colors.orange
                          : Colors.red,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      isPinned
                          ? "PINNED"
                          : "NEW",
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formattedDate,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double screenWidth =
        MediaQuery.sizeOf(context).width;

    final double horizontalPadding =
        screenWidth < 360
            ? 12
            : screenWidth < 600
                ? 16
                : 20;

    final double welcomePadding =
        screenWidth < 360 ? 16 : 20;

    final double welcomeTitleSize =
        screenWidth < 360 ? 26 : 30;

    final double announcementTitleSize =
        screenWidth < 360 ? 17 : 18;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        20,
        horizontalPadding,
        30,
      ),
      children: [
        // ======================================================
        // WELCOME CARD
        // ======================================================

        Container(
          padding:
              EdgeInsets.all(welcomePadding),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome 👋",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isStudentLoading
                    ? "Loading..."
                    : (studentName != null &&
                            studentName!
                                .trim()
                                .isNotEmpty
                        ? studentName!
                        : "Student"),
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      welcomeTitleSize,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Have a productive day!",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ======================================================
        // ATTENDANCE
        // ======================================================

        buildAttendanceCard(),

        const SizedBox(height: 5),

        // ======================================================
        // LEAVE STATUS
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.assignment_turned_in,
              color: Colors.deepPurple,
            ),
            title: const Text(
              "Leave Status",
            ),
            subtitle: const Text(
              "Check your leave requests",
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
                      const LeaveStatusScreen(),
                ),
              );
            },
          ),
        ),

        // ======================================================
        // SUBJECTS
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.menu_book,
              color: Colors.orange,
            ),
            title: const Text(
              "My Subjects",
            ),
            subtitle:
                buildSubjectCount(),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SubjectsScreen(),
                ),
              );
            },
          ),
        ),

        // ======================================================
        // ASSIGNMENTS
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.assignment,
              color: Colors.indigo,
            ),
            title: const Text(
              "Assignments",
            ),
            subtitle: const Text(
              "View and submit assignments",
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
                      const AssignmentScreen(),
                ),
              );
            },
          ),
        ),

        // ======================================================
        // LEAVE REQUEST
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.event_available,
              color: Colors.purple,
            ),
            title: const Text(
              "Leave Request",
            ),
            subtitle: const Text(
              "Apply for leave",
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
                      const LeaveRequestScreen(),
                ),
              );
            },
          ),
        ),

        // ======================================================
        // QR ATTENDANCE
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.qr_code_scanner,
              color: Colors.blue,
            ),
            title: const Text(
              "Scan QR Attendance",
            ),
            subtitle: const Text(
              "Scan teacher's QR code",
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
                      const QRScannerScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 25),

        // ======================================================
        // CAMPUS ANNOUNCEMENTS
        // ======================================================

        Text(
          "📢 Campus Announcements",
          style: TextStyle(
            fontSize:
                screenWidth < 360 ? 20 : 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("announcements")
              .where(
                "expiryAt",
                isGreaterThan:
                    Timestamp.now(),
              )
              .orderBy("expiryAt")
              .orderBy(
                "isPinned",
                descending: true,
              )
              .orderBy(
                "createdAt",
                descending: true,
              )
              .snapshots(),

          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Text(
                    snapshot.error.toString(),
                    style:
                        const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child:
                      CircularProgressIndicator(),
                ),
              );
            }

            final announcements =
                snapshot.data?.docs ?? [];

            if (announcements.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_off,
                  ),
                  title: Text(
                    "No Announcements",
                  ),
                  subtitle: Text(
                    "Nothing to display",
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  announcements.length,
              itemBuilder:
                  (context, index) {
                return buildAnnouncementCard(
                  announcements[index],
                  announcementTitleSize,
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}