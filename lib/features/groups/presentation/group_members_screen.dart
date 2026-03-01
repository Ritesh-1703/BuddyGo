import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';
import 'package:buddygoapp/features/user/presentation/user_profile_view_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _moderators = [];
  List<Map<String, dynamic>> _onlineMembers = [];

  bool _isLoading = true;
  String? _currentUserId;
  bool _isCurrentUserAdmin = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      _currentUserId = authController.currentUser?.id;

      // Get group details
      final group = await _firebaseService.getGroupById(widget.groupId);
      if (group == null) return;

      // Check if current user is admin
      _isCurrentUserAdmin = group.isAdmin(_currentUserId ?? '');

      // Get all member IDs
      final memberIds = group.memberIds;

      // Fetch user details for each member
      final List<Map<String, dynamic>> membersList = [];

      for (String userId in memberIds) {
        final userDoc = await _firebaseService.usersCollection.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Get last active status (simplified - you can enhance this)
          final lastActive = userData['lastActive'] != null
              ? (userData['lastActive'] as Timestamp).toDate()
              : null;

          final isOnline = lastActive != null &&
              DateTime.now().difference(lastActive).inMinutes < 5;

          final memberInfo = {
            'id': userId,
            'name': userData['name'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'photoUrl': userData['photoUrl'],
            'bio': userData['bio'],
            'isVerified': userData['isVerifiedTraveler'] == true,
            'isOnline': isOnline,
            'lastActive': lastActive,
            'role': _getUserRole(group, userId),
            'joinedAt': userData['createdAt'] ?? Timestamp.now(),
            'totalTrips': userData['totalTrips'] ?? 0,
            'rating': userData['rating'] ?? 5,
          };

          membersList.add(memberInfo);

          // Categorize by role
          if (group.isAdmin(userId)) {
            _admins.add(memberInfo);
          } else if (group.isModerator(userId)) {
            _moderators.add(memberInfo);
          }

          // Track online members
          if (isOnline) {
            _onlineMembers.add(memberInfo);
          }
        }
      }

      // Sort members: online first, then alphabetically
      membersList.sort((a, b) {
        if (a['isOnline'] && !b['isOnline']) return -1;
        if (!a['isOnline'] && b['isOnline']) return 1;
        return (a['name'] as String).compareTo(b['name']);
      });

      setState(() {
        _members = membersList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getUserRole(GroupModel group, String userId) {
    if (group.isAdmin(userId)) return 'Admin';
    if (group.isModerator(userId)) return 'Moderator';
    return 'Member';
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF7B61FF);
      case 'Moderator':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;

    return _members.where((member) {
      final name = member['name'].toString().toLowerCase();
      final email = member['email'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _currentTabMembers {
    switch (_tabController.index) {
      case 0: // All Members
        return _filteredMembers;
      case 1: // Admins & Moderators
        return _filteredMembers.where((m) =>
        m['role'] == 'Admin' || m['role'] == 'Moderator'
        ).toList();
      case 2: // Online
        return _filteredMembers.where((m) => m['isOnline']).toList();
      default:
        return _filteredMembers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2B),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Members',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_members.length} members • ${_onlineMembers.length} online',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF7B61FF),
                labelColor: const Color(0xFF7B61FF),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'All (${_members.length})'),
                  Tab(text: 'Admins (${_admins.length + _moderators.length})'),
                  Tab(text: 'Online (${_onlineMembers.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildMembersList(),
          _buildMembersList(),
          _buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _currentTabMembers;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0
                  ? Icons.people_outline
                  : _tabController.index == 1
                  ? Icons.admin_panel_settings
                  : Icons.circle_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No members found'
                  : _tabController.index == 1
                  ? 'No admins found'
                  : 'No members online',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isCurrentUser = member['id'] == _currentUserId;
        final role = member['role'];
        final roleColor = _getRoleColor(role);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: member['photoUrl'] != null
                      ? CachedNetworkImageProvider(member['photoUrl'])
                      : null,
                  child: member['photoUrl'] == null
                      ? Text(
                    member['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7B61FF),
                    ),
                  )
                      : null,
                ),
                if (member['isVerified'])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                if (member['isOnline'])
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D2B),
                    ),
                  ),
                ),
                if (role != 'Member')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                if (isCurrentUser)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.travel_explore,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${member['totalTrips']} trips',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${member['rating']}/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (member['bio'] != null && member['bio'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      member['bio'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            trailing: _buildActionButton(member, isCurrentUser),
            onTap: () {
              if (!isCurrentUser) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileViewScreen(
                      userId: member['id'],
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton(Map<String, dynamic> member, bool isCurrentUser) {
    if (isCurrentUser) return const SizedBox();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'message':
            _startDirectMessage(member['id'], member['name']);
            break;
          case 'view_profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(
                  userId: member['id'],
                ),
              ),
            );
            break;
          case 'make_admin':
            if (_isCurrentUserAdmin) {
              _showMakeAdminDialog(member['id'], member['name']);
            }
            break;
          case 'remove':
            if (_isCurrentUserAdmin) {
              _showRemoveMemberDialog(member['id'], member['name']);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'message',
          child: Row(
            children: [
              Icon(Icons.message, size: 18, color: Color(0xFF7B61FF)),
              SizedBox(width: 8),
              Text('Send Message'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view_profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('View Profile'),
            ],
          ),
        ),
        if (_isCurrentUserAdmin && member['role'] != 'Admin') ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'make_admin',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF7B61FF)),
                SizedBox(width: 8),
                Text('Make Admin'),
              ],
            ),
          ),
        ],
        if (_isCurrentUserAdmin && member['role'] != 'Admin') ...[
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.remove_circle, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove from Group'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startDirectMessage(String userId, String userName) async {
    // TODO: Implement direct message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with $userName...'),
        backgroundColor: const Color(0xFF7B61FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showMakeAdminDialog(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Admin'),
        content: Text('Are you sure you want to make $userName an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7B61FF),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement make admin functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName is now an admin'),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRemoveMemberDialog(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.leaveGroup(widget.groupId, userId);
        _loadMembers(); // Reload members list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName removed from group'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Members Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D2B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This group has no members yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}