import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:badges/badges.dart' as badges;
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart'; // ✅ ADD THIS IMPORT

import 'group_members_screen.dart';
import 'join_requests_screen.dart';

// ==================== CONSTANTS ====================
class ChatColors {
  static const Color primary = Color(0xFF8B5CF6);     // Purple
  static const Color secondary = Color(0xFFFF6B6B);   // Coral
  static const Color tertiary = Color(0xFF4FD1C5);    // Teal
  static const Color accent = Color(0xFFFBBF24);      // Yellow
  static const Color lavender = Color(0xFF9F7AEA);    // Lavender
  static const Color success = Color(0xFF06D6A0);     // Mint Green
  static const Color error = Color(0xFFFF6B6B);       // Coral for errors
  static const Color background = Color(0xFFF0F2FE);  // Light purple tint
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
}

// ==================== GROUP CHAT SCREEN ====================
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
  bool _isEmojiPickerVisible = false;

  // Using ValueNotifier for reactive updates
  final ValueNotifier<int> _onlineCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _memberCountNotifier = ValueNotifier<int>(0);

  // Selection mode variables
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  // ✅ ADD THESE MISSING VARIABLES
  bool _isCurrentUserAdmin = false;
  int _pendingRequestsCount = 0;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _sendButtonAnimationController;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimationController.forward();

    // Initialize real-time counts
    _initializeCounts();

    _messageController.addListener(() {
      setState(() {});
      if (_messageController.text.isNotEmpty) {
        _sendButtonAnimationController.forward();
      } else {
        _sendButtonAnimationController.reverse();
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isEmojiPickerVisible = false;
        });
      }
    });

    // ✅ Listen for group changes to update admin status and pending requests
    _firebaseService.groupsCollection.doc(widget.groupId).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final group = GroupModel.fromJson({...data, 'id': snapshot.id});

        final authController = Provider.of<AuthController>(context, listen: false);
        final currentUserId = authController.currentUser?.id;

        if (currentUserId != null) {
          setState(() {
            _isCurrentUserAdmin = group.isAdmin(currentUserId);
            _pendingRequestsCount = group.pendingRequests
                .where((req) => req.status == RequestStatus.pending)
                .length;
          });
        }
      }
    });
  }
  // Add this method in _GroupChatScreenState
  Future<void> _toggleApprovalRequirement(bool value) async {
    try {
      await _firebaseService.groupsCollection.doc(widget.groupId).update({
        'isJoinApprovalRequired': value,
      });

      _showSnackbar(value
          ? 'Join requests are now required'
          : 'Anyone can now join directly');
    } catch (e) {
      _showSnackbar('Error updating settings', isError: true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    _focusNode.dispose();
    _onlineCountNotifier.dispose();
    _memberCountNotifier.dispose();
    super.dispose();
  }

  void _initializeCounts() {
    _firebaseService.getGroupById(widget.groupId).then((group) {
      if (group != null && mounted) {
        _memberCountNotifier.value = group.currentMembers;
        _onlineCountNotifier.value = (group.currentMembers * 0.6).round();

        // ✅ Check if current user is admin
        final authController = Provider.of<AuthController>(context, listen: false);
        final currentUserId = authController.currentUser?.id;
        if (currentUserId != null) {
          _isCurrentUserAdmin = group.isAdmin(currentUserId);

          // Count pending requests
          _pendingRequestsCount = group.pendingRequests
              .where((req) => req.status == RequestStatus.pending)
              .length;
        }

        setState(() {});
      }
    });

    // Update online count periodically
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _onlineCountNotifier.value = (_memberCountNotifier.value * 0.6).round();
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
      _showSnackbar('Error sending message: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? ChatColors.error : ChatColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
      _showSnackbar('Messages deleted successfully');
    } catch (e) {
      _showSnackbar('Error deleting messages: $e', isError: true);
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
                  color: ChatColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: ChatColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Messages',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ChatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${_selectedMessageIds.length} message(s)? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: ChatColors.textSecondary,
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ChatColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
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
      backgroundColor: ChatColors.background,
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
                                ? ChatColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            margin: EdgeInsets.only(
                              top: index > 0 &&
                                  messages[index - 1].get('userId') == data['userId']
                                  ? 4
                                  : 16,
                            ),
                            child: EnhancedChatBubble(
                              message: ChatMessage(
                                id: doc.id,
                                senderId: data['userId'] ?? '',
                                senderName: data['userName'] ?? 'Unknown',
                                senderImage: data['userImage'],
                                text: data['text'] ?? '',
                                timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
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
                _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(4),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ChatColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sending message...',
            style: GoogleFonts.poppins(
              color: ChatColors.textSecondary,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ChatColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: ChatColors.error,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ChatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: GoogleFonts.poppins(
                color: ChatColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChatColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ChatColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading messages...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ChatColors.textSecondary,
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ChatColors.primary.withOpacity(0.1), ChatColors.secondary.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: ChatColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: ChatColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to start the conversation!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ChatColors.textSecondary,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: ChatColors.primary.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
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
                  _showSnackbar('Attachment feature coming soon!');
                },
              ),

              const SizedBox(width: 8),

              // Message Input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: ChatColors.background,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _messageController.text.isNotEmpty
                          ? ChatColors.primary.withOpacity(0.3)
                          : ChatColors.border,
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
                            hintStyle: GoogleFonts.poppins(
                              color: ChatColors.textSecondary,
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
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: ChatColors.textPrimary,
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
                            ? ChatColors.primary
                            : ChatColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button with Animation
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _sendButtonAnimationController,
                  curve: Curves.elasticOut,
                ),
                child: _buildSendButton(),
              ),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: ChatColors.primary.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color ?? ChatColors.textSecondary,
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
            colors: [ChatColors.primary, ChatColors.secondary],
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
              color: ChatColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: ChatColors.secondary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _sendMessage : null,
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.3),
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

  Widget _buildEmojiPicker() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
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
          height: 320,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 32,
            verticalSpacing: 0,
            horizontalSpacing: 0,
          ),
          categoryViewConfig: CategoryViewConfig(
            indicatorColor: ChatColors.primary,
            iconColor: Colors.grey,
            iconColorSelected: ChatColors.primary,
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
    );
  }

  // Enhanced AppBar with Gradient
  AppBar _buildNormalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: ChatColors.textPrimary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ChatColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: ChatColors.primary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Group avatar with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ChatColors.primary, ChatColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : 'G',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Group Info with ValueListenableBuilder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ChatColors.textPrimary,
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
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: onlineCount > 0
                                ? ChatColors.success
                                : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: onlineCount > 0
                                ? [
                              BoxShadow(
                                color: ChatColors.success.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                                : [],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$onlineCount online',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: ChatColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: ChatColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<int>(
                          valueListenable: _memberCountNotifier,
                          builder: (context, memberCount, child) {
                            return Text(
                              '$memberCount members',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: ChatColors.textSecondary,
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
                color: ChatColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, size: 20, color: ChatColors.primary),
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
      foregroundColor: ChatColors.textPrimary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ChatColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 20, color: ChatColors.primary),
        ),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} selected',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ChatColors.textPrimary,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChatColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: ChatColors.error,
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
    // First fetch the group data
    _firebaseService.getGroupById(widget.groupId).then((group) {
      if (group == null) {
        _showSnackbar('Group not found', isError: true);
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ChatColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Group Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ChatColors.primary,
                                ChatColors.secondary
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: ChatColors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        /// Group Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.groupName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: ChatColors.textPrimary,
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: ChatColors.textSecondary,
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

                    /// Section Title
                    Text(
                      'Group Options',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ChatColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// View Members
                    _buildInfoTile(
                      icon: Icons.people_outline,
                      title: 'View All Members',
                      subtitle: 'See who\'s in this group',
                      color: ChatColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                GroupMembersScreen(
                                  groupId: widget.groupId,
                                  groupName: widget.groupName,
                                ),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const Divider(height: 24, color: ChatColors.border),

                    /// ✅ Join Requests Tile (Only for Admins)
                    if (_isCurrentUserAdmin)
                      _buildInfoTile(
                        icon: Icons.how_to_reg,
                        title: 'Join Requests',
                        subtitle: _pendingRequestsCount > 0
                            ? '$_pendingRequestsCount pending ${_pendingRequestsCount == 1 ? 'request' : 'requests'}'
                            : 'No pending requests',
                        color: ChatColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinRequestsScreen(
                                groupId: widget.groupId,
                                groupName: widget.groupName,
                              ),
                            ),
                          ).then((_) {
                            // Refresh counts when returning
                            _initializeCounts();
                          });
                        },
                      ),

                    const Divider(height: 24, color: ChatColors.border),

                    /// ✅ Approval Required Tile (Only for Admins)
                    if (_isCurrentUserAdmin)
                      _buildInfoTile(
                        icon: Icons.lock_outline,
                        title: 'Approval Required',
                        subtitle: group.isJoinApprovalRequired
                            ? 'New members need approval'
                            : 'Anyone can join directly',
                        color: group.isJoinApprovalRequired ? ChatColors.primary : ChatColors.textSecondary,
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Join Approval'),
                              content: Text(group.isJoinApprovalRequired
                                  ? 'Turn off approval requirement? Anyone can join directly.'
                                  : 'Turn on approval requirement? New members will need admin approval.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _toggleApprovalRequirement(!group.isJoinApprovalRequired);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ChatColors.primary,
                                  ),
                                  child: Text(group.isJoinApprovalRequired ? 'Turn Off' : 'Turn On'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const Divider(height: 24, color: ChatColors.border),

                    /// Report Group
                    _buildInfoTile(
                      icon: Icons.report_outlined,
                      title: 'Report Group',
                      subtitle: 'Report inappropriate content',
                      color: ChatColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showReportDialog();
                      },
                    ),

                    const Divider(height: 24, color: ChatColors.border),

                    /// Leave Group
                    _buildInfoTile(
                      icon: Icons.exit_to_app,
                      title: 'Leave Group',
                      subtitle: 'Permanently leave this group',
                      color: ChatColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showLeaveGroupDialog();
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ChatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ChatColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ChatColors.textSecondary,
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
            borderRadius: BorderRadius.circular(35),
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
                    color: ChatColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: ChatColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Report Group',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ChatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to report this group? Our team will review it within 24 hours.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: ChatColors.textSecondary,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ChatColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSnackbar('Group reported successfully');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChatColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Report',
                          style: GoogleFonts.poppins(
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
            borderRadius: BorderRadius.circular(35),
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
                    color: ChatColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: ChatColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Leave Group',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ChatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to leave this group? You will no longer receive messages from this group.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: ChatColors.textSecondary,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ChatColors.textSecondary,
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
                                _showSnackbar('You left the group');
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              _showSnackbar('Error: $e', isError: true);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChatColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Leave',
                          style: GoogleFonts.poppins(
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

// ==================== CHAT MESSAGE MODEL ====================
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

// ==================== ENHANCED CHAT BUBBLE ====================
class EnhancedChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelected;
  final bool showAvatar;
  final VoidCallback? onLongPress;

  const EnhancedChatBubble({
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
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            if (showAvatar)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [ChatColors.primary, ChatColors.secondary],
                  )
                      : null,
                ),
                padding: EdgeInsets.all(isSelected ? 2 : 0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: ChatColors.background,
                  backgroundImage: message.senderImage != null
                      ? CachedNetworkImageProvider(message.senderImage!)
                      : null,
                  child: message.senderImage == null
                      ? Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ChatColors.primary,
                    ),
                  )
                      : null,
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
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ChatColors.textSecondary,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: message.isMe
                            ? const LinearGradient(
                          colors: [ChatColors.primary, ChatColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: message.isMe ? null : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: message.isMe
                              ? const Radius.circular(22)
                              : const Radius.circular(6),
                          bottomRight: message.isMe
                              ? const Radius.circular(6)
                              : const Radius.circular(22),
                        ),
                        border: isSelected
                            ? Border.all(
                          color: ChatColors.primary,
                          width: 2,
                        )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          if (message.isMe)
                            BoxShadow(
                              color: ChatColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: GoogleFonts.poppins(
                          color: message.isMe ? Colors.white : ChatColors.textPrimary,
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
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: ChatColors.textSecondary,
                            ),
                          ),
                          if (message.isMe) ...[
                            const SizedBox(width: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ChatColors.primary.withOpacity(0.1)
                                    : ChatColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.done_all,
                                size: 12,
                                color: isSelected
                                    ? ChatColors.primary
                                    : ChatColors.success,
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