import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String title;
  final String description;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int maxMembers;
  final int currentMembers;
  final double budget;
  final String hostId;
  final String hostName;
  final String hostImage;
  final List<String> images;
  final List<String> tags;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.maxMembers,
    required this.currentMembers,
    required this.budget,
    required this.hostId,
    required this.hostName,
    required this.hostImage,
    required this.images,
    required this.tags,
    required this.isPublic,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(); // FIXED HERE

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      destination: json['destination'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      maxMembers: json['maxMembers'],
      currentMembers: json['currentMembers'],
      budget: json['budget'].toDouble(),
      hostId: json['hostId'],
      hostName: json['hostName'],
      hostImage: json['hostImage'],
      images: List<String>.from(json['images']),
      tags: List<String>.from(json['tags']),
      isPublic: json['isPublic'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'budget': budget,
      'hostId': hostId,
      'hostName': hostName,
      'hostImage': hostImage,
      'images': images,
      'tags': tags,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}