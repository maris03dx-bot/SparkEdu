import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProfileHelper {
  static Future<Map<String, dynamic>?> getProfile() async {
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

  static Future<String> getName() async {
    final data = await getProfile();

    final name = data?["name"]?.toString().trim() ?? "";

    return name.isEmpty ? "Student" : name;
  }

  static Future<String> getRegisterNo() async {
    final data = await getProfile();

    final registerNo =
        data?["registerNo"]?.toString().trim() ?? "";

    return registerNo;
  }
}