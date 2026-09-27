import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventRequestScreen extends StatefulWidget {
  const EventRequestScreen({super.key});

  @override
  State<EventRequestScreen> createState() =>
      _EventRequestScreenState();
}

class _EventRequestScreenState
    extends State<EventRequestScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController venueController =
      TextEditingController();

  final TextEditingController participantsController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // ==========================================================
  // SELECTED VALUES
  // ==========================================================

  String selectedCategory = "Technical";

  DateTime? selectedDate;

  TimeOfDay? selectedTime;

  bool isSubmitting = false;

  // ==========================================================
  // GET CURRENT STUDENT PROFILE
  // ==========================================================

  Future<Map<String, dynamic>?> getStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final query = await FirebaseFirestore.instance
        .collection("users")
        .where(
          "uid",
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  // ==========================================================
  // SELECT DATE
  // ==========================================================

  Future<void> pickDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ==========================================================
  // SELECT TIME
  // ==========================================================

  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // ==========================================================
  // FORMAT TIME
  // ==========================================================

  String get formattedTime {
    if (selectedTime == null) {
      return "Select Event Time";
    }

    final hour = selectedTime!.hourOfPeriod == 0
        ? 12
        : selectedTime!.hourOfPeriod;

    final minute = selectedTime!.minute
        .toString()
        .padLeft(2, '0');

    final period = selectedTime!.period == DayPeriod.am
        ? "AM"
        : "PM";

    return "$hour:$minute $period";
  }

  // ==========================================================
  // SUBMIT EVENT
  // ==========================================================

  Future<void> submitEvent() async {
    // ========================================================
    // VALIDATE FIELDS
    // ========================================================

    if (titleController.text.trim().isEmpty ||
        venueController.text.trim().isEmpty ||
        participantsController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please fill all fields and select date and time.",
          ),
        ),
      );

      return;
    }

    // ========================================================
    // PARTICIPANTS
    // ========================================================

    final int? participants = int.tryParse(
      participantsController.text.trim(),
    );

    if (participants == null || participants <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please enter a valid number of participants.",
          ),
        ),
      );

      return;
    }

    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // ======================================================
      // CURRENT USER
      // ======================================================

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          "Student is not logged in.",
        );
      }

      // ======================================================
      // GET STUDENT PROFILE
      // ======================================================

      final studentData = await getStudentData();

      if (studentData == null) {
        throw Exception(
          "Student profile not found.",
        );
      }

      // ======================================================
      // REAL STUDENT NAME
      // ======================================================

      final String studentName =
          studentData["name"]?.toString().trim().isNotEmpty == true
              ? studentData["name"].toString().trim()
              : "Student";

      // ======================================================
      // REGISTER NUMBER
      // ======================================================

      final String registerNo =
          studentData["registerNo"]?.toString().trim() ?? "";

      if (registerNo.isEmpty) {
        throw Exception(
          "Student Register No not found.",
        );
      }

      // ======================================================
      // COMBINE DATE + TIME
      // ======================================================

      final DateTime eventDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // ======================================================
      // STUDENT CLASS INFORMATION
      // ======================================================

      final String department =
          studentData["department"]?.toString().trim() ?? "";

      final String year =
          studentData["year"]?.toString().trim() ?? "";

      final String section =
          studentData["section"]?.toString().trim() ?? "";

      final String className =
          studentData["className"]?.toString().trim() ?? "";

      // ======================================================
      // SAVE EVENT REQUEST
      // ======================================================

      await FirebaseFirestore.instance
          .collection("event_requests")
          .add({
        // ----------------------------------------------------
        // EVENT DETAILS
        // ----------------------------------------------------

        "title": titleController.text.trim(),

        "category": selectedCategory,

        "eventDate": Timestamp.fromDate(
          eventDateTime,
        ),

        "venue": venueController.text.trim(),

        "expectedParticipants": participants,

        "description": descriptionController.text.trim(),

        // ----------------------------------------------------
        // STUDENT DETAILS
        //
        // Firebase UID is kept internally.
        // Register No is the student identifier.
        // ----------------------------------------------------

        "studentUid": user.uid,

        "studentName": studentName,

        "registerNo": registerNo,

        "studentId": registerNo,

        // ----------------------------------------------------
        // CLASS DETAILS
        // ----------------------------------------------------

        "className": className,

        "department": department,

        "year": year,

        "section": section,

        // ----------------------------------------------------
        // APPROVAL SYSTEM
        // ----------------------------------------------------

        "mentorStatus": "Pending",

        "deanStatus": "Pending",

        "status": "Pending Mentor Approval",

        // ----------------------------------------------------
        // CREATED TIME
        // ----------------------------------------------------

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      // ======================================================
      // CLEAR FORM
      // ======================================================

      titleController.clear();

      venueController.clear();

      participantsController.clear();

      descriptionController.clear();

      setState(() {
        selectedCategory = "Technical";

        selectedDate = null;

        selectedTime = null;

        isSubmitting = false;
      });

      // ======================================================
      // SUCCESS DIALOG
      // ======================================================

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: const Text(
              "Proposal Submitted",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Your event proposal has been submitted successfully.\n\n"
              "Status: Pending Mentor Approval 🟡",
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to submit proposal:\n$e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !isSubmitting,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DATE SELECTOR
  // ==========================================================

  Widget buildDateSelector() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      width: double.infinity,
      child: Material(
        color: Colors.grey.shade200,
        child: InkWell(
          onTap: isSubmitting ? null : pickDate,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 30,
                ),
                const SizedBox(
                  width: 25,
                ),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? "Select Event Date"
                        : "${selectedDate!.day}/"
                            "${selectedDate!.month}/"
                            "${selectedDate!.year}",
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TIME SELECTOR
  // ==========================================================

  Widget buildTimeSelector() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      width: double.infinity,
      child: Material(
        color: Colors.grey.shade200,
        child: InkWell(
          onTap: isSubmitting ? null : pickTime,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 30,
                ),
                const SizedBox(
                  width: 25,
                ),
                Expanded(
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    participantsController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Event Proposal",
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          38,
          10,
          38,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================
            // EVENT TITLE
            // ================================================

            buildTextField(
              controller: titleController,
              label: "Event Title",
            ),

            // ================================================
            // CATEGORY
            // ================================================

            Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Technical",
                    child: Text("Technical"),
                  ),
                  DropdownMenuItem(
                    value: "Cultural",
                    child: Text("Cultural"),
                  ),
                  DropdownMenuItem(
                    value: "Sports",
                    child: Text("Sports"),
                  ),
                  DropdownMenuItem(
                    value: "Workshop",
                    child: Text("Workshop"),
                  ),
                  DropdownMenuItem(
                    value: "Seminar",
                    child: Text("Seminar"),
                  ),
                  DropdownMenuItem(
                    value: "Other",
                    child: Text("Other"),
                  ),
                ],
                onChanged: isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
              ),
            ),

            // ================================================
            // DATE
            // ================================================

            buildDateSelector(),

            // ================================================
            // TIME
            // ================================================

            buildTimeSelector(),

            // ================================================
            // VENUE
            // ================================================

            buildTextField(
              controller: venueController,
              label: "Venue",
            ),

            // ================================================
            // PARTICIPANTS
            // ================================================

            buildTextField(
              controller: participantsController,
              label: "Expected Participants",
              keyboardType: TextInputType.number,
            ),

            // ================================================
            // DESCRIPTION
            // ================================================

            buildTextField(
              controller: descriptionController,
              label: "Description",
              maxLines: 6,
            ),

            const SizedBox(
              height: 25,
            ),

            // ================================================
            // SUBMIT BUTTON
            // ================================================

            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDF7FF),
                  foregroundColor: const Color(0xFF63469A),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                    side: const BorderSide(
                      color: Color(0xFFE5DDED),
                    ),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit for Mentor Approval",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
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