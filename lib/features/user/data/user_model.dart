import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final String? studentId;
  final List<String>? interests;
  final List<String> blockedUsers;
  final List<String> reportedUsers;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isStudentVerified;
  final int rating;
  final int totalTrips;
  final int totalReviews;
  bool isVerifiedTraveler;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.bio,
    this.location,
    this.studentId,
    this.interests,
    List<String>? blockedUsers,
    List<String>? reportedUsers,
    DateTime? createdAt,
    this.updatedAt,
    this.preferences,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isStudentVerified = false,
    this.rating = 5,
    this.totalTrips = 0,
    this.totalReviews = 0,
    this.isVerifiedTraveler = false,
  })  : blockedUsers = blockedUsers ?? [],
        reportedUsers = reportedUsers ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      location: json['location'],
      studentId: json['studentId'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      blockedUsers: json['blockedUsers'] != null
          ? List<String>.from(json['blockedUsers'])
          : [],
      reportedUsers: json['reportedUsers'] != null
          ? List<String>.from(json['reportedUsers'])
          : [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      preferences: json['preferences'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isStudentVerified: json['isStudentVerified'] ?? false,
      rating: json['rating'] ?? 5,
      totalTrips: json['totalTrips'] ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      isVerifiedTraveler: json['isVerifiedTraveler'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'studentId': studentId,
      'interests': interests,
      'blockedUsers': blockedUsers,
      'reportedUsers': reportedUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'preferences': preferences,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isStudentVerified': isStudentVerified,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalReviews': totalReviews,
      'isVerifiedTraveler': isVerifiedTraveler,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    String? location,
    String? studentId,
    List<String>? interests,
    List<String>? blockedUsers,
    List<String>? reportedUsers,
    Map<String, dynamic>? preferences,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isStudentVerified,
    int? rating,
    int? totalTrips,
    int? totalReviews,
    bool? isVerifiedTraveler,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      studentId: studentId ?? this.studentId,
      interests: interests ?? this.interests,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportedUsers: reportedUsers ?? this.reportedUsers,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      preferences: preferences ?? this.preferences,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isStudentVerified: isStudentVerified ?? this.isStudentVerified,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerifiedTraveler: isVerifiedTraveler ?? this.isVerifiedTraveler,
    );
  }
}