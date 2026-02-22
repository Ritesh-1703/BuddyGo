import 'package:buddygoapp/features/auth/presentation/change_password_screen.dart';
import 'package:buddygoapp/features/safety/presentation/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';

import '../../safety/presentation/terms_services_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  String _currency = 'INR (₹)';

  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French'];
  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationEnabled = prefs.getBool('location') ?? true;
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'INR (₹)';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('location', _locationEnabled);
    await prefs.setBool('darkMode', _darkModeEnabled);
    await prefs.setString('language', _language);
    await prefs.setString('currency', _currency);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> _rateApp() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      await _inAppReview.openStoreListing();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for supporting BuddyGo ❤️')),
    );
  }

  void _shareApp() {
    Share.share(
      'Hey! 👋 Check out BuddyGo – an awesome app to find travel buddies and plan trips together!\n\n'
      'Download now:\n'
      '👉 https://play.google.com/store/apps/details?id=com.yourcompany.buddygoapp',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      subtitle: 'Receive trip updates and messages',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.location_on,
                      title: 'Location Services',
                      subtitle: 'Share location for trip matching',
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() => _locationEnabled = value);
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() => _darkModeEnabled = value);
                        // TODO: Implement theme switching
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Preferences
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownItem(
                      icon: Icons.language,
                      title: 'Language',
                      value: _language,
                      items: _languages,
                      onChanged: (value) {
                        setState(() => _language = value!);
                      },
                    ),
                    _buildDropdownItem(
                      icon: Icons.attach_money,
                      title: 'Currency',
                      value: _currency,
                      items: _currencies,
                      onChanged: (value) {
                        setState(() => _currency = value!);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy & Security
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy & Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Color(0xFF7B61FF)),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.visibility_off,
                        color: Color(0xFF7B61FF),
                      ),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.description,
                        color: Color(0xFF7B61FF),
                      ),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsServicesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.info, color: Color(0xFF7B61FF)),
                      title: const Text('App Version'),
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.star, color: Color(0xFF7B61FF)),
                      title: const Text('Rate this App'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _rateApp();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.share,
                        color: Color(0xFF7B61FF),
                      ),
                      title: const Text('Share with Friends'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _shareApp();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: 'Save Settings',
                onPressed: _saveSettings,
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: 'Logout',
                backgroundColor: const Color(0xFFFF647C),
                onPressed: () async {
                  await authController.signOut();
                  // Navigate to login
                },
              ),
            ),

            // Delete Account (Danger Zone)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () {
                  _showDeleteAccountDialog();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF647C),
                  side: const BorderSide(color: Color(0xFFFF647C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('Delete Account')),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF7B61FF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF7B61FF),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7B61FF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete account logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested')),
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
}
