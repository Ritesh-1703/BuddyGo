import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReportStatus {
  pending,
  reviewed,
  dismissed,
  actionTaken,
}

enum ReportReason {
  inappropriateBehavior('Inappropriate behavior'),
  harassment('Harassment'),
  fakeProfile('Fake profile'),
  spamScam('Spam or scam'),
  offensiveContent('Offensive content'),
  other('Other');

  final String displayName;
  const ReportReason(this.displayName);

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
          (e) => e.displayName == value || e.name == value,
      orElse: () => ReportReason.other,
    );
  }
}

enum ReportType {
  user,
  trip,
  group,
  message,
}

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? reporterImage;
  final String reportedUserId;
  final String reportedUserName;
  final ReportType reportType;
  final String? targetId; // tripId, groupId, or messageId
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? adminNotes;
  final String? evidenceUrl; // Screenshot URL if provided

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reporterImage,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reportType,
    this.targetId,
    required this.reason,
    this.details,
    this.status = ReportStatus.pending,
    DateTime? createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.adminNotes,
    this.evidenceUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reporterName: json['reporterName'] ?? 'Unknown',
      reporterImage: json['reporterImage'],
      reportedUserId: json['reportedUserId'] ?? '',
      reportedUserName: json['reportedUserName'] ?? 'Unknown',
      reportType: _parseReportType(json['reportType']),
      targetId: json['targetId'],
      reason: ReportReason.fromString(json['reason'] ?? 'other'),
      details: json['details'],
      status: _parseReportStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: json['resolvedBy'],
      adminNotes: json['adminNotes'],
      evidenceUrl: json['evidenceUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterImage': reporterImage,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reportType': reportType.name,
      'targetId': targetId,
      'reason': reason.name,
      'reasonDisplay': reason.displayName,
      'details': details,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'adminNotes': adminNotes,
      'evidenceUrl': evidenceUrl,
    };
  }

  static ReportType _parseReportType(dynamic value) {
    if (value is ReportType) return value;
    final String typeStr = value?.toString() ?? 'user';
    return ReportType.values.firstWhere(
          (e) => e.name == typeStr,
      orElse: () => ReportType.user,
    );
  }

  static ReportStatus _parseReportStatus(dynamic value) {
    if (value is ReportStatus) return value;
    final String statusStr = value?.toString() ?? 'pending';
    return ReportStatus.values.firstWhere(
          (e) => e.name == statusStr,
      orElse: () => ReportStatus.pending,
    );
  }

  // Helper methods
  bool get isPending => status == ReportStatus.pending;
  bool get isReviewed => status == ReportStatus.reviewed;
  bool get isDismissed => status == ReportStatus.dismissed;
  bool get isActionTaken => status == ReportStatus.actionTaken;

  String get statusDisplay {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.reviewed:
        return 'Reviewed';
      case ReportStatus.dismissed:
        return 'Dismissed';
      case ReportStatus.actionTaken:
        return 'Action Taken';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.dismissed:
        return Colors.grey;
      case ReportStatus.actionTaken:
        return Colors.green;
    }
  }
}