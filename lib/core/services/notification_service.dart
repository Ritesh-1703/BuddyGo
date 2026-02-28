import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService = FirebaseService();

  // Store navigation callback for handling taps
  Function(String route, dynamic data)? _onNotificationTapCallback;

  Future<void> initialize({Function(String route, dynamic data)? onTap}) async {
    _onNotificationTapCallback = onTap;

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission for notifications');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onNotificationTap(response.payload);
        },
      );

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $token');

      // Save token to user profile in Firestore
      await _saveTokenToFirestore(token);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Received foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
        _saveNotificationToFirestore(message);
      });

      // Listen when app opens from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📲 App opened from notification');
        _handleNotificationClick(message.data);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } else {
      print('❌ User denied notification permissions');
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print("📩 Background message: ${message.messageId}");
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firebaseService.usersCollection.doc(user.uid).update({
          'fcmToken': token,
          'notificationTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ Token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Map<String, dynamic> messageData = message.data;

      final notificationData = {
        'id':
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'type': messageData['type'] ?? 'general',
        'data': messageData,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': messageData['senderId'],
        'groupId': messageData['groupId'],
        'tripId': messageData['tripId'],
      };

      await _firebaseService.usersCollection
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationData['id'] as String)
          .set(notificationData);

      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // ✅ FIXED: _showLocalNotification with proper parameters (NO DUPLICATE)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'buddygo_channel',
          'BuddyGO Notifications',
          channelDescription: 'Travel updates, messages and alerts',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
          color: Color(0xFF7B61FF),
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'BuddyGO',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTap(String? payload) {
    print('📲 Notification tapped with payload: $payload');
    if (payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        final type = data['type'];

        if (type == 'new_message') {
          _onNotificationTapCallback?.call('/chat', data);
        } else if (type == 'verified_badge') {
          _onNotificationTapCallback?.call('/profile', data);
        } else if (type == 'trip_update') {
          _onNotificationTapCallback?.call('/trip', data);
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'];
    print('Handling notification click of type: $type');

    switch (type) {
      case 'new_message':
        _onNotificationTapCallback?.call('/chat', data);
        break;
      case 'verified_badge':
        _onNotificationTapCallback?.call('/profile', data);
        break;
      case 'trip_update':
        _onNotificationTapCallback?.call('/trip-details', data);
        break;
      case 'join_request':
        _onNotificationTapCallback?.call('/requests', data);
        break;
      default:
        _onNotificationTapCallback?.call('/home', data);
    }
  }

  // SEND NOTIFICATION FOR GROUP MESSAGES
  Future<void> sendMessageNotification({
    required String groupId,
    required String groupName,
    required String senderName,
    required String message,
    required List<String> recipientUserIds,
    String? senderId,
  }) async {
    try {
      final membersSnapshot = await _firebaseService.groupsCollection
          .doc(groupId)
          .collection('members')
          .where(FieldPath.documentId, whereIn: recipientUserIds)
          .get();

      final List<String> tokens = [];
      for (var member in membersSnapshot.docs) {
        final memberData = member.data() as Map<String, dynamic>;
        final token = memberData['fcmToken'] as String?;
        if (token != null && member.id != senderId) {
          tokens.add(token);
        }
      }

      for (String token in tokens) {
        await sendPushNotification(
          title: '💬 $groupName',
          body: '$senderName: $message',
          token: token,
          data: {
            'type': 'new_message',
            'groupId': groupId,
            'groupName': groupName,
            'senderId': senderId,
            'senderName': senderName,
          },
        );
      }
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  // SEND NOTIFICATION FOR VERIFIED BADGE
  Future<void> sendVerifiedBadgeNotification({
    required String userId,
    required String userName,
    required bool isVerified,
  }) async {
    try {
      final userDoc = await _firebaseService.usersCollection.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final token = userData?['fcmToken'] as String?;

      if (token != null) {
        await sendPushNotification(
          title: isVerified ? '✅ Verified Traveler!' : '❌ Verification Removed',
          body: isVerified
              ? 'Congratulations $userName! You are now a Verified Traveler.'
              : 'Your Verified Traveler badge has been removed.',
          token: token,
          data: {
            'type': 'verified_badge',
            'userId': userId,
            'userName': userName,
            'isVerified': isVerified,
          },
        );
      }
    } catch (e) {
      print('Error sending verified badge notification: $e');
    }
  }

  // SEND NOTIFICATION FOR TRIP UPDATES
  Future<void> sendTripUpdateNotification({
    required String tripId,
    required String tripName,
    required String updateMessage,
    required List<String> memberIds,
  }) async {
    try {
      final membersSnapshot = await _firebaseService.usersCollection
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      for (var member in membersSnapshot.docs) {
        final memberData = member.data() as Map<String, dynamic>;
        final token = memberData['fcmToken'] as String?;
        if (token != null) {
          await sendPushNotification(
            title: '✈️ Trip Update: $tripName',
            body: updateMessage,
            token: token,
            data: {
              'type': 'trip_update',
              'tripId': tripId,
              'tripName': tripName,
            },
          );
        }
      }
    } catch (e) {
      print('Error sending trip update notification: $e');
    }
  }

  // Main send method
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required String token,
    Map<String, dynamic>? data,
  }) async {
    print('📨 Sending notification:');
    print('   Token: $token');
    print('   Title: $title');
    print('   Body: $body');
    print('   Data: $data');
  }

  // Topic subscriptions
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firebaseService.usersCollection
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'read': true});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firebaseService.getUnreadNotificationCount(user.uid);
  }
}
