import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'group_members_screen.dart';

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

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isSending = false;
  int _onlineCount = 0;
  int _memberCount = 0;
  bool _isEmojiPickerVisible = false;

  // 🔥 FIXED: Use ValueNotifier instead of multiple streams
  final ValueNotifier<int> _onlineCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _memberCountNotifier = ValueNotifier<int>(0);

  // Selection mode variables
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimationController.forward();

    // Initialize real-time counts
    _initializeCounts();

    _messageController.addListener(() {
      setState(() {});
    });

    // Add focus listener to hide emoji picker when keyboard is closed
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isEmojiPickerVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeAnimationController.dispose();
    _focusNode.dispose();
    _onlineCountNotifier.dispose();
    _memberCountNotifier.dispose();
    super.dispose();
  }

  // 🔥 FIXED: Use single calls instead of streams
  void _initializeCounts() {
    // Get total members count from group document
    _firebaseService.getGroupById(widget.groupId).then((group) {
      if (group != null && mounted) {
        _memberCount = group.currentMembers;
        _memberCountNotifier.value = group.currentMembers;
        // Set online count as percentage of members
        _onlineCount = (group.currentMembers * 0.6).round();
        _onlineCountNotifier.value = (group.currentMembers * 0.6).round();
        setState(() {});
      }
    });

    // Update online count periodically (simulated)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _onlineCount = (_memberCount * 0.6).round();
        _onlineCountNotifier.value = (_memberCount * 0.6).round();
        setState(() {});
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    if (user == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isEmojiPickerVisible = false);

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

        await _firebaseService.sendMessageNotification(
          groupId: widget.groupId,
          groupName: widget.groupName,
          senderId: user.id,
          senderName: user.name ?? 'Someone',
          message: messageText,
          recipientUserIds: otherMembers,
        );
      }

      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF647C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
    );
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      for (String messageId in _selectedMessageIds) {
        await _firebaseService.chatsCollection.doc(messageId).delete();
      }

      _exitSelectionMode();
      _showSuccessSnackbar('Messages deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Error deleting messages: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildDeleteConfirmationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                  color: const Color(0xFFFF647C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFF647C),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Messages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D2B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${_selectedMessageIds.length} message(s)? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6E7A8A),
                  fontSize: 15,
                  height: 1.4,
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF647C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      if (_isEmojiPickerVisible) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Messages Stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getChatMessages(widget.groupId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return _buildEmptyState();
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
                        final showAvatar = index == 0 ||
                            messages[index - 1].get('userId') != data['userId'];

                        return GestureDetector(
                          onLongPress: isMe
                              ? () => _toggleSelection(messageId)
                              : null,
                          onTap: _isSelectionMode && isMe
                              ? () => _toggleSelection(messageId)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            color: isSelected
                                ? const Color(0xFF7B61FF).withOpacity(0.1)
                                : Colors.transparent,
                            margin: EdgeInsets.only(
                              top: index > 0 &&
                                  messages[index - 1].get('userId') == data['userId']
                                  ? 4
                                  : 16,
                            ),
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
                              showAvatar: showAvatar,
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

              // Typing Indicator
              if (_isSending)
                _buildTypingIndicator(),

              // Input Section
              if (!_isSelectionMode)
                _buildInputSection(),

              // Emoji Picker
              if (_isEmojiPickerVisible)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: EmojiPicker(
                    textEditingController: _messageController,
                    onEmojiSelected: (category, emoji) {
                      _messageController
                        ..text += emoji.emoji
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _messageController.text.length),
                        );
                    },
                    config: const Config(
                      height: 300,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        columns: 7,
                        emojiSizeMax: 32,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        indicatorColor: Color(0xFF7B61FF),
                        iconColor: Colors.grey,
                        iconColorSelected: Color(0xFF7B61FF),
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        enabled: true,
                        backgroundColor: Colors.white,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sending message...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D2B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFF6E7A8A),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text('Try Again'),
          ),
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
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading messages...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D2B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to start the conversation!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment Button
              _buildIconButton(
                icon: Icons.attach_file_outlined,
                onPressed: () {
                  // TODO: Implement attachment
                },
              ),

              const SizedBox(width: 8),

              // Message Input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _messageController.text.isNotEmpty
                          ? const Color(0xFF7B61FF).withOpacity(0.3)
                          : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1D2B),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),

                      // Emoji Button
                      _buildIconButton(
                        icon: _isEmojiPickerVisible
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        onPressed: _toggleEmojiPicker,
                        color: _isEmojiPickerVisible
                            ? const Color(0xFF7B61FF)
                            : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color ?? Colors.grey[600],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final isEnabled = _messageController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isEnabled
              ? const LinearGradient(
            colors: [Color(0xFF7B61FF), Color(0xFF9D8CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.grey[300]!, Colors.grey[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isEnabled
              ? [
            BoxShadow(
              color: const Color(0xFF7B61FF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _sendMessage : null,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.send,
                color: isEnabled ? Colors.white : Colors.grey[600],
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 FIXED: AppBar with ValueListenableBuilder instead of StreamBuilder
  AppBar _buildNormalAppBar() {
    return AppBar(
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
      title: Row(
        children: [
          // Group avatar with gradient
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF9D8CFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 🔥 FIXED: Use ValueListenableBuilder instead of StreamBuilder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<int>(
                  valueListenable: _onlineCountNotifier,
                  builder: (context, onlineCount, child) {
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: onlineCount > 0
                                ? const Color(0xFF00D4AA)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$onlineCount online',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6E7A8A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<int>(
                          valueListenable: _memberCountNotifier,
                          builder: (context, memberCount, child) {
                            return Text(
                              '$memberCount',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6E7A8A),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, size: 20),
            ),
            onPressed: () => _showGroupInfo(context),
          ),
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
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
          child: const Icon(Icons.close, size: 20),
        ),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} selected',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D2B),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF647C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFFF647C),
                size: 20,
              ),
            ),
            onPressed: _deleteSelectedMessages,
          ),
        ),
      ],
    );
  }

  void _showGroupInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF9D8CFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D2B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<int>(
                          valueListenable: _memberCountNotifier,
                          builder: (context, memberCount, child) {
                            return ValueListenableBuilder<int>(
                              valueListenable: _onlineCountNotifier,
                              builder: (context, onlineCount, child) {
                                return Text(
                                  '$memberCount members • $onlineCount online',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6E7A8A),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Group Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2B),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.people_outline,
                title: 'View All Members',
                subtitle: 'See who\'s in this group',
                color: const Color(0xFF7B61FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupMembersScreen(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildInfoTile(
                icon: Icons.report_outlined,
                title: 'Report Group',
                subtitle: 'Report inappropriate content',
                color: const Color(0xFFFF647C),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
              const Divider(height: 24),
              _buildInfoTile(
                icon: Icons.exit_to_app,
                title: 'Leave Group',
                subtitle: 'Permanently leave this group',
                color: const Color(0xFFFF647C),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveGroupDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D2B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF647C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFFF647C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Report Group',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to report this group? '
                      'Our team will review it within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6E7A8A),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSuccessSnackbar('Group reported successfully');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF647C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF647C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Color(0xFFFF647C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leave Group',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to leave this group? '
                      'You will no longer receive messages from this group.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6E7A8A),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
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
                                Navigator.pop(context);
                                Navigator.pop(context);
                                _showSuccessSnackbar('You left the group');
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              _showErrorSnackbar('Error: $e');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF647C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Leave',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
  final bool showAvatar;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.isSelected = false,
    this.showAvatar = true,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            if (showAvatar)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF9D8CFF)],
                    )
                        : null,
                  ),
                  padding: EdgeInsets.all(isSelected ? 2 : 0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: message.senderImage != null
                        ? CachedNetworkImageProvider(message.senderImage!)
                        : null,
                    child: message.senderImage == null
                        ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF6E7A8A),
                      ),
                    )
                        : null,
                  ),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                margin: EdgeInsets.only(
                  left: message.isMe ? 50 : 0,
                  right: !message.isMe ? 50 : 0,
                ),
                child: Column(
                  crossAxisAlignment: message.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!message.isMe && showAvatar)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: message.isMe
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF7B61FF),
                            Color(0xFF9D8CFF)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: message.isMe
                            ? null
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: message.isMe
                              ? const Radius.circular(20)
                              : const Radius.circular(4),
                          bottomRight: message.isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                        border: isSelected
                            ? Border.all(
                          color: const Color(0xFF7B61FF),
                          width: 2,
                        )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isMe
                              ? Colors.white
                              : const Color(0xFF1A1D2B),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(message.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA0A8B8),
                            ),
                          ),
                          if (message.isMe) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7B61FF).withOpacity(0.1)
                                    : const Color(0xFF00D4AA).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.done_all,
                                size: 12,
                                color: isSelected
                                    ? const Color(0xFF7B61FF)
                                    : const Color(0xFF00D4AA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}