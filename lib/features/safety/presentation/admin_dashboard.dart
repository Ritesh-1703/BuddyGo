import 'package:buddygoapp/features/auth/presentation/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import '../data/report_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedTab = 0; // 0: Reports, 1: Users, 2: Analytics

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'lib/assets/images/AdminPanal.png',
                height: 40,
                width: 40,
              ),
              const Spacer(),
              const Text('Admin Dashboard', style: TextStyle(fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF7B61FF),
            labelColor: const Color(0xFF7B61FF),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Reports'),
              Tab(text: 'Users'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reports found'));
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final data = report.data() as Map<String, dynamic>;

            return ReportCard(
              reportId: report.id,
              data: data,
              onActionTaken: () {
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.usersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;

            return UserCard(
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
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Users',
                  value: '1,234',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Trips',
                  value: '48',
                  icon: Icons.travel_explore,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Reports',
                  value: '12',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Revenue',
                  value: '₹24,500',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildActivityList(),
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
    return Card(
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
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        _buildActivityItem(
          icon: Icons.person_add,
          title: 'New user registered',
          subtitle: 'John Doe joined the platform',
          time: '2 hours ago',
          color: Colors.blue,
        ),
        _buildActivityItem(
          icon: Icons.travel_explore,
          title: 'New trip created',
          subtitle: 'Goa Beach Adventure by Sarah',
          time: '4 hours ago',
          color: Colors.green,
        ),
        _buildActivityItem(
          icon: Icons.warning,
          title: 'Report submitted',
          subtitle: 'User reported for inappropriate behavior',
          time: '1 day ago',
          color: Colors.orange,
        ),
        _buildActivityItem(
          icon: Icons.verified,
          title: 'User verified',
          subtitle: 'Student verification completed',
          time: '2 days ago',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onActionTaken;

  const ReportCard({
    super.key,
    required this.reportId,
    required this.data,
    required this.onActionTaken,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (data['status'] ?? 'pending').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, h:mm a').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reason
            Text(
              'Reason: ${data['reason']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Details
            if (data['details'] != null)
              Text(
                data['details'],
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            const SizedBox(height: 16),
            // Actions
            if ((data['status'] ?? 'pending') == 'pending')
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Dismiss',
                      backgroundColor: Colors.grey,
                      onPressed: () => _updateReportStatus('dismissed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Warn User',
                      backgroundColor: Colors.orange,
                      onPressed: () => _updateReportStatus('warned'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Suspend',
                      backgroundColor: Colors.red,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'dismissed':
        return Colors.grey;
      case 'warned':
        return Colors.blue;
      case 'suspended':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateReportStatus(String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'status': status, 'resolvedAt': FieldValue.serverTimestamp()},
    );
  }
}

class UserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final VoidCallback onAction;

  const UserCard({
    super.key,
    required this.userId,
    required this.data,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null
                      ? Text(data['name']?[0] ?? '?')
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data['email'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadges(data),
              ],
            ),
            const SizedBox(height: 16),
            // User Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // _buildUserStat('Trips', '${data['totalTrips'] ?? 0}'),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('trips')
                      .where('hostId', isEqualTo: userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildUserStat('Trips', '0');
                    }

                    return _buildUserStat(
                      'Trips',
                      snapshot.data!.docs.length.toString(),
                    );
                  },
                ),
                _buildUserStat('Rating', '${data['rating'] ?? 5}/5'),
                _buildUserStat(
                  'Reports',
                  '${data['reportedUsers']?.length ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // View profile
                    },
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Message user
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                    ),
                    child: const Text('Message'),
                  ),
                ),
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
          _buildBadge(Icons.email, 'Email', Colors.blue),
        if (data['isPhoneVerified'] == true)
          _buildBadge(Icons.phone, 'Phone', Colors.green),
        if (data['isStudentVerified'] == true)
          _buildBadge(Icons.school, 'Student', Colors.purple),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}