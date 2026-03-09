import 'package:cloud_firestore/cloud_firestore.dart';

// Mirrors one Firestore document in the /users collection
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  // Converts a Firestore DocumentSnapshot into a UserModel
  factory UserModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid:         snapshot.id,
      email:       data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt:   (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email':       email,
    'displayName': displayName,
    'createdAt':   FieldValue.serverTimestamp(),
  };
}