import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/safety/presentation/report_screen.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';

import '../../safety/data/report_model.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isBlocked = false;
  bool _isInContacts = false;
  List<Map<String, dynamic>> _userTrips = [];
  List<Map<String, dynamic>> _mutualGroups = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBlockStatus();
    _checkContactStatus();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile
      final userDoc = await _firebaseService.usersCollection
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      // Get user's recent trips
      final tripsSnapshot = await _firebaseService.tripsCollection
          .where('hostId', isEqualTo: widget.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      _userTrips = tripsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Get mutual groups
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

    final action = _isBlocked ? 'unblock' : 'block';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          _isBlocked
              ? 'Are you sure you want to unblock this user?'
              : 'Are you sure you want to block this user? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: _isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(_isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBlocked
                ? 'User unblocked successfully'
                : 'User blocked successfully',
          ),
          backgroundColor: _isBlocked ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isInContacts
                ? 'User added to contacts'
                : 'User removed from contacts',
          ),
          backgroundColor: const Color(0xFF00D4AA),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if there's an existing direct message group
    final existingGroups = await _firebaseService.groupsCollection
        .where('memberIds', arrayContains: currentUser.uid)
        .get();

    String? existingGroupId;
    for (var doc in existingGroups.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['memberIds'] ?? []);
      if (members.length == 2 && members.contains(widget.userId)) {
        existingGroupId = doc.id;
        break;
      }
    }

  //   if (existingGroupId != null) {
  //     // Navigate to existing chat
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => GroupChatScreen(
  //           groupId: existingGroupId,
  //           groupName: _userData?['name'] ?? 'Chat',
  //         ),
  //       ),
  //     );
  //   } else {
  //     // Create new direct message group
  //     final newGroup = GroupModel(
  //       id: '',
  //       name: _userData?['name'] ?? 'Chat',
  //       description: 'Direct message',
  //       createdBy: currentUser.uid,
  //       createdByName: currentUser.displayName ?? 'User',
  //       type: GroupType.private,
  //       maxMembers: 2,
  //       currentMembers: 2,
  //       memberIds: [currentUser.uid, widget.userId],
  //       memberRoles: {
  //         currentUser.uid: MemberRole.admin,
  //         widget.userId: MemberRole.member,
  //       },
  //       adminIds: [currentUser.uid],
  //       isJoinApprovalRequired: false,
  //       isChatEnabled: true,
  //     );
  //
  //     final groupId = await _firebaseService.createGroup(newGroup);
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => GroupChatScreen(
  //           groupId: groupId,
  //           groupName: _userData?['name'] ?? 'Chat',
  //         ),
  //       ),
  //     );
  //   }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isCurrentUser = authController.currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isCurrentUser)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        _isBlocked ? Icons.block_flipped : Icons.block,
                        color: _isBlocked ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_isBlocked ? 'Unblock User' : 'Block User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Report User'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'contact',
                  child: Row(
                    children: [
                      Icon(
                        _isInContacts ? Icons.star : Icons.star_border,
                        color: _isInContacts ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Action Buttons (if not current user)
            if (!isCurrentUser) ...[
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],

            // Bio Section
            if (_userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty)
              _buildSection(
                'About',
                Text(
                  _userData!['bio'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Stats
            _buildStatsSection(),
            const SizedBox(height: 16),

            // Interests
            if (_userData!['interests'] != null && (_userData!['interests'] as List).isNotEmpty)
              _buildInterestsSection(),
            const SizedBox(height: 16),

            // Recent Trips
            if (_userTrips.isNotEmpty)
              _buildRecentTripsSection(),
            const SizedBox(height: 16),

            // Mutual Groups
            if (_mutualGroups.isNotEmpty)
              _buildMutualGroupsSection(),
            const SizedBox(height: 24),

            // Block Status Warning
            if (_isBlocked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have blocked this user. You will not receive any messages from them.',
                        style: TextStyle(color: Colors.red),
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

  Widget _buildProfileHeader() {
    final isVerified = _userData?['isVerifiedTraveler'] == true;

    return Column(
      children: [
        // Profile Image
        CircleAvatar(
          radius: 60,
          backgroundImage: _userData!['photoUrl'] != null
              ? CachedNetworkImageProvider(_userData!['photoUrl'])
              : const NetworkImage(
            'https://th.bing.com/th/id/OIP.0AKX_YJS6w3y215EcZ-WAAAAAA?w=151&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
          ),
          child: _userData!['photoUrl'] == null
              ? Text(
            _userData!['name']?[0].toUpperCase() ?? '?',
            style: const TextStyle(fontSize: 30),
          )
              : null,
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          _userData!['name'] ?? 'Unknown User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // Email
        Text(
          _userData!['email'] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        // Location
        if (_userData!['location'] != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                _userData!['location'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Verification Badge
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: Color(0xFF00D4AA),
                ),
                SizedBox(width: 8),
                Text(
                  'Verified Traveler',
                  style: TextStyle(
                    color: Color(0xFF00D4AA),
                    fontWeight: FontWeight.w600,
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
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              'Joined ${_formatJoinDate(_userData!['createdAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
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
          child: ElevatedButton.icon(
            onPressed: _isBlocked ? null : _startChat,
            icon: const Icon(Icons.message),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleBlockUser,
            icon: Icon(
              _isBlocked ? Icons.block_flipped : Icons.block,
              color: _isBlocked ? Colors.green : Colors.red,
            ),
            label: Text(_isBlocked ? 'Unblock' : 'Block'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isBlocked ? Colors.green : Colors.red,
              side: BorderSide(
                color: _isBlocked ? Colors.green : Colors.red,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('trips')
                  .where('hostId', isEqualTo: widget.userId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildUserStat('Trips', 'Trips');
                }

                return _buildUserStat(
                  'Trips',
                  snapshot.data!.docs.length.toString(),
                );
              },
            ),
            _buildStatItem('Reviews', '${_userData!['totalReviews'] ?? 0}'),
            _buildStatItem('Rating', '${_userData!['rating'] ?? 5}/5'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D2B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6E7A8A),
          ),
        ),
      ],
    );
  }
  Widget _buildUserStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D2B),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF6E7A8A))),
      ],
    );
  }
  Widget _buildInterestsSection() {
    final interests = _userData!['interests'] as List;

    return _buildSection(
      'Interests',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              interest,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentTripsSection() {
    return _buildSection(
      'Recent Trips',
      Column(
        children: _userTrips.map((trip) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: trip['images'] != null && (trip['images'] as List).isNotEmpty
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(trip['images'][0]),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: trip['images'] == null || (trip['images'] as List).isEmpty
                  ? const Icon(Icons.image, color: Colors.grey)
                  : null,
            ),
            title: Text(
              trip['title'] ?? 'Untitled',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(trip['destination'] ?? 'Unknown'),
            trailing: Text(
              '${trip['currentMembers'] ?? 0}/${trip['maxMembers'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMutualGroupsSection() {
    return _buildSection(
      'Mutual Groups',
      Column(
        children: _mutualGroups.map((group) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: group['image'] != null
                  ? CachedNetworkImageProvider(group['image'])
                  : null,
              child: group['image'] == null
                  ? Text(group['name'][0].toUpperCase())
                  : null,
            ),
            title: Text(group['name']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
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