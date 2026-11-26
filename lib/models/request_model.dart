import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String userId;
  final String userName;
  final String userDept;
  final int userGrade;
  final double userRating;
  final String requestNote;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  RequestModel({
    required this.userId,
    required this.userName,
    required this.userDept,
    required this.userGrade,
    required this.userRating,
    required this.requestNote,
    this.status = 'pending',
    required this.createdAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RequestModel(
      userId: map['userId'] ?? documentId,
      userName: map['userName'] ?? '',
      userDept: map['userDept'] ?? '',
      userGrade: map['userGrade'] ?? 1,
      userRating: (map['userRating'] ?? 5.0).toDouble(),
      requestNote: map['requestNote'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userDept': userDept,
      'userGrade': userGrade,
      'userRating': userRating,
      'requestNote': requestNote,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}