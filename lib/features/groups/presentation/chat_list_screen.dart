import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Map<String, dynamic>> _onlineUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnlineUsers();
  }

  Future<void> _loadOnlineUsers() async {
    // In a real app, you would get online users from Firestore presence system
    // For now, using sample data
    setState(() {
      _isLoading = false;
    });
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
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
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
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
                    final group = GroupModel.fromJson({
                      ...data,
                      'id': doc.id,
                    });

                    // Get last message info (you would get this from a subcollection)
                    // For now, using a placeholder
                    final lastMessage = _getLastMessageInfo(group.id);

                    return ChatListItem(
                      group: group,
                      lastMessage: lastMessage,
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
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF7B61FF),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildOnlineUsersSection() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5, // You would get this from Firestore presence
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: CachedNetworkImageProvider(
                        'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 1}.jpg',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  index == 0 ? 'You' : 'User ${index + 1}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to get last message info
  Map<String, dynamic> _getLastMessageInfo(String groupId) {
    // In a real app, you would query the messages subcollection
    // For now, returning sample data based on groupId
    final now = DateTime.now();

    if (groupId.contains('1')) {
      return {
        'lastMessage': 'See you all at the airport!',
        'lastSender': 'Sarah Wilson',
        'timestamp': now.subtract(const Duration(minutes: 30)),
        'unreadCount': 3,
      };
    } else if (groupId.contains('2')) {
      return {
        'lastMessage': 'Don\'t forget trekking poles',
        'lastSender': 'Mike Chen',
        'timestamp': now.subtract(const Duration(hours: 2)),
        'unreadCount': 0,
      };
    } else {
      return {
        'lastMessage': 'Temple visit confirmed for tomorrow',
        'lastSender': 'Lisa Park',
        'timestamp': now.subtract(const Duration(days: 1)),
        'unreadCount': 1,
      };
    }
  }
}

class ChatListItem extends StatelessWidget {
  final GroupModel group;
  final Map<String, dynamic> lastMessage;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.group,
    required this.lastMessage,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = lastMessage['unreadCount'] ?? 0;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: group.coverImage != null
                ? CachedNetworkImageProvider(group.coverImage!)
                : null,
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
          // Online indicator (you would get this from presence system)
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
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: const Color(0xFF1A1D2B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(lastMessage['timestamp'] as DateTime? ?? group.lastActivityAt),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
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
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
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
    final sender = lastMessage['lastSender'] ?? 'Unknown';
    final message = lastMessage['lastMessage'] ?? 'No messages yet';

    if (sender == 'You' || sender == currentUserId) {
      return 'You: $message';
    }
    return '$sender: $message';
  }
}