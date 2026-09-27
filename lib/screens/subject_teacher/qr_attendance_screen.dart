import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class QRAttendanceScreen extends StatelessWidget {
  const QRAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final subject = "Artificial Intelligence";
    final teacher = "Mr. Kumar";

    final qrData =
        "subject=$subject;"
        "teacher=$teacher;"
        "date=${DateFormat('yyyy-MM-dd').format(now)};"
        "time=${DateFormat('HH:mm').format(now)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Attendance QR"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.qr_code_2,
                color: Colors.blue,
                size: 70,
              ),

              const SizedBox(height: 20),

              const Text(
                "Attendance QR Code",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                DateFormat(
                  "dd MMM yyyy  •  hh:mm a",
                ).format(now),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: QrImageView(
                  data: qrData,
                  size: 280,
                ),
              ),

              const SizedBox(height: 30),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(subject),
                  subtitle: Text("Teacher : $teacher"),
                ),
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text("Generated At"),
                  subtitle: Text(
                    DateFormat(
                      "dd MMM yyyy  hh:mm a",
                    ).format(now),
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