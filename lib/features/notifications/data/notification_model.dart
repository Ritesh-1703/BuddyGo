import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  message,
  verifiedBadge,
  tripUpdate,
  joinRequest,
  report,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime timestamp;
  final String? senderId;
  final String? senderName;
  final String? groupId;
  final String? groupName;
  final String? tripId;
  final String? tripName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.read = false,
    required this.timestamp,
    this.senderId,
    this.senderName,
    this.groupId,
    this.groupName,
    this.tripId,
    this.tripName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      data: json['data'],
      read: json['read'] ?? false,
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      senderId: json['senderId'],
      senderName: json['senderName'],
      groupId: json['groupId'],
      groupName: json['groupName'],
      tripId: json['tripId'],
      tripName: json['tripName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderId': senderId,
      'senderName': senderName,
      'groupId': groupId,
      'groupName': groupName,
      'tripId': tripId,
      'tripName': tripName,
    };
  }

  static NotificationType _parseNotificationType(dynamic value) {
    if (value is NotificationType) return value;
    final String typeStr = value?.toString() ?? 'general';
    switch (typeStr) {
      case 'message':
        return NotificationType.message;
      case 'verifiedBadge':
        return NotificationType.verifiedBadge;
      case 'tripUpdate':
        return NotificationType.tripUpdate;
      case 'joinRequest':
        return NotificationType.joinRequest;
      case 'report':
        return NotificationType.report;
      default:
        return NotificationType.general;
    }
  }

  String get typeDisplay {
    switch (type) {
      case NotificationType.message:
        return 'New Message';
      case NotificationType.verifiedBadge:
        return 'Verification Update';
      case NotificationType.tripUpdate:
        return 'Trip Update';
      case NotificationType.joinRequest:
        return 'Join Request';
      case NotificationType.report:
        return 'Report Update';
      case NotificationType.general:
        return 'Notification';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.verifiedBadge:
        return Icons.verified;
      case NotificationType.tripUpdate:
        return Icons.travel_explore;
      case NotificationType.joinRequest:
        return Icons.person_add;
      case NotificationType.report:
        return Icons.flag;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.verifiedBadge:
        return Colors.green;
      case NotificationType.tripUpdate:
        return Colors.orange;
      case NotificationType.joinRequest:
        return Colors.purple;
      case NotificationType.report:
        return Colors.red;
      case NotificationType.general:
        return Colors.grey;
    }
  }
}