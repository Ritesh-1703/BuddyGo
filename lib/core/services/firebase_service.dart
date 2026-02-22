import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/features/user/data/user_model.dart';

import '../../features/groups/data/group_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection References
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get tripsCollection => _firestore.collection('trips');
  CollectionReference get groupsCollection => _firestore.collection('groups');
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get reportsCollection => _firestore.collection('reports');

  // User Operations
  Future<void> createUserProfile(UserModel user) async {
    await usersCollection.doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await usersCollection.doc(userId).update(data);
  }

  // Trip Operations
  Future<String> createTrip(Trip trip) async {
    final docRef = await tripsCollection.add(trip.toJson());
    await tripsCollection.doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  Stream<List<Trip>> getTripsStream() {
    return tripsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('Firestore Error: $error');
      return Stream.value([]);
    })
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return Trip.fromJson({
            ...data,
            'id': doc.id, // Ensure ID is included
          });
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
          return null;
        }
      }).where((trip) => trip != null).cast<Trip>().toList();
    });
  }

  Future<List<Trip>> getTripsByUser(String userId) async {
    // final snapshot = await tripsCollection
    //     .where('hostId', isEqualTo: userId)
    //     .orderBy('createdAt', descending: true)
    //     .get();
    //
    // return snapshot.docs
    //     .map((doc) => Trip.fromJson(doc.data() as Map<String, dynamic>))
    //     .toList();

    final snapshot = await tripsCollection
        .where('hostId', isEqualTo: userId)
        .get();

    final trips = snapshot.docs
        .map((doc) => Trip.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return trips;
  }


  Future<List<Trip>> getTripsJoinedByUser(String userId) async {
    final snapshot = await tripsCollection
        .where('memberIds', arrayContains: userId)
        .get();

    final trips = snapshot.docs
        .map((doc) => Trip.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return trips;
  }

  Future<void> joinTrip(String tripId, String userId, String userName) async {
    final tripRef = tripsCollection.doc(tripId);

    await _firestore.runTransaction((transaction) async {
      // 1️⃣ Get Trip
      final tripDoc = await transaction.get(tripRef);
      if (!tripDoc.exists) throw Exception('Trip not found');

      final tripData = tripDoc.data() as Map<String, dynamic>;

      final currentMembers = (tripData['currentMembers'] ?? 0) as int;
      final maxMembers = (tripData['maxMembers'] ?? 1) as int;
      final members = List<String>.from(tripData['memberIds'] ?? []);

      if (members.contains(userId)) {
        throw Exception('You already joined this trip');
      }

      if (currentMembers >= maxMembers) {
        throw Exception('Trip is full');
      }

      // 2️⃣ Update Trip
      transaction.update(tripRef, {
        'currentMembers': currentMembers + 1,
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // 3️⃣ Find related Group by tripId
      final groupQuery = await groupsCollection
          .where('tripId', isEqualTo: tripId)
          .limit(1)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Group for this trip not found');
      }

      final groupDoc = groupQuery.docs.first;
      final groupRef = groupsCollection.doc(groupDoc.id);
      final groupData = groupDoc.data() as Map<String, dynamic>;

      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

      // 4️⃣ Join Group Logic
      if (group.isBlocked(userId)) {
        throw Exception('You are blocked from this group');
      }

      if (group.isMember(userId)) {
        return; // Already in group
      }

      if (!group.hasVacancy()) {
        throw Exception('Group is full');
      }

      if (group.isJoinApprovalRequired) {
        final request = JoinRequest(
          userId: userId,
          userName: userName,
          message: 'I want to join this trip',
        );

        transaction.update(groupRef, {
          'pendingRequests': FieldValue.arrayUnion([request.toJson()]),
        });
      } else {
        transaction.update(groupRef, {
          'memberIds': FieldValue.arrayUnion([userId]),
          'currentMembers': group.currentMembers + 1,
          'memberRoles.$userId': 'member',
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }


  // Future<void> joinTrip(String tripId, String userId) async {
  //   final tripRef = tripsCollection.doc(tripId);
  //   await _firestore.runTransaction((transaction) async {
  //     final tripDoc = await transaction.get(tripRef);
  //     if (!tripDoc.exists) throw Exception('Trip not found');
  //
  //     final data = tripDoc.data() as Map<String, dynamic>;
  //
  //     final currentMembers = (data['currentMembers'] ?? 0) as int;
  //     final maxMembers = (data['maxMembers'] ?? 1) as int;
  //     final members = List<String>.from(data['memberIds'] ?? []);
  //
  //     if (members.contains(userId)) {
  //       throw Exception('You already joined this trip');
  //     }
  //
  //     if (currentMembers >= maxMembers) {
  //       throw Exception('Trip is full');
  //     }
  //
  //     transaction.update(tripRef, {
  //       'currentMembers': currentMembers + 1,
  //       'memberIds': FieldValue.arrayUnion([userId]),
  //     });
        // if (currentMembers < maxMembers) {
        //   transaction.update(tripRef, {
        //     'currentMembers': currentMembers + 1,
        //     'memberIds': FieldValue.arrayUnion([userId]),
        //   });
        // }

  //   });
  // }

  // Image Upload
  // Future<String> uploadImage(String userId, String filePath) async {
  //   final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //   final ref = _storage.ref().child('users/$userId/$fileName');
  //   final uploadTask = await ref.putFile(File(filePath));
  //   return await uploadTask.ref.getDownloadURL();
  // }

  Future<String> uploadImage(String userId, String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw Exception('Selected image file does not exist');
    }

    final fileName = 'trip_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('trips')
        .child(userId)
        .child(fileName);

    final snapshot = await ref.putFile(file);
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  // Add to FirebaseService class
  Future<void> updateGroupLastMessage(String groupId, String message, String sender) async {
    await groupsCollection.doc(groupId).update({
      'lastMessage': message,
      'lastSender': sender,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

// Also update your sendMessage method to call this
  Future<void> sendMessage({
    required String groupId,
    required String userId,
    required String userName,
    required String text,
    String? imageUrl,
  }) async {
    await chatsCollection.add({
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [userId],
    });

    // Update group's last message
    await updateGroupLastMessage(groupId, text, userName);
  }

  // Stream<List<Map<String, dynamic>>> getChatMessages(String groupId) {
  //   return chatsCollection
  //       .where('groupId', isEqualTo: groupId)
  //       .orderBy('timestamp', descending: false)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //       .map((doc) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     return {
  //       'id': doc.id,
  //       ...data,
  //       'timestamp': (data['timestamp'] as Timestamp).toDate(),
  //     };
  //   })
  //       .toList());
  // }

  // Replace your existing getChatMessages method with this:
  Stream<QuerySnapshot<Object?>> getChatMessages(String groupId) {
    return chatsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Report Operations
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
    String? evidenceUrl,
  }) async {
    await reportsCollection.add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'details': details,
      'evidenceUrl': evidenceUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Group Operations
  Future<String> createGroup(GroupModel group) async {
    final docRef = await groupsCollection.add(group.toJson());
    await groupsCollection.doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  Stream<List<GroupModel>> getGroupsStream() {
    return groupsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('lastActivityAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('Groups stream error: $error');
      return Stream.value([]);
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return GroupModel.fromJson({
            ...data,
            'id': doc.id,
          });
        } catch (e) {
          print('Error parsing group ${doc.id}: $e');
          return null;
        }
      }).where((group) => group != null).cast<GroupModel>().toList();
    });
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await groupsCollection.doc(groupId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return GroupModel.fromJson({
        ...data,
        'id': doc.id,
      });
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    await groupsCollection.doc(groupId).update(updates);
  }

  Future<void> joinGroup(String groupId, String userId, String userName, {String? message}) async {
    final groupRef = groupsCollection.doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final data = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...data, 'id': groupDoc.id});

      if (group.isBlocked(userId)) {
        throw Exception('You are blocked from this group');
      }

      if (group.isMember(userId)) {
        throw Exception('Already a member');
      }

      if (!group.hasVacancy()) {
        throw Exception('Group is full');
      }

      if (group.isJoinApprovalRequired) {
        // Add to pending requests
        final request = JoinRequest(
          userId: userId,
          userName: userName,
          message: message ?? 'I want to join this trip',
        );

        transaction.update(groupRef, {
          'pendingRequests': FieldValue.arrayUnion([request.toJson()]),
        });
      } else {
        // Direct join
        transaction.update(groupRef, {
          'memberIds': FieldValue.arrayUnion([userId]),
          'currentMembers': group.currentMembers + 1,
          'memberRoles.$userId': 'member',
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> approveJoinRequest(String groupId, String userId) async {
    final groupRef = groupsCollection.doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final data = groupDoc.data() as Map<String, dynamic>;
      final pendingRequests = List<Map<String, dynamic>>.from(data['pendingRequests'] ?? []);

      // Remove request from pending
      final updatedRequests = pendingRequests.where((req) => req['userId'] != userId).toList();

      // Add user to members
      transaction.update(groupRef, {
        'pendingRequests': updatedRequests,
        'memberIds': FieldValue.arrayUnion([userId]),
        'currentMembers': (data['currentMembers'] ?? 0) + 1,
        'memberRoles.$userId': 'member',
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectJoinRequest(String groupId, String userId) async {
    final groupRef = groupsCollection.doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final data = groupDoc.data() as Map<String, dynamic>;
      final pendingRequests = List<Map<String, dynamic>>.from(data['pendingRequests'] ?? []);

      // Remove request from pending
      final updatedRequests = pendingRequests.where((req) => req['userId'] != userId).toList();

      transaction.update(groupRef, {
        'pendingRequests': updatedRequests,
      });
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final groupRef = groupsCollection.doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final data = groupDoc.data() as Map<String, dynamic>;
      final currentMembers = data['currentMembers'] ?? 0;

      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'currentMembers': currentMembers - 1,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // If last member leaves, deactivate group
      if (currentMembers - 1 <= 0) {
        transaction.update(groupRef, {
          'isActive': false,
        });
      }
    });
  }

  Stream<List<Trip>> getTripsStreamWithFilter(String filter) {
    Query query = tripsCollection.orderBy('createdAt', descending: true);

    final now = DateTime.now();

    if (filter == 'Upcoming') {
      // Includes both ongoing + upcoming (not past)
      query = tripsCollection
          .where('endDate', isGreaterThanOrEqualTo: now)
          .orderBy('endDate')
          .orderBy('createdAt', descending: true);
    }
    else if (filter == 'Popular') {
      query = tripsCollection
          .orderBy('currentMembers', descending: true)
          .orderBy('createdAt', descending: true); // ✅ tie-breaker by latest
    }
    else if (filter == 'Budget') {
      query = tripsCollection
          .where('budget', isLessThanOrEqualTo: 10000)
          .orderBy('budget')
          .orderBy(
          'createdAt', descending: true); // ✅ latest first inside budget
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Trip.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }





  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}