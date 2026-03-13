import 'package:buddygoapp/features/auth/presentation/admin_login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import '../data/report_model.dart';
import 'admin_user_profile_screen.dart';

// ==================== CONSTANTS ====================
class AdminColors {
  static const Color primary = Color(0xFF8B5CF6); // Purple
  static const Color secondary = Color(0xFFFF6B6B); // Coral
  static const Color tertiary = Color(0xFF4FD1C5); // Teal
  static const Color accent = Color(0xFFFBBF24); // Yellow
  static const Color lavender = Color(0xFF9F7AEA); // Lavender
  static const Color success = Color(0xFF06D6A0); // Mint Green
  static const Color error = Color(0xFFFF6B6B); // Coral for errors
  static const Color warning = Color(0xFFFBBF24); // Yellow for warnings
  static const Color background = Color(0xFFF0F2FE); // Light purple tint
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);

  // Status colors
  static const Color pending = Color(0xFFFBBF24); // Yellow
  static const Color dismissed = Color(0xFF718096); // Grey
  static const Color warned = Color(0xFF4FD1C5); // Teal
  static const Color suspended = Color(0xFFFF6B6B); // Coral
  static const Color resolved = Color(0xFF06D6A0); // Mint
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AdminColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              // Animated Logo Container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminColors.primary, AdminColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/AdminPanal.png',
                  height: 24,
                  width: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Logout Button with Neon Style
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: AdminColors.error),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AdminColors.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminColors.primary, AdminColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: AdminColors.textSecondary,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  // Reports Tab with Badge
                  Tab(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firebaseService.reportsCollection
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final pendingCount = snapshot.data?.docs.length ?? 0;
                        return badges.Badge(
                          showBadge: pendingCount > 0,
                          badgeContent: Text(
                            pendingCount > 9 ? '9+' : '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: AdminColors.error,
                            padding: const EdgeInsets.all(4),
                          ),
                          child: const Text('Reports'),
                        );
                      },
                    ),
                  ),
                  const Tab(text: 'Users'),
                  const Tab(text: 'Analytics'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReportsTab(),
            _buildUsersTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.reportsCollection
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.flag_outlined,
            title: 'No Reports Found',
            message: 'All reports will appear here',
          );
        }

        final reports = snapshot.data!.docs;
        final pendingCount = reports
            .where(
              (r) => (r.data() as Map<String, dynamic>)['status'] == 'pending',
            )
            .length;

        return Column(
          children: [
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AdminColors.warning, AdminColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.warning.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pendingCount Pending ${pendingCount == 1 ? 'Report' : 'Reports'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Requires your attention',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final data = report.data() as Map<String, dynamic>;

                  return EnhancedReportCard(
                    reportId: report.id,
                    data: data,
                    onActionTaken: () {
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.usersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'No Users Found',
            message: 'Users will appear here',
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;

            return EnhancedUserCard(
              userId: user.id,
              data: data,
              onAction: () {
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards with Real-time Counts
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.usersCollection.snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _buildStatCard(
                      title: 'Total Users',
                      value: '$count',
                      icon: Icons.people,
                      color: AdminColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('trips')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _buildStatCard(
                      title: 'Active Trips',
                      value: '$count',
                      icon: Icons.travel_explore,
                      color: AdminColors.success,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.reportsCollection
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _buildStatCard(
                      title: 'Pending Reports',
                      value: '$count',
                      icon: Icons.warning,
                      color: AdminColors.warning,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Expanded(
              //   child: StreamBuilder<QuerySnapshot>(
              //     stream: FirebaseFirestore.instance.collection('payments').snapshots(),
              //     builder: (context, snapshot) {
              //       int total = 0;
              //       if (snapshot.hasData) {
              //         total = snapshot.data!.docs.fold(0, (sum, doc) {
              //           final data = doc.data() as Map<String, dynamic>;
              //           return sum + (data['amount'] as int? ?? 0);
              //         });
              //       }
              //       return _buildStatCard(
              //         title: 'Revenue',
              //         value: '₹${(total / 1000).toStringAsFixed(1)}K',
              //         icon: Icons.attach_money,
              //         color: AdminColors.lavender,
              //       );
              //     },
              //   ),
              // ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .snapshots(),
                  builder: (context, paymentSnapshot) {
                    int total = 0;

                    /// If payments exist → use them
                    if (paymentSnapshot.hasData &&
                        paymentSnapshot.data!.docs.isNotEmpty) {
                      total = paymentSnapshot.data!.docs.fold(0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return sum + (data['amount'] as int? ?? 0);
                      });

                      return _buildStatCard(
                        title: 'Revenue',
                        value: '₹${(total / 1000).toStringAsFixed(1)}K',
                        icon: Icons.attach_money,
                        color: AdminColors.lavender,
                      );
                    }

                    /// If payments NOT active → calculate from trip budgets
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('trips')
                          .snapshots(),
                      builder: (context, tripSnapshot) {
                        int tripTotal = 0;

                        if (tripSnapshot.hasData) {
                          tripTotal = tripSnapshot.data!.docs.fold(0, (
                            sum,
                            doc,
                          ) {
                            final data = doc.data() as Map<String, dynamic>;
                            return sum +
                                ((data['budget'] as num?)?.toInt() ?? 0);
                          });
                        }

                        return _buildStatCard(
                          title: 'Trip Budget',
                          value: '₹${(tripTotal / 1000).toStringAsFixed(1)}K',
                          icon: Icons.account_balance_wallet,
                          color: AdminColors.lavender,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AdminColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AdminColors.primary, AdminColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.reportsCollection
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final reports = snapshot.data!.docs;

                    return Column(
                      children: reports.map((report) {
                        final data = report.data() as Map<String, dynamic>;
                        return _buildActivityItem(
                          icon: Icons.flag,
                          title: 'Report submitted',
                          subtitle: '${data['reason']}',
                          time: _formatTime(
                            (data['createdAt'] as Timestamp).toDate(),
                          ),
                          color: AdminColors.warning,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
              gradient: LinearGradient(
                colors: [
                  AdminColors.primary.withOpacity(0.1),
                  AdminColors.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminColors.primary.withOpacity(0.1),
                  AdminColors.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AdminColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AdminColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AdminColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours > 24) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

// ==================== ENHANCED REPORT CARD ====================
class EnhancedReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onActionTaken;

  const EnhancedReportCard({
    super.key,
    required this.reportId,
    required this.data,
    required this.onActionTaken,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();
    final status = data['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(status).withOpacity(0.1),
                        _getStatusColor(status).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('MMM dd, h:mm a').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Reporter Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['reporterId'])
                  .get(),
              builder: (context, snapshot) {
                // final reporterName = snapshot.hasData
                //     ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
                //     : 'Loading...';
                final reporterData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                final reporterName = reporterData?['name'] ?? 'Admin';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: AdminColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reported by: ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                    Text(
                      reporterName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // Reported User Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['reportedUserId'])
                  .get(),
              builder: (context, snapshot) {
                // final reportedUserName = snapshot.hasData
                //     ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ??
                //           'Unknown'
                //     : 'Loading...';
                final reportedData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                final reportedUserName = reportedData?['name'] ?? 'Unknown';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AdminColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        size: 14,
                        color: AdminColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reported user: ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                    Text(
                      reportedUserName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason: ${data['reason']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  if (data['details'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data['details'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions for pending reports
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      text: 'Dismiss',
                      color: AdminColors.dismissed,
                      onPressed: () => _updateReportStatus('dismissed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      text: 'Warn',
                      color: AdminColors.warned,
                      onPressed: () => _updateReportStatus('warned'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      text: 'Suspend',
                      color: AdminColors.suspended,
                      onPressed: () => _updateReportStatus('suspended'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AdminColors.pending;
      case 'dismissed':
        return AdminColors.dismissed;
      case 'warned':
        return AdminColors.warned;
      case 'suspended':
        return AdminColors.suspended;
      case 'resolved':
        return AdminColors.resolved;
      default:
        return AdminColors.dismissed;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'dismissed':
        return Icons.close;
      case 'warned':
        return Icons.warning;
      case 'suspended':
        return Icons.block;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.flag;
    }
  }

  Future<void> _updateReportStatus(String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'status': status, 'resolvedAt': FieldValue.serverTimestamp()},
    );
  }
}

// ==================== ENHANCED USER CARD ====================
class EnhancedUserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final VoidCallback onAction;

  const EnhancedUserCard({
    super.key,
    required this.userId,
    required this.data,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AdminColors.primary, AdminColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AdminColors.background,
                    backgroundImage: data['photoUrl'] != null
                        ? CachedNetworkImageProvider(data['photoUrl'])
                        : null,
                    child: data['photoUrl'] == null
                        ? Text(
                            data['name']?[0]?.toUpperCase() ?? '?',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown User',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Verification Badges
                _buildVerificationBadges(data),
              ],
            ),

            const SizedBox(height: 16),

            // User Stats (Rating removed as requested)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Trips Stat with Real-time Count
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('trips')
                      .where('hostId', isEqualTo: userId)
                      .get(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _buildUserStat(
                      label: 'Trips',
                      value: '$count',
                      color: AdminColors.primary,
                    );
                  },
                ),

                Container(width: 1, height: 30, color: AdminColors.border),

                // Reports Stat with Real-time Count
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('reportedUserId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _buildUserStat(
                      label: 'Reports',
                      value: '$count',
                      color: AdminColors.error,
                    );
                  },
                ),

                Container(width: 1, height: 30, color: AdminColors.border),

                // Join Date
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AdminColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatJoinDate(data['createdAt']),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminUserProfileScreen(userId: userId),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.primary,
                      side: BorderSide(
                        color: AdminColors.primary.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'View Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded(
                //   child: Container(
                //     decoration: BoxDecoration(
                //       gradient: const LinearGradient(
                //         colors: [AdminColors.primary, AdminColors.secondary],
                //         begin: Alignment.topLeft,
                //         end: Alignment.bottomRight,
                //       ),
                //       borderRadius: BorderRadius.circular(16),
                //       boxShadow: [
                //         BoxShadow(
                //           color: AdminColors.primary.withOpacity(0.3),
                //           blurRadius: 10,
                //           offset: const Offset(0, 4),
                //         ),
                //       ],
                //     ),
                //     child: ElevatedButton(
                //       onPressed: () {},
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.transparent,
                //         foregroundColor: Colors.white,
                //         shadowColor: Colors.transparent,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(16),
                //         ),
                //         padding: const EdgeInsets.symmetric(vertical: 14),
                //       ),
                //       child: Text(
                //         'Message',
                //         style: GoogleFonts.poppins(
                //           fontSize: 13,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadges(Map<String, dynamic> data) {
    return Row(
      children: [
        if (data['isEmailVerified'] == true)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email, size: 14, color: Colors.blue),
          ),
        if (data['isPhoneVerified'] == true)
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone, size: 14, color: Colors.green),
          ),
        if (data['isStudentVerified'] == true)
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, size: 14, color: Colors.purple),
          ),
      ],
    );
  }

  Widget _buildUserStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AdminColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatJoinDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('MMM yyyy').format(timestamp.toDate());
    }
    return 'N/A';
  }
}
