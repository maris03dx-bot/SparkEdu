import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentPerformanceScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentPerformanceScreen({
    super.key,
    required this.studentData,
  });

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _studentIdentifier() {
    final studentId = _stringValue(studentData['studentId']);

    if (studentId.isNotEmpty) {
      return studentId;
    }

    final registerNo = _stringValue(studentData['registerNo']);

    if (registerNo.isNotEmpty) {
      return registerNo;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String studentId = _studentIdentifier();

    final String name = _stringValue(studentData['name']);
    final String department = _stringValue(studentData['department']);
    final String year = _stringValue(studentData['year']);
    final String section = _stringValue(studentData['section']);
    final String registerNo = _stringValue(studentData['registerNo']);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Student Performance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4FD3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: studentId.isEmpty
          ? const Center(
              child: Text(
                'Student information is incomplete.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where(
                    'studentId',
                    isEqualTo: studentId,
                  )
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('leave_requests')
                      .where(
                        'studentId',
                        isEqualTo: studentId,
                      )
                      .snapshots(),
                  builder: (context, leaveSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('assignments')
                          .snapshots(),
                      builder: (context, assignmentSnapshot) {
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('subjects')
                              .snapshots(),
                          builder: (context, subjectSnapshot) {
                            if (attendanceSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                leaveSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                assignmentSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                subjectSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final attendanceDocs =
                                attendanceSnapshot.data?.docs ?? [];

                            final leaveDocs =
                                leaveSnapshot.data?.docs ?? [];

                            final assignmentDocs =
                                assignmentSnapshot.data?.docs ?? [];

                            final subjectDocs =
                                subjectSnapshot.data?.docs ?? [];

                            final attendanceStats =
                                _calculateAttendance(attendanceDocs);

                            final int present =
                                attendanceStats['present'] ?? 0;

                            final int absent =
                                attendanceStats['absent'] ?? 0;

                            final int leave =
                                attendanceStats['leave'] ?? 0;

                            final int totalAttendanceDays =
                                attendanceStats['total'] ?? 0;

                            final double attendancePercentage =
                                totalAttendanceDays == 0
                                    ? 0
                                    : (present /
                                            totalAttendanceDays) *
                                        100;

                            final int assignmentCount =
                                _filterAssignments(
                              assignmentDocs,
                              studentId,
                              registerNo,
                              department,
                              year,
                              section,
                            ).length;

                            final int subjectCount =
                                _filterSubjects(
                              subjectDocs,
                              department,
                              year,
                              section,
                            ).length;

                            final bool hasPerformanceData =
                                totalAttendanceDays > 0 ||
                                    assignmentCount > 0 ||
                                    leaveDocs.isNotEmpty;

                            if (!hasPerformanceData) {
                              return _NoPerformanceDataView(
                                name: name,
                                department: department,
                                year: year,
                                section: section,
                                registerNo: registerNo,
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                await Future.delayed(
                                  const Duration(
                                    milliseconds: 500,
                                  ),
                                );
                              },
                              child: SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _StudentHeader(
                                      name: name,
                                      department: department,
                                      year: year,
                                      section: section,
                                      registerNo: registerNo,
                                    ),

                                    const SizedBox(height: 20),

                                    const Text(
                                      'Performance Overview',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _AttendancePerformanceCard(
                                      percentage:
                                          attendancePercentage,
                                      present: present,
                                      absent: absent,
                                      leave: leave,
                                      total:
                                          totalAttendanceDays,
                                    ),

                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PerformanceCard(
                                            title: 'Assignments',
                                            value:
                                                assignmentCount
                                                    .toString(),
                                            subtitle:
                                                'Available records',
                                            icon: Icons
                                                .assignment_outlined,
                                            color:
                                                Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _PerformanceCard(
                                            title: 'Leaves',
                                            value:
                                                leaveDocs.length
                                                    .toString(),
                                            subtitle:
                                                'Leave requests',
                                            icon: Icons
                                                .event_available,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PerformanceCard(
                                            title: 'Subjects',
                                            value:
                                                subjectCount
                                                    .toString(),
                                            subtitle:
                                                'Current class',
                                            icon: Icons
                                                .menu_book_outlined,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _PerformanceCard(
                                            title:
                                                'Attendance Days',
                                            value:
                                                totalAttendanceDays
                                                    .toString(),
                                            subtitle:
                                                'Recorded classes',
                                            icon: Icons
                                                .calendar_month,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Attendance Breakdown',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _AttendanceBreakdown(
                                      present: present,
                                      absent: absent,
                                      leave: leave,
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Academic Summary',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _AcademicSummary(
                                      attendancePercentage:
                                          attendancePercentage,
                                      assignmentCount:
                                          assignmentCount,
                                      subjectCount:
                                          subjectCount,
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Mentor Remarks',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _MentorRemarks(
                                      attendancePercentage:
                                          attendancePercentage,
                                      assignmentCount:
                                          assignmentCount,
                                    ),

                                    const SizedBox(height: 24),

                                    const _InfoCard(
                                      icon:
                                          Icons.info_outline,
                                      title:
                                          'Performance tracking',
                                      message:
                                          'This dashboard is based on the student records currently available in SparkEdu.',
                                    ),

                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Map<String, int> _calculateAttendance(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int present = 0;
    int absent = 0;
    int leave = 0;

    for (final doc in docs) {
      final data = doc.data();

      final String status =
          _stringValue(data['status']).toLowerCase();

      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else if (status == 'leave' ||
          status == 'on leave') {
        leave++;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'leave': leave,
      'total': present + absent + leave,
    };
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterAssignments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String studentId,
    String registerNo,
    String department,
    String year,
    String section,
  ) {
    return docs.where((doc) {
      final data = doc.data();

      final String assignmentStudentId =
          _stringValue(data['studentId']);

      final String assignmentRegisterNo =
          _stringValue(data['registerNo']);

      final String assignmentDepartment =
          _stringValue(data['department']);

      final String assignmentYear =
          _stringValue(data['year']);

      final String assignmentSection =
          _stringValue(data['section']);

      final bool studentMatch =
          (assignmentStudentId.isNotEmpty &&
              assignmentStudentId == studentId) ||
          (assignmentRegisterNo.isNotEmpty &&
              assignmentRegisterNo == registerNo);

      final bool classMatch =
          assignmentDepartment.isNotEmpty &&
              assignmentYear.isNotEmpty &&
              assignmentSection.isNotEmpty &&
              assignmentDepartment == department &&
              assignmentYear == year &&
              assignmentSection == section;

      return studentMatch || classMatch;
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterSubjects(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String department,
    String year,
    String section,
  ) {
    return docs.where((doc) {
      final data = doc.data();

      final String subjectDepartment =
          _stringValue(data['department']);

      final String subjectYear =
          _stringValue(data['year']);

      final String subjectSection =
          _stringValue(data['section']);

      final bool departmentMatch =
          subjectDepartment.isEmpty ||
              subjectDepartment == department;

      final bool yearMatch =
          subjectYear.isEmpty ||
              subjectYear == year;

      final bool sectionMatch =
          subjectSection.isEmpty ||
              subjectSection == section;

      return departmentMatch &&
          yearMatch &&
          sectionMatch;
    }).toList();
  }
}

class _NoPerformanceDataView extends StatelessWidget {
  final String name;
  final String department;
  final String year;
  final String section;
  final String registerNo;

  const _NoPerformanceDataView({
    required this.name,
    required this.department,
    required this.year,
    required this.section,
    required this.registerNo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StudentHeader(
            name: name,
            department: department,
            year: year,
            section: section,
            registerNo: registerNo,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EDFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Color(0xFF6B4FD3),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'No Performance Data Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name.isEmpty
                        ? 'This student is newly added to SparkEdu.'
                        : '$name is newly added to SparkEdu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Performance insights will appear after attendance, assignments, leave requests, or other academic activity are recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7FC),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        _NoDataItem(
                          icon: Icons.fact_check_outlined,
                          text: 'Attendance data will appear here',
                        ),
                        SizedBox(height: 12),
                        _NoDataItem(
                          icon: Icons.assignment_outlined,
                          text: 'Assignment activity will appear here',
                        ),
                        SizedBox(height: 12),
                        _NoDataItem(
                          icon: Icons.event_available,
                          text: 'Leave activity will appear here',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _InfoCard(
            icon: Icons.info_outline,
            title: 'New student profile',
            message:
                'No performance judgement is made until sufficient academic activity is available.',
          ),
        ],
      ),
    );
  }
}

class _NoDataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NoDataItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF6B4FD3),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentHeader extends StatelessWidget {
  final String name;
  final String department;
  final String year;
  final String section;
  final String registerNo;

  const _StudentHeader({
    required this.name,
    required this.department,
    required this.year,
    required this.section,
    required this.registerNo,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> classDetails = [
      if (department.isNotEmpty) department,
      if (year.isNotEmpty) '$year Year',
      if (section.isNotEmpty) 'Section $section',
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF6B4FD3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Student' : name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (classDetails.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      classDetails.join(' • '),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (registerNo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EDFF),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Register No: $registerNo',
                        style: const TextStyle(
                          color: Color(0xFF6B4FD3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendancePerformanceCard
    extends StatelessWidget {
  final double percentage;
  final int present;
  final int absent;
  final int leave;
  final int total;

  const _AttendancePerformanceCard({
    required this.percentage,
    required this.present,
    required this.absent,
    required this.leave,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage <= 0
                    ? 0
                    : percentage >= 100
                        ? 1
                        : percentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AttendanceMiniStat(
                    label: 'Present',
                    value: present,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _AttendanceMiniStat(
                    label: 'Absent',
                    value: absent,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _AttendanceMiniStat(
                    label: 'Leave',
                    value: leave,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _AttendanceMiniStat(
                    label: 'Total',
                    value: total,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceMiniStat
    extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PerformanceCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBreakdown
    extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;

  const _AttendanceBreakdown({
    required this.present,
    required this.absent,
    required this.leave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _BreakdownRow(
              label: 'Present',
              value: present,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const Divider(height: 24),
            _BreakdownRow(
              label: 'Absent',
              value: absent,
              icon: Icons.cancel,
              color: Colors.red,
            ),
            const Divider(height: 24),
            _BreakdownRow(
              label: 'Leave',
              value: leave,
              icon: Icons.event_available,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AcademicSummary extends StatelessWidget {
  final double attendancePercentage;
  final int assignmentCount;
  final int subjectCount;

  const _AcademicSummary({
    required this.attendancePercentage,
    required this.assignmentCount,
    required this.subjectCount,
  });

  @override
  Widget build(BuildContext context) {
    final String attendanceMessage =
        attendancePercentage >= 85
            ? 'Attendance is in a healthy range.'
            : attendancePercentage >= 75
                ? 'Attendance should be monitored regularly.'
                : 'Attendance requires mentor attention.';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _SummaryRow(
              icon: Icons.fact_check_outlined,
              title: 'Attendance',
              message: attendanceMessage,
            ),
            const Divider(height: 26),
            _SummaryRow(
              icon: Icons.assignment_outlined,
              title: 'Assignments',
              message:
                  '$assignmentCount assignment record${assignmentCount == 1 ? '' : 's'} found.',
            ),
            const Divider(height: 26),
            _SummaryRow(
              icon: Icons.menu_book_outlined,
              title: 'Subjects',
              message:
                  '$subjectCount subject${subjectCount == 1 ? '' : 's'} linked to the class.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF6B4FD3),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MentorRemarks extends StatelessWidget {
  final double attendancePercentage;
  final int assignmentCount;

  const _MentorRemarks({
    required this.attendancePercentage,
    required this.assignmentCount,
  });

  @override
  Widget build(BuildContext context) {
    String remark;

    if (attendancePercentage < 75 &&
        attendancePercentage > 0) {
      remark =
          'Attendance is below the expected level. Mentor follow-up is recommended.';
    } else if (attendancePercentage < 85 &&
        attendancePercentage > 0) {
      remark =
          'Attendance is acceptable but should be monitored regularly.';
    } else if (assignmentCount == 0) {
      remark =
          'No assignment records were found for this student. Check assignment activity.';
    } else {
      remark =
          'The available academic records indicate regular participation. Continue monitoring progress.';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF6B4FD3),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                remark,
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF1EDFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B4FD3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4FD3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}