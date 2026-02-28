import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:intl/intl.dart';

import '../../../core/services/notification_service.dart';

class AdminUserProfileScreen extends StatefulWidget {
  final String userId;
  final bool isAdmin;

  const AdminUserProfileScreen({
    super.key,
    required this.userId,
    this.isAdmin = true,
  });

  @override
  State<AdminUserProfileScreen> createState() => _AdminUserProfileScreenState();
}

class _AdminUserProfileScreenState extends State<AdminUserProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userReports = [];
  List<Map<String, dynamic>> _userTrips = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile
      final userDoc = await _firebaseService.usersCollection
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      // Get user's reports (as reporter)
      final reportsSnapshot = await _firebaseService.reportsCollection
          .where('reporterId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      _userReports = reportsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Get user's trips
      final tripsSnapshot = await _firebaseService.tripsCollection
          .where('hostId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      _userTrips = tripsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 ADD THIS METHOD - It was missing in your file
  Future<void> _toggleVerifiedBadge() async {
    final currentStatus = _userData?['isVerifiedTraveler'] ?? false;
    final newStatus = !currentStatus;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Verify User' : 'Remove Verification'),
        content: Text(
          newStatus
              ? 'Are you sure you want to mark this user as a Verified Traveler?'
              : 'Are you sure you want to remove the Verified Traveler badge from this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(newStatus ? 'Verify' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Update in Firestore
      await _firebaseService.usersCollection.doc(widget.userId).update({
        'isVerifiedTraveler': newStatus,
        'verifiedAt': newStatus ? FieldValue.serverTimestamp() : null,
        'verifiedBy': newStatus ? FirebaseAuth.instance.currentUser?.uid : null,
      });
      // 🔥 ADD THIS - Send notification to user
      await _firebaseService.sendVerifiedBadgeNotification(
        userId: widget.userId,
        userName: _userData!['name'] ?? 'User',
        isVerified: newStatus,
      );

      // Update local state
      setState(() {
        _userData!['isVerifiedTraveler'] = newStatus;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '✅ User is now a Verified Traveler!'
                : '❌ Verified badge removed successfully',
          ),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating verification status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isAdmin)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'warn',
                  child: Text('⚠️ Send Warning'),
                ),
                const PopupMenuItem(
                  value: 'suspend',
                  child: Text('⛔ Suspend Account'),
                ),
                const PopupMenuItem(value: 'ban', child: Text('🚫 Ban User')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'warn':
                    _showWarningDialog();
                    break;
                  case 'suspend':
                    _showSuspendDialog();
                    break;
                  case 'ban':
                    _showBanDialog();
                    break;
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(),
                  const SizedBox(height: 16),

                  // 🔥 Verified Badge Toggle Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_userData?['isVerifiedTraveler'] == true
                                    ? const Color(0xFF00D4AA)
                                    : Colors.grey)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _userData?['isVerifiedTraveler'] == true
                              ? const Color(0xFF00D4AA)
                              : Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _userData?['isVerifiedTraveler'] == true
                                ? Icons.verified
                                : Icons.verified_outlined,
                            color: _userData?['isVerifiedTraveler'] == true
                                ? const Color(0xFF00D4AA)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userData?['isVerifiedTraveler'] == true
                                ? 'Verified Traveler'
                                : 'Not Verified',
                            style: TextStyle(
                              color: _userData?['isVerifiedTraveler'] == true
                                  ? const Color(0xFF00D4AA)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _toggleVerifiedBadge,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _userData?['isVerifiedTraveler'] == true
                                    ? Colors.red.withOpacity(0.1)
                                    : const Color(0xFF00D4AA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _userData?['isVerifiedTraveler'] == true
                                    ? 'Remove Badge'
                                    : 'Add Badge',
                                style: TextStyle(
                                  color:
                                      _userData?['isVerifiedTraveler'] == true
                                      ? Colors.red
                                      : const Color(0xFF00D4AA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Details
                  _buildSection('📋 User Details', [
                    _buildInfoRow('User ID', widget.userId),
                    _buildInfoRow('Email', _userData!['email'] ?? 'N/A'),
                    _buildInfoRow('Phone', _userData!['phone'] ?? 'N/A'),
                    _buildInfoRow('Location', _userData!['location'] ?? 'N/A'),
                    _buildInfoRow('Bio', _userData!['bio'] ?? 'No bio'),
                  ]),
                  const SizedBox(height: 16),

                  // Verification Status
                  _buildSection('✅ Verification Status', [
                    _buildVerificationItem(
                      'Email',
                      _userData!['isEmailVerified'] == true,
                    ),
                    _buildVerificationItem(
                      'Phone',
                      _userData!['isPhoneVerified'] == true,
                    ),
                    _buildVerificationItem(
                      'Student',
                      _userData!['isStudentVerified'] == true,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Stats
                  _buildSection('📊 Statistics', [
                    _buildStatRow(
                      'Total Trips',
                      '${_userData!['totalTrips'] ?? 0}',
                    ),
                    _buildStatRow('Reports Filed', '${_userReports.length}'),
                    _buildStatRow('Rating', '${_userData!['rating'] ?? 5}/5'),
                    _buildStatRow(
                      'Joined',
                      _formatDate(_userData!['createdAt']),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Recent Reports
                  if (_userReports.isNotEmpty) ...[
                    _buildSection(
                      '⚠️ Recent Reports',
                      _userReports.map((report) {
                        return ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          title: Text(report['reason'] ?? 'Unknown'),
                          subtitle: Text(
                            'Status: ${report['status'] ?? 'pending'}',
                          ),
                          trailing: Text(_formatTimestamp(report['createdAt'])),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Recent Trips
                  if (_userTrips.isNotEmpty) ...[
                    _buildSection(
                      '✈️ Recent Trips',
                      _userTrips.map((trip) {
                        return ListTile(
                          leading: const Icon(
                            Icons.travel_explore,
                            color: Colors.green,
                          ),
                          title: Text(trip['title'] ?? 'Untitled'),
                          subtitle: Text(trip['destination'] ?? 'Unknown'),
                          trailing: Text(
                            '${trip['currentMembers'] ?? 0}/${trip['maxMembers'] ?? 0}',
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Admin Actions
                  if (widget.isAdmin) ...[
                    const Text(
                      '🔨 Admin Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Warn User',
                            backgroundColor: Colors.orange,
                            onPressed: _showWarningDialog,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'Suspend',
                            backgroundColor: Colors.red,
                            onPressed: _showSuspendDialog,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Delete Account',
                      backgroundColor: Colors.red,
                      onPressed: _showDeleteDialog,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // 🔥 Helper Methods (All existing ones stay the same)
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _userData!['photoUrl'] != null
                ? CachedNetworkImageProvider(_userData!['photoUrl'])
                : null,
            child: _userData!['photoUrl'] == null
                ? Text(
                    _userData!['name']?[0].toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 30),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userData!['name'] ?? 'Unknown User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Text(
            _userData!['email'] ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String label, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            color: isVerified ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            isVerified ? 'Verified' : 'Not Verified',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return 'Unknown';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    }
    return '';
  }

  // Dialog Methods
  void _showWarningDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to warn this user?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Warning sent successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: const Text('Are you sure you want to suspend this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User suspended successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: const Text(
          'Are you sure you want to permanently ban this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User banned successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete this user account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
