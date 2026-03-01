import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:buddygoapp/features/safety/presentation/report_screen.dart';
import 'package:buddygoapp/features/user/presentation/user_profile_view_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';
import 'package:buddygoapp/features/user/presentation/profile_screen.dart';

import '../../safety/data/report_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.id;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Online Users
          _buildOnlineUsersSection(),
          const Divider(),
          // Chat List from Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.groupsCollection
                  .where('memberIds', arrayContains: currentUserId)
                  .where('isActive', isEqualTo: true)
                  .orderBy('lastActivityAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = snapshot.data?.docs ?? [];

                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join a trip or create one to start chatting',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateGroupScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B61FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Create New Trip'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final doc = groups[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Parse the group data
                    final group = GroupModel.fromJson({...data, 'id': doc.id});

                    // Get real last message info from Firestore
                    return FutureBuilder<QuerySnapshot>(
                      future: _firebaseService.chatsCollection
                          .where('groupId', isEqualTo: group.id)
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, lastMessageSnapshot) {
                        if (lastMessageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ChatListItem(
                            group: group,
                            lastMessage: null,
                            currentUserId: currentUserId,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                    groupId: group.id,
                                    groupName: group.name,
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        Map<String, dynamic>? lastMessageData;
                        int unreadCount = 0;

                        if (lastMessageSnapshot.hasData &&
                            lastMessageSnapshot.data!.docs.isNotEmpty) {
                          final lastMsgDoc =
                              lastMessageSnapshot.data!.docs.first;
                          lastMessageData =
                              lastMsgDoc.data() as Map<String, dynamic>;

                          // Get unread count (messages not read by current user)
                          final readBy = List<String>.from(
                            lastMessageData['readBy'] ?? [],
                          );
                          if (!readBy.contains(currentUserId) &&
                              lastMessageData['userId'] != currentUserId) {
                            unreadCount = 1;
                          }
                        }

                        return ChatListItem(
                          group: group,
                          lastMessage: lastMessageData,
                          unreadCount: unreadCount,
                          currentUserId: currentUserId,
                          onTap: () {
                            // Mark messages as read when opening chat
                            _markMessagesAsRead(group.id, currentUserId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                  groupId: group.id,
                                  groupName: group.name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        backgroundColor: const Color(0xFF7B61FF),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Future<void> _markMessagesAsRead(String groupId, String userId) async {
    try {
      final unreadMessages = await _firebaseService.chatsCollection
          .where('groupId', isEqualTo: groupId)
          .where('readBy', arrayContains: userId)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Widget _buildOnlineUsersSection() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users online'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? 'User';
              final photoUrl = data['photoUrl'];
              final userId = users[index].id;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onLongPress: () {
                    _showUserOptions(context, userId, data);
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: photoUrl != null
                                ? CachedNetworkImageProvider(photoUrl)
                                : const NetworkImage(
                                    'https://th.bing.com/th/id/OIP.0AKX_YJS6w3y215EcZ-WAAAAAA?w=151&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
                                  ),
                            child: photoUrl == null
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7B61FF),
                                    ),
                                  )
                                : null,
                          ),
                          // Online indicator
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 ADDED: Block user functionality
  Future<void> _blockUser(String userId) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.currentUser?.id;

    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.usersCollection
                    .doc(currentUserId)
                    .update({
                      'blockedUsers': FieldValue.arrayUnion([userId]),
                    });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error blocking user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  // 🔥 ADDED: Share user profile
  void _shareUserProfile(String userId, String userName) {
    // In a real app, you would use the share package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing profile of $userName'),
        backgroundColor: const Color(0xFF7B61FF),
      ),
    );
  }

  // 🔥 ADDED: Show user options on long press
  void _showUserOptions(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF7B61FF)),
                ),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileViewScreen(userId: userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.block, color: Colors.red),
                ),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(userId);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag, color: Colors.orange),
                ),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        userId: userId,
                        userName: userData['name'] ?? 'User',
                        userImage: userData['photoUrl'],
                        reportType: ReportType.user,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: Colors.blue),
                ),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _shareUserProfile(userId, userData['name'] ?? 'User');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class ChatListItem extends StatelessWidget {
  final GroupModel group;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.group,
    required this.lastMessage,
    this.unreadCount = 0,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: group.coverImage != null
                ? CachedNetworkImageProvider(group.coverImage!)
                : const AssetImage('lib/assets/images/logo1.png')
                      as ImageProvider,
            child: group.coverImage == null
                ? Text(
                    group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B61FF),
                    ),
                  )
                : null,
          ),
          // Online indicator (simplified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
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
              group.name,
              style: TextStyle(
                fontWeight: unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16,
                color: const Color(0xFF1A1D2B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(
              lastMessage?['timestamp']?.toDate() ?? group.lastActivityAt,
            ),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getLastMessagePreview(),
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                fontWeight: unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${group.currentMembers} members',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (group.isAdmin(currentUserId))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final chatDate = DateTime(time.year, time.month, time.day);

    if (chatDate == today) {
      return DateFormat('h:mm a').format(time);
    } else if (chatDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }

  String _getLastMessagePreview() {
    if (lastMessage == null) {
      return 'No messages yet';
    }

    final senderId = lastMessage!['userId'] ?? '';
    final senderName = lastMessage!['userName'] ?? 'Unknown';
    final messageText = lastMessage!['text'] ?? '';

    if (senderId == currentUserId) {
      return 'You: $messageText';
    }
    return '$senderName: $messageText';
  }
}
