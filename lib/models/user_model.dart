import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String department;
  final int grade;
  final String gender; // YENİ EKLENDİ
  final DateTime? birthDate; // YENİ EKLENDİ
  final String bio;
  final List<String> interests;
  final double ratingAvg;
  final int ratingCount;
  final int attendedCount;
  final int noShowCount;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.department,
    required this.grade,
    this.gender = 'Belirtilmedi',
    this.birthDate,
    this.bio = '',
    this.interests = const [],
    this.ratingAvg = 5.0,
    this.ratingCount = 0,
    this.attendedCount = 0,
    this.noShowCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      grade: map['grade'] ?? 1,
      gender: map['gender'] ?? 'Belirtilmedi',
      birthDate: (map['birthDate'] as Timestamp?)?.toDate(),
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      ratingAvg: (map['ratingAvg'] ?? 5.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      attendedCount: map['attendedCount'] ?? 0,
      noShowCount: map['noShowCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'department': department,
      'grade': grade,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'bio': bio,
      'interests': interests,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'attendedCount': attendedCount,
      'noShowCount': noShowCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}