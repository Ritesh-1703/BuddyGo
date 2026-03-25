import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/safety/presentation/report_screen.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';

import '../../safety/data/report_model.dart';

// ==================== CONSTANTS ====================
class ProfileViewColors {
  static const Color primary = Color(0xFF8B5CF6);     // Purple
  static const Color secondary = Color(0xFFFF6B6B);   // Coral
  static const Color tertiary = Color(0xFF4FD1C5);    // Teal
  static const Color accent = Color(0xFFFBBF24);      // Yellow
  static const Color lavender = Color(0xFF9F7AEA);    // Lavender
  static const Color success = Color(0xFF06D6A0);     // Mint Green
  static const Color error = Color(0xFFFF6B6B);       // Coral for errors
  static const Color warning = Color(0xFFFBBF24);      // Yellow for warnings
  static const Color background = Color(0xFFF0F2FE);  // Light purple tint
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
}

// ==================== LEVEL SYSTEM ====================
class LevelSystem {
  static const levels = [
    {'name': 'Explorer', 'minTrips': 0, 'color': ProfileViewColors.tertiary},
    {'name': 'Adventurer', 'minTrips': 5, 'color': ProfileViewColors.primary},
    {'name': 'Globetrotter', 'minTrips': 15, 'color': ProfileViewColors.secondary},
    {'name': 'Voyager', 'minTrips': 30, 'color': ProfileViewColors.accent},
    {'name': 'Nomad', 'minTrips': 50, 'color': ProfileViewColors.lavender},
    {'name': 'Legend', 'minTrips': 100, 'color': ProfileViewColors.success},
  ];

  static Map<String, dynamic> getLevel(int tripCount) {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (tripCount >= (levels[i]['minTrips'] as int)) {
        return levels[i];
      }
    }
    return levels.first;
  }

  static double getProgress(int tripCount) {
    final currentLevel = getLevel(tripCount);
    final nextLevel = getNextLevel(tripCount);

    if (nextLevel == null) return 1.0;

    final currentMin = currentLevel['minTrips'] as int;
    final nextMin = nextLevel['minTrips'] as int;

    return (tripCount - currentMin) / (nextMin - currentMin);
  }

  static Map<String, dynamic>? getNextLevel(int tripCount) {
    for (int i = 0; i < levels.length; i++) {
      if (tripCount < (levels[i]['minTrips'] as int )) {
        return levels[i];
      }
    }
    return null;
  }
}

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isBlocked = false;
  bool _isInContacts = false;
  List<Map<String, dynamic>> _userTrips = [];
  List<Map<String, dynamic>> _mutualGroups = [];

  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadUserData();
    _checkBlockStatus();
    _checkContactStatus();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userDoc = await _firebaseService.usersCollection
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      final tripsSnapshot = await _firebaseService.tripsCollection
          .where('hostId', isEqualTo: widget.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      _userTrips = tripsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final currentUserGroups = await _firebaseService.groupsCollection
            .where('memberIds', arrayContains: currentUser.uid)
            .get();

        final otherUserGroups = await _firebaseService.groupsCollection
            .where('memberIds', arrayContains: widget.userId)
            .get();

        final currentGroupIds = currentUserGroups.docs.map((doc) => doc.id).toSet();
        final otherGroupIds = otherUserGroups.docs.map((doc) => doc.id).toSet();

        final mutualIds = currentGroupIds.intersection(otherGroupIds).toList();

        _mutualGroups = [];
        for (String id in mutualIds) {
          final groupDoc = await _firebaseService.groupsCollection.doc(id).get();
          if (groupDoc.exists) {
            final groupData = groupDoc.data() as Map<String, dynamic>;
            _mutualGroups.add({
              'id': id,
              'name': groupData['name'] ?? 'Unknown Group',
              'image': groupData['coverImage'],
            });
          }
        }
      }

    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBlockStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserDoc = await _firebaseService.usersCollection
          .doc(currentUser.uid)
          .get();

      if (currentUserDoc.exists) {
        final data = currentUserDoc.data() as Map<String, dynamic>;
        final blockedUsers = List<String>.from(data['blockedUsers'] ?? []);
        setState(() {
          _isBlocked = blockedUsers.contains(widget.userId);
        });
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  Future<void> _checkContactStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserDoc = await _firebaseService.usersCollection
          .doc(currentUser.uid)
          .get();

      if (currentUserDoc.exists) {
        final data = currentUserDoc.data() as Map<String, dynamic>;
        final contacts = List<String>.from(data['contacts'] ?? []);
        setState(() {
          _isInContacts = contacts.contains(widget.userId);
        });
      }
    } catch (e) {
      print('Error checking contact status: $e');
    }
  }

  Future<void> _toggleBlockUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildActionDialog(
        title: _isBlocked ? 'Unblock User' : 'Block User',
        message: _isBlocked
            ? 'Are you sure you want to unblock this user?'
            : 'Are you sure you want to block this user? You will no longer receive messages from them.',
        actionText: _isBlocked ? 'Unblock' : 'Block',
        actionColor: _isBlocked ? ProfileViewColors.success : ProfileViewColors.error,
      ),
    );

    if (confirm != true) return;

    try {
      if (_isBlocked) {
        await _firebaseService.usersCollection.doc(currentUser.uid).update({
          'blockedUsers': FieldValue.arrayRemove([widget.userId]),
        });
      } else {
        await _firebaseService.usersCollection.doc(currentUser.uid).update({
          'blockedUsers': FieldValue.arrayUnion([widget.userId]),
        });
      }

      setState(() {
        _isBlocked = !_isBlocked;
      });

      _showSnackbar(
        _isBlocked ? 'User unblocked successfully' : 'User blocked successfully',
        isSuccess: !_isBlocked,
      );
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _toggleContact() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (_isInContacts) {
        await _firebaseService.usersCollection.doc(currentUser.uid).update({
          'contacts': FieldValue.arrayRemove([widget.userId]),
        });
      } else {
        await _firebaseService.usersCollection.doc(currentUser.uid).update({
          'contacts': FieldValue.arrayUnion([widget.userId]),
        });
      }

      setState(() {
        _isInContacts = !_isInContacts;
      });

      _showSnackbar(
        _isInContacts ? 'User added to contacts' : 'User removed from contacts',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false, bool isError = false, bool isInfo= false}) {
    Color getColor() {
      if (isError) return ProfileViewColors.error;
      if (isSuccess) return ProfileViewColors.success;
      return ProfileViewColors.primary;
    }

    IconData getIcon() {
      if (isError) return Icons.error_outline;
      if (isSuccess) return Icons.check_circle;
      return Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: getColor(),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper method to calculate age from date of birth
  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Helper method to format gender for display
  String _formatGender(String? gender) {
    if (gender == null) return 'Not specified';
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  // Helper method to get gender icon
  IconData _getGenderIcon(String? gender) {
    if (gender == null) return Icons.person;
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'other':
        return Icons.transgender;
      case 'prefer_not_to_say':
        return Icons.help_outline;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isCurrentUser = authController.currentUser?.id == widget.userId;

    // Get age and gender from user data
    final dateOfBirth = _userData?['dateOfBirth'] != null
        ? (_userData!['dateOfBirth'] as Timestamp).toDate()
        : null;
    final age = _calculateAge(dateOfBirth);
    final gender = _userData?['gender'] as String?;

    return Scaffold(
      backgroundColor: ProfileViewColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ProfileViewColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: ProfileViewColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [ProfileViewColors.primary, ProfileViewColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'User Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          if (!isCurrentUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: ProfileViewColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton(
                icon: Icon(Icons.more_vert, color: ProfileViewColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isBlocked ? ProfileViewColors.success.withOpacity(0.1) : ProfileViewColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isBlocked ? Icons.block_flipped : Icons.block,
                            color: _isBlocked ? ProfileViewColors.success : ProfileViewColors.error,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_isBlocked ? 'Unblock User' : 'Block User'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ProfileViewColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.flag, color: ProfileViewColors.warning, size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Text('Report User'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'contact',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isInContacts ? ProfileViewColors.accent.withOpacity(0.1) : ProfileViewColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isInContacts ? Icons.star : Icons.star_border,
                            color: _isInContacts ? ProfileViewColors.accent : ProfileViewColors.textSecondary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_isInContacts ? 'Remove from Contacts' : 'Add to Contacts'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'block':
                      _toggleBlockUser();
                      break;
                    case 'report':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportScreen(
                            userId: widget.userId,
                            userName: _userData?['name'] ?? 'User',
                            userImage: _userData?['photoUrl'],
                            reportType: ReportType.user,
                          ),
                        ),
                      );
                      break;
                    case 'contact':
                      _toggleContact();
                      break;
                  }
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _userData == null
          ? _buildErrorState('User not found')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header with Neon Glow
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // 🔥 NEW: Age and Gender Section
            if (age != null || gender != null)
              _buildAgeGenderSection(age, gender),
            if (age != null || gender != null) const SizedBox(height: 16),

            // Action Buttons (if not current user)
            if (!isCurrentUser) ...[
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],

            // Bio Section
            if (_userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty)
              _buildInfoCard(
                title: 'About',
                icon: Icons.info_outline,
                gradientColors: [ProfileViewColors.primary, ProfileViewColors.secondary],
                child: Text(
                  _userData!['bio'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6,
                    color: ProfileViewColors.textPrimary,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Stats and Level Section
            _buildStatsSection(),
            const SizedBox(height: 16),

            // Interests Section
            if (_userData!['interests'] != null && (_userData!['interests'] as List).isNotEmpty)
              _buildInfoCard(
                title: 'Interests',
                icon: Icons.interests,
                gradientColors: [ProfileViewColors.tertiary, ProfileViewColors.success],
                child: _buildInterestsSection(),
              ),
            const SizedBox(height: 16),

            // Recent Trips Section
            if (_userTrips.isNotEmpty)
              _buildInfoCard(
                title: 'Recent Trips',
                icon: Icons.travel_explore,
                gradientColors: [ProfileViewColors.secondary, ProfileViewColors.accent],
                child: _buildRecentTripsSection(),
              ),
            const SizedBox(height: 16),

            // Mutual Groups Section
            if (_mutualGroups.isNotEmpty)
              _buildInfoCard(
                title: 'Mutual Groups',
                icon: Icons.group,
                gradientColors: [ProfileViewColors.lavender, ProfileViewColors.primary],
                child: _buildMutualGroupsSection(),
              ),
            const SizedBox(height: 24),

            // Block Status Warning
            if (_isBlocked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ProfileViewColors.error.withOpacity(0.1), ProfileViewColors.secondary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ProfileViewColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ProfileViewColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block, color: ProfileViewColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have blocked this user. You will not receive any messages from them.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ProfileViewColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 NEW: Age and Gender Section Widget
  Widget _buildAgeGenderSection(int? age, String? gender) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProfileViewColors.primary.withOpacity(0.1),
            ProfileViewColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ProfileViewColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gender != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProfileViewColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getGenderIcon(gender),
                size: 18,
                color: ProfileViewColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatGender(gender),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ProfileViewColors.textPrimary,
              ),
            ),
          ],
          if (age != null && gender != null) ...[
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: ProfileViewColors.border,
            ),
          ],
          if (age != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProfileViewColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cake,
                size: 18,
                color: ProfileViewColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$age years old',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ProfileViewColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ProfileViewColors.primary.withOpacity(0.1), ProfileViewColors.secondary.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ProfileViewColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ProfileViewColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ProfileViewColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 64, color: ProfileViewColors.error),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ProfileViewColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isVerified = _userData?['isVerifiedTraveler'] == true;

    return Column(
      children: [
        // Animated Avatar with Glow
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    ProfileViewColors.primary,
                    ProfileViewColors.secondary,
                    ProfileViewColors.tertiary,
                  ],
                  stops: [0.3, 0.6, 0.9],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ProfileViewColors.primary.withOpacity(0.3 * _pulseAnimationController.value),
                    blurRadius: 20,
                    spreadRadius: 5 * _pulseAnimationController.value,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: ProfileViewColors.background,
                backgroundImage: _userData!['photoUrl'] != null
                    ? CachedNetworkImageProvider(_userData!['photoUrl'])
                    : null,
                child: _userData!['photoUrl'] == null
                    ? Text(
                  _userData!['name']?[0].toUpperCase() ?? '?',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: ProfileViewColors.primary,
                  ),
                )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          _userData!['name'] ?? 'Unknown User',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ProfileViewColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Email
        Text(
          _userData!['email'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: ProfileViewColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Location
        if (_userData!['location'] != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: ProfileViewColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _userData!['location'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: ProfileViewColors.textSecondary,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Verification Badge
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ProfileViewColors.success.withOpacity(0.1), ProfileViewColors.tertiary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: ProfileViewColors.success.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: ProfileViewColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verified Traveler',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ProfileViewColors.success,
                  ),
                ),
              ],
            ),
          ),

        // Join Date
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 14, color: ProfileViewColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Joined ${_formatJoinDate(_userData!['createdAt'])}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: ProfileViewColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ProfileViewColors.primary, ProfileViewColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ProfileViewColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isBlocked ? null : _startChat,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.message, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isBlocked
                    ? [ProfileViewColors.success, ProfileViewColors.tertiary]
                    : [ProfileViewColors.error, ProfileViewColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isBlocked ? ProfileViewColors.success.withOpacity(0.3) : ProfileViewColors.error.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleBlockUser,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBlocked ? Icons.block_flipped : Icons.block,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isBlocked ? 'Unblock' : 'Block',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('trips')
          .where('hostId', isEqualTo: widget.userId)
          .get(),
      builder: (context, snapshot) {
        final tripCount = snapshot.data?.docs.length ?? 0;
        final level = LevelSystem.getLevel(tripCount);
        final progress = LevelSystem.getProgress(tripCount);
        final nextLevel = LevelSystem.getNextLevel(tripCount);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ProfileViewColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Stats Row (Trips and Level only - removed rating)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Trips',
                    value: '$tripCount',
                    color: ProfileViewColors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: ProfileViewColors.border,
                  ),
                  _buildStatItem(
                    label: 'Level',
                    value: level['name'],
                    color: level['color'],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Level Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: level['color'],
                        ),
                      ),
                      if (nextLevel != null)
                        Text(
                          nextLevel['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ProfileViewColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: ProfileViewColors.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [level['color'], ProfileViewColors.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: level['color'].withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (nextLevel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${tripCount}/${nextLevel['minTrips']} trips to reach ${nextLevel['name']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: ProfileViewColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: ProfileViewColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ProfileViewColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    final interests = _userData!['interests'] as List;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ProfileViewColors.primary.withOpacity(0.1), ProfileViewColors.secondary.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: ProfileViewColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            interest,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ProfileViewColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTripsSection() {
    return Column(
      children: _userTrips.map((trip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ProfileViewColors.primary, ProfileViewColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: trip['images'] != null && (trip['images'] as List).isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: trip['images'][0],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                    errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.white),
                  )
                      : const Icon(Icons.image, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ProfileViewColors.textPrimary,
                      ),
                    ),
                    Text(
                      trip['destination'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ProfileViewColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ProfileViewColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${trip['currentMembers'] ?? 0}/${trip['maxMembers'] ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ProfileViewColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMutualGroupsSection() {
    return Column(
      children: _mutualGroups.map((group) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                  groupId: group['id'],
                  groupName: group['name'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ProfileViewColors.lavender, ProfileViewColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: group['image'] != null
                        ? CachedNetworkImage(
                      imageUrl: group['image'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => const Icon(Icons.group, color: Colors.white),
                    )
                        : const Icon(Icons.group, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ProfileViewColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: ProfileViewColors.textSecondary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionDialog({
    required String title,
    required String message,
    required String actionText,
    required Color actionColor,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  actionText == 'Block' ? Icons.block :
                  actionText == 'Unblock' ? Icons.block_flipped :
                  actionText == 'Report' ? Icons.flag : Icons.warning,
                  color: actionColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ProfileViewColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: ProfileViewColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ProfileViewColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [actionColor, actionColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          actionText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat() {
    _showSnackbar('Chat feature coming soon!', isInfo: true);
  }

  String _formatJoinDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      final joinDate = date.toDate();
      final now = DateTime.now();
      final difference = now.difference(joinDate);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else {
        return 'Today';
      }
    }
    return 'Unknown';
  }
}