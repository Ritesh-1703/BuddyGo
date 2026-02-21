import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'groupId': 'trip_1',
      'groupName': 'Goa Trip Group',
      'lastMessage': 'See you all at the airport!',
      'lastSender': 'Sarah Wilson',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'unreadCount': 3,
      'members': 4,
      'image': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5',
      'isOnline': true,
    },
    {
      'id': '2',
      'groupId': 'trip_2',
      'groupName': 'Himalayan Trek',
      'lastMessage': 'Don\'t forget trekking poles',
      'lastSender': 'Mike Chen',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'unreadCount': 0,
      'members': 6,
      'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4',
      'isOnline': false,
    },
    {
      'id': '3',
      'groupId': 'trip_3',
      'groupName': 'Bali Cultural Trip',
      'lastMessage': 'Temple visit confirmed for tomorrow',
      'lastSender': 'Lisa Park',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 1,
      'members': 3,
      'image': 'https://images.unsplash.com/photo-1537984822441-cff3303b9e3d',
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
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
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
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
          ),
          const Divider(),
          // Chat List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ChatListItem(
                  chat: chat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatScreen(
                          groupId: chat['groupId'],
                          groupName: chat['groupName'],
                        ),
                      ),
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
}

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM dd');

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: CachedNetworkImageProvider(chat['image']),
          ),
          if (chat['isOnline'] as bool)
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
              chat['groupName'],
              style: TextStyle(
                fontWeight: chat['unreadCount'] > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            _formatTime(chat['timestamp'] as DateTime),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chat['unreadCount'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat['unreadCount']}',
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
              '${chat['lastSender']}: ${chat['lastMessage']}',
              style: TextStyle(
                color: chat['unreadCount'] > 0
                    ? Colors.black
                    : Colors.grey[600],
                fontWeight: chat['unreadCount'] > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Text(
        '${chat['members']} members',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
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
}