import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupType {
  public,
  private,
  duo,
}

enum MemberRole {
  admin,
  moderator,
  member,
  pending,
  blocked,
}

enum RequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final String createdBy;
  final String createdByName;
  final String? createdByImage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Group Details
  final GroupType type;
  final int maxMembers;
  final int currentMembers;
  final List<String> memberIds;
  final Map<String, MemberRole> memberRoles;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final List<String> blockedUserIds;

  // Trip Specific
  final String? tripId;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final List<String> tags;
  final List<String> interests;

  // Settings
  final bool isJoinApprovalRequired;
  final bool isChatEnabled;
  final bool isLocationSharingEnabled;
  final bool isMemberListPublic;

  // Stats
  final int totalMessages;
  final int totalPhotos;
  final int totalEvents;
  final double averageRating;

  // Join Requests
  final List<JoinRequest> pendingRequests;

  // Metadata
  final DateTime lastActivityAt;
  final bool isActive;
  final bool isDeleted;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    required this.createdBy,
    required this.createdByName,
    this.createdByImage,
    DateTime? createdAt,
    this.updatedAt,
    this.type = GroupType.public,
    this.maxMembers = 10,
    this.currentMembers = 1,
    List<String>? memberIds,
    Map<String, MemberRole>? memberRoles,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? blockedUserIds,
    this.destination,
    this.startDate,
    this.endDate,
    this.budget,
    List<String>? tags,
    List<String>? interests,
    this.tripId,
    this.isJoinApprovalRequired = false,
    this.isChatEnabled = true,
    this.isLocationSharingEnabled = true,
    this.isMemberListPublic = true,
    this.totalMessages = 0,
    this.totalPhotos = 0,
    this.totalEvents = 0,
    this.averageRating = 5.0,
    List<JoinRequest>? pendingRequests,
    DateTime? lastActivityAt,
    this.isActive = true,
    this.isDeleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        memberIds = memberIds ?? [createdBy],
        memberRoles = memberRoles ?? {createdBy: MemberRole.admin},
        adminIds = adminIds ?? [createdBy],
        moderatorIds = moderatorIds ?? [],
        blockedUserIds = blockedUserIds ?? [],
        tags = tags ?? [],
        interests = interests ?? [],
        pendingRequests = pendingRequests ?? [],
        lastActivityAt = lastActivityAt ?? DateTime.now();

  // Factory constructor for creating from Firestore
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    // Parse member roles
    Map<String, MemberRole> roles = {};
    if (json['memberRoles'] != null) {
      (json['memberRoles'] as Map<String, dynamic>).forEach((key, value) {
        roles[key] = MemberRole.values.firstWhere(
              (e) => e.toString() == 'MemberRole.$value',
          orElse: () => MemberRole.member,
        );
      });
    }

    // Parse pending requests
    List<JoinRequest> requests = [];
    if (json['pendingRequests'] != null) {
      requests = (json['pendingRequests'] as List)
          .map((req) => JoinRequest.fromJson(req))
          .toList();
    }

    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['coverImage'],
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
      createdByImage: json['createdByImage'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      type: json['type'] != null
          ? GroupType.values.firstWhere(
            (e) => e.toString() == 'GroupType.${json['type']}',
        orElse: () => GroupType.public,
      )
          : GroupType.public,
      maxMembers: json['maxMembers'] ?? 10,
      currentMembers: json['currentMembers'] ?? 1,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      memberRoles: roles,
      adminIds: List<String>.from(json['adminIds'] ?? []),
      moderatorIds: List<String>.from(json['moderatorIds'] ?? []),
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? []),
      tripId: json['tripId'],
      destination: json['destination'],
      startDate: json['startDate'] != null
          ? (json['startDate'] as Timestamp).toDate()
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      budget: json['budget']?.toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      isJoinApprovalRequired: json['isJoinApprovalRequired'] ?? false,
      isChatEnabled: json['isChatEnabled'] ?? true,
      isLocationSharingEnabled: json['isLocationSharingEnabled'] ?? true,
      isMemberListPublic: json['isMemberListPublic'] ?? true,
      totalMessages: json['totalMessages'] ?? 0,
      totalPhotos: json['totalPhotos'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
      averageRating: (json['averageRating'] ?? 5.0).toDouble(),
      pendingRequests: requests,
      lastActivityAt: json['lastActivityAt'] != null
          ? (json['lastActivityAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    // Convert member roles to strings
    Map<String, String> rolesString = {};
    memberRoles.forEach((key, value) {
      rolesString[key] = value.toString().split('.').last;
    });

    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByImage': createdByImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'type': type.toString().split('.').last,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'memberIds': memberIds,
      'memberRoles': rolesString,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'blockedUserIds': blockedUserIds,
      'tripId': tripId,
      'destination': destination,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'budget': budget,
      'tags': tags,
      'interests': interests,
      'isJoinApprovalRequired': isJoinApprovalRequired,
      'isChatEnabled': isChatEnabled,
      'isLocationSharingEnabled': isLocationSharingEnabled,
      'isMemberListPublic': isMemberListPublic,
      'totalMessages': totalMessages,
      'totalPhotos': totalPhotos,
      'totalEvents': totalEvents,
      'averageRating': averageRating,
      'pendingRequests': pendingRequests.map((req) => req.toJson()).toList(),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }

  // Helper methods
  bool isMember(String userId) => memberIds.contains(userId);

  bool isAdmin(String userId) => adminIds.contains(userId);

  bool isModerator(String userId) => moderatorIds.contains(userId);

  bool canManage(String userId) => isAdmin(userId) || isModerator(userId);

  bool isBlocked(String userId) => blockedUserIds.contains(userId);

  bool hasVacancy() => currentMembers < maxMembers;

  int availableSpots() => maxMembers - currentMembers;

  bool isUpcoming() {
    if (startDate == null) return false;
    return startDate!.isAfter(DateTime.now());
  }

  bool isOngoing() {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }

  bool isPast() {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  int get durationInDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  // Create a copy with updated fields
  GroupModel copyWith({
    String? name,
    String? description,
    String? coverImage,
    DateTime? updatedAt,
    GroupType? type,
    int? maxMembers,
    int? currentMembers,
    List<String>? memberIds,
    Map<String, MemberRole>? memberRoles,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? blockedUserIds,
    String? tripId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    List<String>? tags,
    List<String>? interests,
    bool? isJoinApprovalRequired,
    bool? isChatEnabled,
    bool? isLocationSharingEnabled,
    bool? isMemberListPublic,
    int? totalMessages,
    int? totalPhotos,
    int? totalEvents,
    double? averageRating,
    List<JoinRequest>? pendingRequests,
    DateTime? lastActivityAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByImage: createdByImage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      type: type ?? this.type,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      memberIds: memberIds ?? this.memberIds,
      memberRoles: memberRoles ?? this.memberRoles,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      tripId: tripId ?? this.tripId,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      tags: tags ?? this.tags,
      interests: interests ?? this.interests,
      isJoinApprovalRequired: isJoinApprovalRequired ?? this.isJoinApprovalRequired,
      isChatEnabled: isChatEnabled ?? this.isChatEnabled,
      isLocationSharingEnabled: isLocationSharingEnabled ?? this.isLocationSharingEnabled,
      isMemberListPublic: isMemberListPublic ?? this.isMemberListPublic,
      totalMessages: totalMessages ?? this.totalMessages,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      totalEvents: totalEvents ?? this.totalEvents,
      averageRating: averageRating ?? this.averageRating,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Join Request Model
class JoinRequest {
  final String userId;
  final String userName;
  final String? userImage;
  final String message;
  final DateTime requestedAt;
  final RequestStatus status;
  final DateTime? respondedAt;
  final String? respondedBy;

  JoinRequest({
    required this.userId,
    required this.userName,
    this.userImage,
    required this.message,
    DateTime? requestedAt,
    this.status = RequestStatus.pending,
    this.respondedAt,
    this.respondedBy,
  }) : requestedAt = requestedAt ?? DateTime.now();

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImage: json['userImage'],
      message: json['message'] ?? '',
      requestedAt: json['requestedAt'] != null
          ? (json['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] != null
          ? RequestStatus.values.firstWhere(
            (e) => e.toString() == 'RequestStatus.${json['status']}',
        orElse: () => RequestStatus.pending,
      )
          : RequestStatus.pending,
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: json['respondedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'message': message,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.toString().split('.').last,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
    };
  }

  JoinRequest copyWith({
    RequestStatus? status,
    DateTime? respondedAt,
    String? respondedBy,
  }) {
    return JoinRequest(
      userId: userId,
      userName: userName,
      userImage: userImage,
      message: message,
      requestedAt: requestedAt,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }
}

// Group Activity Model (for timeline/feed)
class GroupActivity {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String? userImage;
  final ActivityType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> comments;

  GroupActivity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.type,
    required this.content,
    this.metadata,
    DateTime? timestamp,
    List<String>? likes,
    List<String>? comments,
  })  : timestamp = timestamp ?? DateTime.now(),
        likes = likes ?? [],
        comments = comments ?? [];

  factory GroupActivity.fromJson(Map<String, dynamic> json) {
    return GroupActivity(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImage: json['userImage'],
      type: ActivityType.values.firstWhere(
            (e) => e.toString() == 'ActivityType.${json['type']}',
        orElse: () => ActivityType.message,
      ),
      content: json['content'] ?? '',
      metadata: json['metadata'],
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      likes: List<String>.from(json['likes'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'type': type.toString().split('.').last,
      'content': content,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
    };
  }
}

enum ActivityType {
  message,
  photo,
  event,
  poll,
  member_joined,
  member_left,
  trip_updated,
}

// Group Stats Model
class GroupStats {
  final int totalMembers;
  final int activeToday;
  final int totalMessages;
  final int totalPhotos;
  final int totalEvents;
  final double averageRating;
  final Map<String, int> memberActivity;

  GroupStats({
    required this.totalMembers,
    required this.activeToday,
    required this.totalMessages,
    required this.totalPhotos,
    required this.totalEvents,
    required this.averageRating,
    required this.memberActivity,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalMembers: json['totalMembers'] ?? 0,
      activeToday: json['activeToday'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      totalPhotos: json['totalPhotos'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      memberActivity: Map<String, int>.from(json['memberActivity'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'activeToday': activeToday,
      'totalMessages': totalMessages,
      'totalPhotos': totalPhotos,
      'totalEvents': totalEvents,
      'averageRating': averageRating,
      'memberActivity': memberActivity,
    };
  }
}