import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:buddygoapp/features/safety/presentation/report_screen.dart';
import 'package:buddygoapp/features/user/presentation/user_profile_view_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/groups/data/group_model.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';
import 'package:buddygoapp/features/user/presentation/profile_screen.dart';

import '../../safety/data/report_model.dart';

// ==================== CONSTANTS ====================
class ChatColors {
  static const Color primary = Color(0xFF8B5CF6);     // Purple
  static const Color secondary = Color(0xFFFF6B6B);   // Coral
  static const Color tertiary = Color(0xFF4FD1C5);    // Teal
  static const Color accent = Color(0xFFFBBF24);      // Yellow
  static const Color lavender = Color(0xFF9F7AEA);    // Lavender
  static const Color success = Color(0xFF06D6A0);     // Mint Green
  static const Color background = Color(0xFFF8F9FF);  // Light background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
}

// ==================== CHAT LIST SCREEN ====================
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.id;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ChatColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: ChatColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Please login to view chats',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: ChatColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ChatColors.background,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Text(
              'Messages',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ChatColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              // Search Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ChatColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                // child: IconButton(
                //   icon: Icon(Icons.search, color: ChatColors.primary),
                //   onPressed: () {
                //
                //   },
                // ),
              ),
              // More Options Button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ChatColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                // child: IconButton(
                //   icon: Icon(Icons.more_vert, color: ChatColors.primary),
                //   onPressed: () {},
                // ),
              ),
            ],
          ),

          // Online Users Section
          SliverToBoxAdapter(
            child: _buildOnlineUsersSection(),
          ),

          // Chat List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Chats',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ChatColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ChatColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getChatCount(currentUserId)} active',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ChatColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat List from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.groupsCollection
                .where('memberIds', arrayContains: currentUserId)
                .where('isActive', isEqualTo: true)
                .orderBy('lastActivityAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildErrorState(snapshot.error.toString()),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ChatColors.primary),
                    ),
                  ),
                );
              }

              final groups = snapshot.data?.docs ?? [];

              if (groups.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final doc = groups[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final group = GroupModel.fromJson({...data, 'id': doc.id});

                    return FutureBuilder<QuerySnapshot>(
                      future: _firebaseService.chatsCollection
                          .where('groupId', isEqualTo: group.id)
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, lastMessageSnapshot) {
                        if (lastMessageSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildChatItemShimmer();
                        }

                        Map<String, dynamic>? lastMessageData;
                        int unreadCount = 0;

                        if (lastMessageSnapshot.hasData &&
                            lastMessageSnapshot.data!.docs.isNotEmpty) {
                          final lastMsgDoc = lastMessageSnapshot.data!.docs.first;
                          lastMessageData = lastMsgDoc.data() as Map<String, dynamic>;

                          final readBy = List<String>.from(
                            lastMessageData['readBy'] ?? [],
                          );
                          if (!readBy.contains(currentUserId) &&
                              lastMessageData['userId'] != currentUserId) {
                            unreadCount = 1;
                          }
                        }

                        return EnhancedChatListItem(
                          group: group,
                          lastMessage: lastMessageData,
                          unreadCount: unreadCount,
                          currentUserId: currentUserId,
                          onTap: () {
                            _markMessagesAsRead(group.id, currentUserId);
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    GroupChatScreen(groupId: group.id, groupName: group.name),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  childCount: groups.length,
                ),
              );
            },
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================

  // ==================== ONLINE USERS SECTION ====================
  Widget _buildOnlineUsersSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ChatColors.primary),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No users online',
                style: GoogleFonts.poppins(
                  color: ChatColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final photoUrl = data['photoUrl'];
              final userId = users[index].id;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onLongPress: () => _showUserOptions(context, userId, data),
                  onTap: () {
                    // Quick chat option - could navigate to DM
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Avatar with gradient border
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ChatColors.primary, ChatColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage: photoUrl != null
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ChatColors.primary,
                                ),
                              )
                                  : null,
                            ),
                          ),
                          // Online indicator with pulse animation
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: ChatColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ChatColors.success.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ChatColors.textPrimary,
                          ),
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

  // ==================== CHAT ITEM SHIMMER ====================
  Widget _buildChatItemShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChatColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: ChatColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ChatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.length > 50 ? '${error.substring(0, 50)}...' : error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ChatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChatColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ChatColors.primary.withOpacity(0.1), ChatColors.secondary.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: ChatColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chats yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ChatColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join a trip or create one to start chatting\nwith fellow travelers',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ChatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
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
              backgroundColor: ChatColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Create New Trip',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getChatCount(String userId) {
    // This is a placeholder - you might want to implement actual count logic
    return 0;
  }

  // ==================== FIXED: MARK MESSAGES AS READ ====================
  // In ChatListScreen class, replace the _markMessagesAsRead method
  Future<void> _markMessagesAsRead(String groupId, String userId) async {
    try {
      // Get all messages in the group
      final allMessages = await _firebaseService.chatsCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      if (allMessages.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      int updateCount = 0;

      for (var doc in allMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);
        final messageUserId = data['userId'] as String?;

        // Mark as read if user hasn't read it and didn't send it
        if (!readBy.contains(userId) && messageUserId != userId) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('✅ Marked $updateCount messages as read in group: $groupId');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // ==================== USER OPTIONS ====================
  Future<void> _blockUser(String userId) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.currentUser?.id;

    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to block this user? You will no longer receive messages from them.',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'User blocked successfully',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: ChatColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error blocking user',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: ChatColors.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: ChatColors.secondary,
            ),
            child: Text(
              'Block',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _shareUserProfile(String userId, String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sharing profile of $userName',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: ChatColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showUserOptions(
      BuildContext context,
      String userId,
      Map<String, dynamic> userData,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: userData['photoUrl'] != null
                          ? CachedNetworkImageProvider(userData['photoUrl'])
                          : null,
                      child: userData['photoUrl'] == null
                          ? Text(
                        (userData['name']?[0] ?? '?').toUpperCase(),
                        style: const TextStyle(color: ChatColors.primary),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'User',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ChatColors.textPrimary,
                            ),
                          ),
                          Text(
                            '@${userId.substring(0, 8)}...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ChatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Options
              _buildOptionTile(
                icon: Icons.person,
                label: 'View Profile',
                color: ChatColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileViewScreen(userId: userId),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.block,
                label: 'Block User',
                color: ChatColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(userId);
                },
              ),
              _buildOptionTile(
                icon: Icons.flag,
                label: 'Report User',
                color: Colors.orange,
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
              _buildOptionTile(
                icon: Icons.share,
                label: 'Share Profile',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _shareUserProfile(userId, userData['name'] ?? 'User');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ChatColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ==================== ENHANCED CHAT LIST ITEM ====================
class EnhancedChatListItem extends StatelessWidget {
  final GroupModel group;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;
  final String currentUserId;
  final VoidCallback onTap;

  const EnhancedChatListItem({
    super.key,
    required this.group,
    required this.lastMessage,
    this.unreadCount = 0,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = group.isAdmin(currentUserId);
    final timeColor = unreadCount > 0 ? ChatColors.primary : ChatColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (unreadCount > 0)
              BoxShadow(
                color: ChatColors.primary.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with status
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: unreadCount > 0
                            ? [ChatColors.primary, ChatColors.secondary]
                            : [Colors.grey[300]!, Colors.grey[300]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: group.coverImage != null
                          ? CachedNetworkImageProvider(group.coverImage!)
                          : null,
                      child: group.coverImage == null
                          ? Text(
                        group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: unreadCount > 0
                              ? ChatColors.primary
                              : Colors.grey[500],
                        ),
                      )
                          : null,
                    ),
                  ),
                  // Group type indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: group.isActive ? ChatColors.success : Colors.grey,
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

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Name and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: unreadCount > 0
                                  ? ChatColors.textPrimary
                                  : ChatColors.textPrimary.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(lastMessage?['timestamp']?.toDate() ?? group.lastActivityAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: timeColor,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Bottom row: Last message and member count
                    Row(
                      children: [
                        // Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ChatColors.primary, ChatColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Last message preview
                        Expanded(
                          child: Text(
                            _getLastMessagePreview(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: unreadCount > 0
                                  ? ChatColors.textPrimary
                                  : ChatColors.textSecondary,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Member count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ChatColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 12,
                                color: ChatColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${group.currentMembers}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ChatColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Admin badge
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ChatColors.accent, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  String _getLastMessagePreview() {
    if (lastMessage == null) {
      return 'No messages yet • Be the first to say hi!';
    }

    final senderId = lastMessage!['userId'] ?? '';
    final senderName = lastMessage!['userName'] ?? 'Unknown';
    final messageText = lastMessage!['text'] ?? '';
    final messageType = lastMessage!['type'] ?? 'text';

    String prefix = '';
    if (senderId == currentUserId) {
      prefix = 'You: ';
    } else {
      prefix = '$senderName: ';
    }

    if (messageType == 'image') {
      return '$prefix📷 Photo';
    } else if (messageType == 'location') {
      return '$prefix📍 Location';
    } else {
      return '$prefix$messageText';
    }
  }
}