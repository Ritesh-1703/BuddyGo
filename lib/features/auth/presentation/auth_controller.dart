import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/user/data/user_model.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _resetPasswordMessage; // For tracking password reset status

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get resetPasswordMessage => _resetPasswordMessage;

  AuthController() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (_isLoggedIn) {
      await _loadCurrentUser();
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMTokenToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get the current FCM token
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken != null) {
        // Save token to Firestore
        await _firebaseService.usersCollection.doc(user.uid).update({
          'fcmToken': fcmToken,
          'notificationTokens': FieldValue.arrayUnion([fcmToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        print('✅ FCM token saved for user: ${user.uid}');

        // Also update currentUser if exists
        if (_currentUser != null) {
          _currentUser!.fcmToken = fcmToken;
          if (_currentUser!.notificationTokens == null) {
            _currentUser!.notificationTokens = [];
          }
          if (!_currentUser!.notificationTokens!.contains(fcmToken)) {
            _currentUser!.notificationTokens!.add(fcmToken);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Refresh FCM token (call this when token changes)
  Future<void> refreshFCMToken() async {
    await _saveFCMTokenToFirestore();
  }

  // Update user profile with new fields
  Future<void> updateProfileWithDetails({
    String? name,
    String? bio,
    String? location,
    String? studentId,
    List<String>? interests,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      final updatedUser = _currentUser!.copyWith(
        name: name,
        bio: bio,
        location: location,
        studentId: studentId,
        interests: interests,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      final updateData = {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (studentId != null) 'studentId': studentId,
        if (interests != null) 'interests': interests,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        if (gender != null) 'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebaseService.updateUserProfile(
        _currentUser!.id,
        updateData,
      );

      _currentUser = updatedUser;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Update _createUserProfile to include FCM token and new fields
  Future<void> _createUserProfile(User firebaseUser, {DateTime? dateOfBirth, String? gender}) async {
    // Get FCM token
    String? fcmToken = await _firebaseMessaging.getToken();

    final userModel = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      dateOfBirth: dateOfBirth,
      gender: gender,
      fcmToken: fcmToken,
      notificationTokens: fcmToken != null ? [fcmToken] : [],
    );

    await _firebaseService.createUserProfile(userModel);
    _currentUser = userModel;
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firebaseService.getUserProfile(user.uid);
      if (userData != null) {
        _currentUser = userData;
      } else {
        // Create user profile if doesn't exist
        await _createUserProfile(user);
      }
    }
    notifyListeners();
  }

  // NEW: Forgot Password - Send reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _resetPasswordMessage = null;

      await _auth.sendPasswordResetEmail(email: email);

      _resetPasswordMessage = 'Password reset email sent successfully. Please check your inbox.';
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      if (e.code == 'user-not-found') {
        _resetPasswordMessage = 'No user found with this email address.';
      } else if (e.code == 'invalid-email') {
        _resetPasswordMessage = 'Please enter a valid email address.';
      } else {
        _resetPasswordMessage = 'Error: ${e.message}';
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _resetPasswordMessage = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  // NEW: Clear reset password message
  void clearResetPasswordMessage() {
    _resetPasswordMessage = null;
    notifyListeners();
  }

  // Updated signInWithEmail with email verification check
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      await user?.reload();

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        _setLoading(false);

        throw FirebaseAuthException(
          code: "email-not-verified",
          message: "Please verify your email first.",
        );
      }

      await _saveLoginStatus(true);
      await _loadCurrentUser();

      // Save FCM token after successful login
      await _saveFCMTokenToFirestore();

      _setLoading(false);
      return true;

    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Updated signUpWithEmail to include new fields
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      _setLoading(true);

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name
      await result.user?.updateDisplayName(name);

      // Get FCM token
      String? fcmToken = await _firebaseMessaging.getToken();

      // Create user profile with all fields
      final userModel = UserModel(
        id: result.user!.uid,
        email: email,
        name: name,
        isEmailVerified: false,
        dateOfBirth: dateOfBirth,
        gender: gender,
        fcmToken: fcmToken,
        notificationTokens: fcmToken != null ? [fcmToken] : [],
      );

      await _firebaseService.createUserProfile(userModel);

      // Send verification email
      await result.user?.sendEmailVerification();

      // Sign out user until they verify email
      await _auth.signOut();

      _setLoading(false);
      return true;

    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      print(e.message);
      return false;
    }
  }

  // Updated signInWithGoogle to include FCM token
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      // Get FCM token
      String? fcmToken = await _firebaseMessaging.getToken();

      // Check if user exists
      final existingUser = await _firebaseService.getUserProfile(result.user!.uid);
      if (existingUser == null) {
        // Create new user with FCM token
        final userModel = UserModel(
          id: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName,
          photoUrl: result.user!.photoURL,
          isEmailVerified: result.user!.emailVerified,
          fcmToken: fcmToken,
          notificationTokens: fcmToken != null ? [fcmToken] : [],
        );
        await _firebaseService.createUserProfile(userModel);
        _currentUser = userModel;
      } else {
        // Update existing user with new FCM token
        _currentUser = existingUser;
        await _firebaseService.usersCollection.doc(result.user!.uid).update({
          'fcmToken': fcmToken,
          'notificationTokens': FieldValue.arrayUnion([fcmToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        // Update currentUser
        _currentUser!.fcmToken = fcmToken;
        if (_currentUser!.notificationTokens == null) {
          _currentUser!.notificationTokens = [];
        }
        if (!_currentUser!.notificationTokens!.contains(fcmToken)) {
          _currentUser!.notificationTokens!.add(fcmToken!);
        }
      }

      await _saveLoginStatus(true);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Updated updateProfile to include new fields
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? location,
    String? studentId,
    List<String>? interests,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      final updatedUser = _currentUser!.copyWith(
        name: name,
        bio: bio,
        location: location,
        studentId: studentId,
        interests: interests,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      final updateData = {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (studentId != null) 'studentId': studentId,
        if (interests != null) 'interests': interests,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        if (gender != null) 'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebaseService.updateUserProfile(
        _currentUser!.id,
        updateData,
      );

      _currentUser = updatedUser;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Updated signOut to remove FCM token
  Future<void> signOut() async {
    // Remove FCM token before signing out
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          await _firebaseService.usersCollection.doc(user.uid).update({
            'fcmToken': FieldValue.delete(),
            'notificationTokens': FieldValue.arrayRemove([fcmToken]),
          });
        }
      }
    } catch (e) {
      print('Error removing FCM token: $e');
    }

    await _auth.signOut();
    await _googleSignIn.signOut();
    await _saveLoginStatus(false);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveLoginStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
    _isLoggedIn = status;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}