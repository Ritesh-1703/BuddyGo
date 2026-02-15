import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/features/user/data/user_model.dart';

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


  Future<void> joinTrip(String tripId, String userId) async {
    final tripRef = tripsCollection.doc(tripId);
    await _firestore.runTransaction((transaction) async {
      final tripDoc = await transaction.get(tripRef);
      if (!tripDoc.exists) throw Exception('Trip not found');

      final data = tripDoc.data() as Map<String, dynamic>;

      final currentMembers = (data['currentMembers'] ?? 0) as int;
      final maxMembers = (data['maxMembers'] ?? 1) as int;
      final members = List<String>.from(data['memberIds'] ?? []);

      if (members.contains(userId)) {
        throw Exception('You already joined this trip');
      }

      if (currentMembers >= maxMembers) {
        throw Exception('Trip is full');
      }

      transaction.update(tripRef, {
        'currentMembers': currentMembers + 1,
        'memberIds': FieldValue.arrayUnion([userId]),
      });
        // if (currentMembers < maxMembers) {
        //   transaction.update(tripRef, {
        //     'currentMembers': currentMembers + 1,
        //     'memberIds': FieldValue.arrayUnion([userId]),
        //   });
        // }

    });
  }

  // Image Upload
  Future<String> uploadImage(String userId, String filePath) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$userId/$fileName');
    final uploadTask = await ref.putFile(File(filePath));
    return await uploadTask.ref.getDownloadURL();
  }

  // Chat Operations
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
  }

  Stream<List<Map<String, dynamic>>> getChatMessages(String groupId) {
    return chatsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
        'timestamp': (data['timestamp'] as Timestamp).toDate(),
      };
    })
        .toList());
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

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}