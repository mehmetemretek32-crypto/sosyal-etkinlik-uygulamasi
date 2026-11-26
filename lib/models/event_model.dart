import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String hostId;
  final String hostName;
  final double hostRating;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final bool isOnline;
  final String locationName;

  final String? platformLink;
  final double? latitude;
  final double? longitude;
  final DateTime endDate;

  final DateTime eventDate;
  final int maxCapacity;
  final bool requiresApproval;
  final int currentCount;
  final List<String> approvedUserIds;
  final List<String> pendingUserIds;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.hostId,
    this.hostName = '',
    this.hostRating = 0.0,
    required this.title,
    this.description = '',
    required this.category,
    required this.tags,
    required this.isOnline,
    required this.locationName,
    this.platformLink,
    this.latitude,
    this.longitude,
    required this.endDate,
    required this.eventDate,
    required this.maxCapacity,
    required this.requiresApproval,
    required this.currentCount,
    required this.approvedUserIds,
    required this.pendingUserIds,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? 'Gizli Kullanıcı',
      hostRating: (map['hostRating'] ?? 0.0).toDouble(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isOnline: map['isOnline'] ?? false,
      locationName: map['locationName'] ?? '',
      platformLink: map['platformLink'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ??
          (map['eventDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      eventDate: (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxCapacity: map['maxCapacity'] ?? 10,
      requiresApproval: map['requiresApproval'] ?? false,
      currentCount: map['currentCount'] ?? 1,
      approvedUserIds: List<String>.from(map['approvedUserIds'] ?? []),
      pendingUserIds: List<String>.from(map['pendingUserIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // EKSİK OLAN FONKSİYON EKLENDİ
  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'hostRating': hostRating,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'isOnline': isOnline,
      'locationName': locationName,
      'platformLink': platformLink,
      'latitude': latitude,
      'longitude': longitude,
      'endDate': Timestamp.fromDate(endDate),
      'eventDate': Timestamp.fromDate(eventDate),
      'maxCapacity': maxCapacity,
      'requiresApproval': requiresApproval,
      'currentCount': currentCount,
      'approvedUserIds': approvedUserIds,
      'pendingUserIds': pendingUserIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}