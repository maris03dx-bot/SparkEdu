import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String organizer;
  final int participants;
  final String status;
  final Timestamp eventDate;
  final Timestamp createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.organizer,
    required this.participants,
    required this.status,
    required this.eventDate,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'] ?? '',
      organizer: data['organizer'] ?? '',
      participants: data['participants'] ?? 0,
      status: data['status'] ?? 'Pending',
      eventDate: data['eventDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'venue': venue,
      'organizer': organizer,
      'participants': participants,
      'status': status,
      'eventDate': eventDate,
      'createdAt': createdAt,
    };
  }
}