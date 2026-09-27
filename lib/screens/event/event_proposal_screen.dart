import 'package:flutter/material.dart';

class EventProposalScreen extends StatefulWidget {
  const EventProposalScreen({super.key});

  @override
  State<EventProposalScreen> createState() => _EventProposalScreenState();
}

class _EventProposalScreenState extends State<EventProposalScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final venueController = TextEditingController();
  final participantController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = "Technical";

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final List<String> categories = [
    "Technical",
    "Workshop",
    "Seminar",
    "Cultural",
    "Sports",
    "Club Activity",
  ];

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Proposal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Event Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter event title";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: categories.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              ListTile(
                tileColor: Colors.grey.shade200,
                leading: const Icon(Icons.calendar_month),
                title: Text(
                  selectedDate == null
                      ? "Select Event Date"
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: pickDate,
              ),

              const SizedBox(height: 15),

              ListTile(
                tileColor: Colors.grey.shade200,
                leading: const Icon(Icons.access_time),
                title: Text(
                  selectedTime == null
                      ? "Select Event Time"
                      : selectedTime!.format(context),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: pickTime,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: venueController,
                decoration: const InputDecoration(
                  labelText: "Venue",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: participantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Expected Participants",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Proposal Submitted"),
                          content: const Text(
                            "Your event proposal has been submitted successfully.\n\nStatus: Pending Mentor Approval 🟡",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                    }
                  },
                  child: const Text(
                    "Submit for Mentor Approval",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}