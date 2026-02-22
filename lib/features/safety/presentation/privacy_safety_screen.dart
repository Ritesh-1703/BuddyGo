import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Privacy Settings
  bool _shareLocation = true;
  bool _shareProfile = true;
  bool _showOnlineStatus = true;
  bool _allowMessagesFromEveryone = false;
  bool _allowFriendRequests = true;
  bool _saveChatHistory = true;

  // Safety Settings
  bool _safeSearch = true;
  bool _blockedUsersVisible = true;
  bool _receiveSafetyAlerts = true;
  bool _autoBlockSuspicious = false;

  // Data Settings
  bool _analyticsCollection = true;
  bool _personalizedAds = false;

  int _selectedPrivacyLevel = 1; // 0: Public, 1: Friends, 2: Private

  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> _reportedUsers = [];
  bool _isLoadingBlocked = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    // Load from SharedPreferences or Firestore
    // For now, using defaults
    setState(() {
      // Settings would be loaded here
    });
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoadingBlocked = true);

    // Simulate loading blocked users
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _blockedUsers = [
        {
          'id': 'user1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'photoUrl': null,
          'blockedDate': DateTime.now().subtract(const Duration(days: 5)),
        },
        {
          'id': 'user2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'photoUrl': null,
          'blockedDate': DateTime.now().subtract(const Duration(days: 12)),
        },
      ];

      _reportedUsers = [
        {
          'id': 'user3',
          'name': 'Mike Johnson',
          'reason': 'Harassment',
          'status': 'Resolved',
          'reportedDate': DateTime.now().subtract(const Duration(days: 3)),
        },
      ];

      _isLoadingBlocked = false;
    });
  }

  Future<void> _unblockUser(String userId) async {
    setState(() {
      _blockedUsers.removeWhere((user) => user['id'] == userId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User unblocked successfully'),
        backgroundColor: Color(0xFF00D4AA),
      ),
    );
  }

  Future<void> _saveSettings() async {
    // Save to SharedPreferences or Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Color(0xFF00D4AA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Safety'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Score Card
            _buildSafetyScoreCard(),
            const SizedBox(height: 24),

            // Privacy Level
            _buildSectionTitle('Privacy Level'),
            const SizedBox(height: 12),
            _buildPrivacyLevelSelector(),
            const SizedBox(height: 24),

            // Privacy Settings
            _buildSectionTitle('Privacy Settings'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.location_on,
                title: 'Share Location',
                subtitle: 'Allow trip members to see your location',
                value: _shareLocation,
                onChanged: (value) => setState(() => _shareLocation = value),
              ),
              _buildSwitchTile(
                icon: Icons.public,
                title: 'Public Profile',
                subtitle: 'Allow non-members to view your profile',
                value: _shareProfile,
                onChanged: (value) => setState(() => _shareProfile = value),
              ),
              _buildSwitchTile(
                icon: Icons.circle,
                title: 'Show Online Status',
                subtitle: 'Let others see when you\'re active',
                value: _showOnlineStatus,
                onChanged: (value) => setState(() => _showOnlineStatus = value),
              ),
              _buildSwitchTile(
                icon: Icons.message,
                title: 'Messages from Everyone',
                subtitle: 'Allow message requests from anyone',
                value: _allowMessagesFromEveryone,
                onChanged: (value) => setState(() => _allowMessagesFromEveryone = value),
              ),
              _buildSwitchTile(
                icon: Icons.person_add,
                title: 'Friend Requests',
                subtitle: 'Allow others to send you friend requests',
                value: _allowFriendRequests,
                onChanged: (value) => setState(() => _allowFriendRequests = value),
              ),
              _buildSwitchTile(
                icon: Icons.history,
                title: 'Save Chat History',
                subtitle: 'Keep chat history on your device',
                value: _saveChatHistory,
                onChanged: (value) => setState(() => _saveChatHistory = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Safety Settings
            _buildSectionTitle('Safety Settings'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.security,
                title: 'Safe Search',
                subtitle: 'Filter inappropriate content',
                value: _safeSearch,
                onChanged: (value) => setState(() => _safeSearch = value),
              ),
              _buildSwitchTile(
                icon: Icons.visibility_off,
                title: 'Blocked Users Visible',
                subtitle: 'Show blocked users in your list',
                value: _blockedUsersVisible,
                onChanged: (value) => setState(() => _blockedUsersVisible = value),
              ),
              _buildSwitchTile(
                icon: Icons.notifications_active,
                title: 'Safety Alerts',
                subtitle: 'Receive safety notifications',
                value: _receiveSafetyAlerts,
                onChanged: (value) => setState(() => _receiveSafetyAlerts = value),
              ),
              _buildSwitchTile(
                icon: Icons.auto_awesome,
                title: 'Auto-block Suspicious',
                subtitle: 'Automatically block detected spam accounts',
                value: _autoBlockSuspicious,
                onChanged: (value) => setState(() => _autoBlockSuspicious = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Data & Analytics
            _buildSectionTitle('Data & Analytics'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.analytics,
                title: 'Usage Analytics',
                subtitle: 'Help improve BuddyGO with usage data',
                value: _analyticsCollection,
                onChanged: (value) => setState(() => _analyticsCollection = value),
              ),
              _buildSwitchTile(
                icon: Icons.ad_units,
                title: 'Personalized Ads',
                subtitle: 'See relevant advertisements',
                value: _personalizedAds,
                onChanged: (value) => setState(() => _personalizedAds = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Blocked Users Section
            _buildSectionTitle('Blocked Users'),
            const SizedBox(height: 12),
            _blockedUsersVisible
                ? _buildBlockedUsersList()
                : const SizedBox.shrink(),
            const SizedBox(height: 24),

            // Reported Users Section
            _buildSectionTitle('Report History'),
            const SizedBox(height: 12),
            _buildReportedUsersList(),
            const SizedBox(height: 24),

            // Two-Factor Authentication
            _buildSectionTitle('Security'),
            const SizedBox(height: 12),
            _buildTwoFactorCard(),
            const SizedBox(height: 24),

            // Data Export/Delete
            _buildDataManagementCard(),
            const SizedBox(height: 24),

            // Emergency Contacts
            _buildEmergencyContactsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF9E8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '85',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good • Better than 70% of users',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1D2B),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7B61FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF7B61FF),
    );
  }

  Widget _buildPrivacyLevelSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPrivacyOption(
              title: 'Public',
              description: 'Anyone can see your profile and trips',
              value: 0,
              icon: Icons.public,
            ),
            const SizedBox(height: 12),
            _buildPrivacyOption(
              title: 'Friends Only',
              description: 'Only friends and trip members can see your info',
              value: 1,
              icon: Icons.people,
            ),
            const SizedBox(height: 12),
            _buildPrivacyOption(
              title: 'Private',
              description: 'Only you can see your profile',
              value: 2,
              icon: Icons.lock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String description,
    required int value,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPrivacyLevel = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedPrivacyLevel == value
              ? const Color(0xFF7B61FF).withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPrivacyLevel == value
                ? const Color(0xFF7B61FF)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedPrivacyLevel == value
                    ? const Color(0xFF7B61FF)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _selectedPrivacyLevel == value
                    ? Colors.white
                    : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedPrivacyLevel == value
                          ? const Color(0xFF7B61FF)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: value,
              groupValue: _selectedPrivacyLevel,
              onChanged: (int? val) {
                setState(() => _selectedPrivacyLevel = val ?? 1);
              },
              activeColor: const Color(0xFF7B61FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    if (_isLoadingBlocked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blockedUsers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.block, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No blocked users',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Users you block will appear here',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _blockedUsers.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF7B61FF),
              child: Text(
                user['name'][0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name']),
            subtitle: Text('Blocked ${_formatDate(user['blockedDate'])}'),
            trailing: TextButton(
              onPressed: () => _unblockUser(user['id']),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
              ),
              child: const Text('Unblock'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportedUsersList() {
    if (_reportedUsers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.flag, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No reports',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your report history will appear here',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reportedUsers.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final report = _reportedUsers[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: report['status'] == 'Resolved'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                report['status'] == 'Resolved'
                    ? Icons.check_circle
                    : Icons.pending,
                color: report['status'] == 'Resolved'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            title: Text(report['name']),
            subtitle: Text('Reason: ${report['reason']}'),
            trailing: Text(
              report['status'],
              style: TextStyle(
                color: report['status'] == 'Resolved'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTwoFactorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fingerprint,
                color: Color(0xFF7B61FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Two-Factor Authentication',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add an extra layer of security',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: false,
              onChanged: (value) {},
              activeColor: const Color(0xFF7B61FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download, color: Colors.blue),
            ),
            title: const Text('Export My Data'),
            subtitle: const Text('Download a copy of your data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show export dialog
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete, color: Colors.orange),
            ),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: Color(0xFFFF647C)),
                SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildEmergencyContact(
                    name: 'Police',
                    number: '100',
                    icon: Icons.local_police,
                  ),
                  const SizedBox(height: 8),
                  _buildEmergencyContact(
                    name: 'Ambulance',
                    number: '102',
                    icon: Icons.local_hospital,
                  ),
                  const SizedBox(height: 8),
                  _buildEmergencyContact(
                    name: 'Women Helpline',
                    number: '1091',
                    icon: Icons.female,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact({
    required String name,
    required String number,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF647C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF647C), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFF647C),
          ),
          child: const Text('Call'),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete account logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  backgroundColor: Color(0xFFFF647C),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF647C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Today';
    }
  }
}