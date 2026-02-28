import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';

import '../../../core/services/notification_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isSending = false;
  int _onlineCount = 0;
  int _memberCount = 0;

  // Selection mode variables
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
    _messageController.addListener(() {
      setState(() {}); // rebuild when text changes
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final group = await _firebaseService.getGroupById(widget.groupId);
      if (group != null) {
        setState(() {
          _memberCount = group.currentMembers;
          _onlineCount = (group.currentMembers * 0.6).round();
        });
      }
    } catch (e) {
      print('Error loading group info: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    if (user == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      await _firebaseService.sendMessage(
        groupId: widget.groupId,
        userId: user.id,
        userName: user.name ?? 'Anonymous',
        text: messageText,
      );
      final group = await _firebaseService.getGroupById(widget.groupId);
      if (group != null) {
        final otherMembers = group.memberIds
            .where((id) => id != user.id)
            .toList();

        // 🔥 Send push notifications to other members
        await _firebaseService.sendMessageNotification(
          groupId: widget.groupId,
          groupName: widget.groupName,
          senderName: user.name ?? 'Someone',
          message: messageText,
          recipientUserIds: otherMembers,
          senderId: user.id,
        );
      }

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: const Color(0xFFFF647C),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  // In your _sendMessage method
  //   Future<void> _sendMessage() async {
  //     if (_messageController.text.trim().isEmpty) return;
  //
  //     final authController = Provider.of<AuthController>(context, listen: false);
  //     final user = authController.currentUser;
  //
  //     if (user == null) return;
  //
  //     final messageText = _messageController.text.trim();
  //     _messageController.clear();
  //
  //     try {
  //       // Send message to Firestore
  //       await _firebaseService.sendMessage(
  //         groupId: widget.groupId,
  //         userId: user.id,
  //         userName: user.name ?? 'Anonymous',
  //         text: messageText,
  //       );
  //
  //       // 🔥 Get group members except sender
  //       final group = await _firebaseService.getGroupById(widget.groupId);
  //       if (group != null) {
  //         final otherMembers = group.memberIds.where((id) => id != user.id).toList();
  //
  //         // 🔥 Send push notifications to other members
  //         await NotificationService().sendMessageNotification(
  //           groupId: widget.groupId,
  //           groupName: widget.groupName,
  //           senderName: user.name ?? 'Someone',
  //           message: messageText,
  //           recipientUserIds: otherMembers,
  //           senderId: user.id,
  //         );
  //       }
  //
  //       _scrollToBottom();
  //     } catch (e) {
  //       print('Error sending message: $e');
  //     }
  //   }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Messages'),
        content: Text(
          'Are you sure you want to delete ${_selectedMessageIds.length} message(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF647C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      // Delete each selected message
      for (String messageId in _selectedMessageIds) {
        await _firebaseService.chatsCollection.doc(messageId).delete();
      }

      // Exit selection mode
      _exitSelectionMode();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messages deleted successfully'),
          backgroundColor: Color(0xFF00D4AA),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting messages: $e'),
          backgroundColor: const Color(0xFFFF647C),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.id;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Messages Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getChatMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to say hello!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final messageId = doc.id;
                    final isMe = data['userId'] == currentUserId;
                    final isSelected = _selectedMessageIds.contains(messageId);

                    return GestureDetector(
                      onLongPress: isMe
                          ? () => _toggleSelection(messageId)
                          : null,
                      onTap: _isSelectionMode && isMe
                          ? () => _toggleSelection(messageId)
                          : null,
                      child: Container(
                        color: isSelected
                            ? const Color(0xFF7B61FF).withOpacity(0.1)
                            : null,
                        child: ChatBubble(
                          message: ChatMessage(
                            id: doc.id,
                            senderId: data['userId'] ?? '',
                            senderName: data['userName'] ?? 'Unknown',
                            senderImage: data['userImage'],
                            text: data['text'] ?? '',
                            timestamp:
                                data['timestamp']?.toDate() ?? DateTime.now(),
                            isMe: isMe,
                          ),
                          isSelected: isSelected,
                          onLongPress: isMe
                              ? () => _toggleSelection(messageId)
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Section (hidden in selection mode)
          if (!_isSelectionMode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Message Input
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Icon(Icons.attach_file, color: Colors.grey[500]),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  // Send Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _messageController.text.isNotEmpty
                            ? const Color(0xFF7B61FF)
                            : const Color(0xFF7B61FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    onPressed: _messageController.text.isNotEmpty
                        ? _sendMessage
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.groupName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '$_onlineCount online • $_memberCount members',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showGroupInfo(context);
          },
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} selected',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF647C)),
          onPressed: _deleteSelectedMessages,
        ),
      ],
    );
  }

  void _showGroupInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Group Info',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF7B61FF)),
              title: const Text('Members'),
              subtitle: Text('$_memberCount members in this group'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to members list
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Color(0xFFFF647C)),
              title: const Text('Report Group'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Color(0xFFFF647C)),
              title: const Text('Leave Group'),
              onTap: () {
                Navigator.pop(context);
                _showLeaveGroupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Group'),
        content: const Text(
          'Are you sure you want to report this group? '
          'Our team will review it within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group reported successfully'),
                  backgroundColor: Color(0xFF00D4AA),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF647C),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? '
          'You will no longer receive messages from this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authController = Provider.of<AuthController>(
                context,
                listen: false,
              );
              final userId = authController.currentUser?.id;

              if (userId != null) {
                try {
                  await _firebaseService.leaveGroup(widget.groupId, userId);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to chat list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You left the group'),
                        backgroundColor: Color(0xFFFF647C),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFFF647C),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF647C),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderImage != null
                  ? CachedNetworkImageProvider(message.senderImage!)
                  : null,
              child: message.senderImage == null
                  ? Text(message.senderName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF7B61FF), width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: message.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!message.isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6E7A8A),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isMe
                            ? (isSelected
                                  ? const Color(0xFF7B61FF).withOpacity(0.7)
                                  : const Color(0xFF7B61FF))
                            : Colors.grey[100],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: message.isMe
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: message.isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isMe
                              ? Colors.white
                              : const Color(0xFF1A1D2B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFA0A8B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
          if (message.isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7B61FF),
              child: const Text(
                'Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
