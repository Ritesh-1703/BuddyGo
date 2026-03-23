import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:google_fonts/google_fonts.dart';
import 'package:buddygoapp/core/services/notification_service.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/discovery/presentation/discovery_screen.dart';
import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:buddygoapp/features/groups/presentation/chat_list_screen.dart';
import 'package:buddygoapp/features/user/presentation/profile_screen.dart';
import 'package:buddygoapp/features/user/presentation/my_trips_screen.dart';

// ==================== CONSTANTS - SEPARATE LOGIC ====================
class TabColors {
  static const Color primary = Color(0xFF8B5CF6);     // Purple
  static const Color secondary = Color(0xFFFF6B6B);   // Coral
  static const Color tertiary = Color(0xFF4FD1C5);    // Teal
  static const Color accent = Color(0xFFFBBF24);      // Yellow
  static const Color lavender = Color(0xFF9F7AEA);    // Lavender

  static const Color unselected = Color(0xFFA0AEC0);  // Grey
  static const Color background = Colors.white;
}

class TabIcons {
  static const IconData discover = Icons.explore;
  static const IconData discoverOutlined = Icons.explore_outlined;
  static const IconData chats = Icons.chat_bubble;
  static const IconData chatsOutlined = Icons.chat_bubble_outlined;
  static const IconData myTrips = Icons.travel_explore;
  static const IconData myTripsOutlined = Icons.travel_explore_outlined;
  static const IconData alerts = Icons.notifications;
  static const IconData alertsOutlined = Icons.notifications_outlined;
  static const IconData profile = Icons.person;
  static const IconData profileOutlined = Icons.person_outlined;
}

class TabLabels {
  static const String discover = 'Discover';
  static const String chats = 'Chats';
  static const String myTrips = 'My Trips';
  static const String alerts = 'Notification';
  static const String profile = 'Profile';
}

// ==================== TAB ITEM MODEL ====================
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData outlinedIcon;
  final Color color;
  final Widget screen;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.outlinedIcon,
    required this.color,
    required this.screen,
  });
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;

  // Separate list of navigation items - CLEAN LOGIC
  late final List<BottomNavItem> _navItems = [
    BottomNavItem(
      label: TabLabels.discover,
      icon: TabIcons.discover,
      outlinedIcon: TabIcons.discoverOutlined,
      color: TabColors.primary,
      screen: const DiscoveryScreen(),
    ),
    BottomNavItem(
      label: TabLabels.chats,
      icon: TabIcons.chats,
      outlinedIcon: TabIcons.chatsOutlined,
      color: TabColors.secondary,
      screen: const ChatListScreen(),
    ),
    BottomNavItem(
      label: TabLabels.myTrips,
      icon: TabIcons.myTrips,
      outlinedIcon: TabIcons.myTripsOutlined,
      color: TabColors.tertiary,
      screen: const MyTripsScreen(),
    ),
    BottomNavItem(
      label: TabLabels.alerts,
      icon: TabIcons.alerts,
      outlinedIcon: TabIcons.alertsOutlined,
      color: TabColors.accent,
      screen: const NotificationsScreen(),
    ),
    BottomNavItem(
      label: TabLabels.profile,
      icon: TabIcons.profile,
      outlinedIcon: TabIcons.profileOutlined,
      color: TabColors.lavender,
      screen: const ProfileScreen(),
    ),
  ];

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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _navItems.map((item) => item.screen).toList(),
      ),

      // FIX 1: Added padding to prevent overlap with bottom nav
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // FIX 2: Proper bottom navigation bar without overflow
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget? _buildFloatingActionButton() {
    // Only show FAB for Discover and Chats tabs
    if (_selectedIndex != 0 && _selectedIndex != 1) return null;

    final isDiscoverTab = _selectedIndex == 0;
    final buttonColor = isDiscoverTab ? TabColors.primary : TabColors.secondary;

    return Padding(
      // Add bottom padding to prevent overlap with bottom nav
      padding: const EdgeInsets.only(bottom: 20),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: Container(
          height: 52, // Slightly reduced height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                buttonColor,
                isDiscoverTab ? TabColors.lavender : TabColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleFABPress,
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDiscoverTab ? Icons.add : Icons.message,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDiscoverTab ? 'Create' : 'New Chat',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleFABPress() {
    _fabAnimationController.reset();
    _fabAnimationController.forward();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
  }

  // ==================== FIXED BOTTOM NAVIGATION BAR ====================
  Widget _buildBottomNavigationBar() {
    return Container(
      // FIX: Use MediaQuery to get safe area and prevent overflow
      height: 60 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: TabColors.primary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            return _buildNavItem(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with special handling for alerts
              if (item.label == TabLabels.alerts)
                _buildAlertIcon(item, isSelected)
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 8 : 6),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? item.icon : item.outlinedIcon,
                    size: isSelected ? 24 : 22,
                    color: isSelected ? item.color : TabColors.unselected,
                  ),
                ),

              const SizedBox(height: 2),

              // Label
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? item.color : TabColors.unselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertIcon(BottomNavItem item, bool isSelected) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isSelected ? 8 : 6),
          decoration: BoxDecoration(
            color: isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: badges.Badge(
            showBadge: unreadCount > 0,
            position: badges.BadgePosition.topEnd(top: -6, end: -4),
            badgeContent: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: TabColors.secondary,
              padding: const EdgeInsets.all(3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSelected ? item.icon : item.outlinedIcon,
              size: isSelected ? 24 : 22,
              color: isSelected ? item.color : TabColors.unselected,
            ),
          ),
        );
      },
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    });
  }
}