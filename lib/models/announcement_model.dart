import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final bool isPinned;
  final Timestamp createdAt;
  final Timestamp expiryAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isPinned,
    required this.createdAt,
    required this.expiryAt,
  });

  factory AnnouncementModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isPinned: data['isPinned'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expiryAt: data['expiryAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'isPinned': isPinned,
      'createdAt': createdAt,
      'expiryAt': expiryAt,
    };
  }
}