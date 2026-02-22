import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FaqItem> _allFaqs = [
    FaqItem(
      question: 'How do I create a trip?',
      answer: 'To create a trip, go to the Discover tab and tap the "Create Trip" button. Fill in the details like destination, dates, budget, and description. Add a cover photo and select tags for your trip. Once done, tap "Create Trip" to publish it.',
      category: 'Trips',
      icon: Icons.travel_explore,
    ),
    FaqItem(
      question: 'How do I join an existing trip?',
      answer: 'Browse trips on the Discover page. Find a trip you like and tap "Join Trip". If the trip is public, you\'ll be added immediately. If it\'s private, the host will need to approve your request.',
      category: 'Trips',
      icon: Icons.group_add,
    ),
    FaqItem(
      question: 'How does group chat work?',
      answer: 'Once you join a trip, you\'re automatically added to the group chat. You can access it from the Chats tab. Here you can communicate with other trip members, share updates, and plan together.',
      category: 'Chat',
      icon: Icons.chat,
    ),
    FaqItem(
      question: 'How do I verify my account?',
      answer: 'Go to your Profile > Edit Profile. You can verify your email by tapping "Verify Email". For student verification, upload your student ID card. Our team will review it within 24-48 hours.',
      category: 'Account',
      icon: Icons.verified_user,
    ),
    FaqItem(
      question: 'How do I report a user?',
      answer: 'Go to the user\'s profile, tap the three dots menu, and select "Report User". Choose a reason and provide details. Our safety team will review the report and take appropriate action.',
      category: 'Safety',
      icon: Icons.flag,
    ),
    FaqItem(
      question: 'What should I do if I feel unsafe?',
      answer: 'Your safety is our priority. Immediately block the user from their profile. Report them to our team. In case of emergency, contact local authorities first.',
      category: 'Safety',
      icon: Icons.security,
    ),
    FaqItem(
      question: 'How do I delete my account?',
      answer: 'Go to Settings > Scroll to bottom > "Delete Account". Please note this action is permanent and all your data will be removed.',
      category: 'Account',
      icon: Icons.delete_forever,
    ),
    FaqItem(
      question: 'How do I change my password?',
      answer: 'Go to Settings > Privacy & Security > Change Password. Enter your current password and new password twice to confirm.',
      category: 'Account',
      icon: Icons.lock_reset,
    ),
    FaqItem(
      question: 'How do I leave a group?',
      answer: 'In the group chat, tap the info icon in the app bar, then select "Leave Group". Confirm your choice in the dialog.',
      category: 'Groups',
      icon: Icons.exit_to_app,
    ),
    FaqItem(
      question: 'Can I cancel a trip I created?',
      answer: 'Yes, go to "My Trips" tab, find your trip, tap "Edit" and select "Cancel Trip". All members will be notified.',
      category: 'Trips',
      icon: Icons.cancel,
    ),
    FaqItem(
      question: 'How are payments handled?',
      answer: 'BuddyGO doesn\'t handle payments between users. We recommend discussing payment details in the group chat and using secure payment methods.',
      category: 'Payments',
      icon: Icons.payment,
    ),
    FaqItem(
      question: 'What are the community guidelines?',
      answer: 'Be respectful, no harassment, no spam, no fake profiles. Respect others\' privacy. Follow local laws and regulations during trips.',
      category: 'Guidelines',
      icon: Icons.gavel,
    ),
  ];

  List<FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _allFaqs;
    return _allFaqs.where((faq) {
      return faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<String> get _categories {
    return _allFaqs.map((faq) => faq.category).toSet().toList();
  }

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Categories
          if (_searchQuery.isEmpty)
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      selectedColor: const Color(0xFF7B61FF),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: Colors.grey[100],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = _filteredFaqs[index];
                if (_selectedCategory != null &&
                    faq.category != _selectedCategory) {
                  return const SizedBox.shrink();
                }
                return FaqTile(faq: faq);
              },
            ),
          ),

          // Contact Support Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D2B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.email_outlined,
                        label: 'Email Us',
                        onTap: () => _launchEmail(),
                        color: const Color(0xFF7B61FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.chat_outlined,
                        label: 'Live Chat',
                        onTap: () => _startLiveChat(),
                        color: const Color(0xFF00D4AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.help_outline,
                        label: 'FAQs',
                        onTap: () {
                          _scrollToTop();
                        },
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.feedback_outlined,
                        label: 'Feedback',
                        onTap: () => _showFeedbackDialog(context),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTop() {
    // Implement scroll to top
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@buddygo.com',
      queryParameters: {
        'subject': 'Help Request - BuddyGO User',
      },
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email app'),
          backgroundColor: Color(0xFFFF647C),
        ),
      );
    }
  }

  void _startLiveChat() {
    // Navigate to live chat or show contact options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
            'Our support team is available:\n'
                'Monday - Friday: 9 AM - 6 PM\n'
                'Saturday: 10 AM - 4 PM\n'
                'Sunday: Closed'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We\'d love to hear your thoughts!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                // Submit feedback
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: Color(0xFF00D4AA),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  final String category;
  final IconData icon;

  FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    required this.icon,
  });
}

class FaqTile extends StatefulWidget {
  final FaqItem faq;

  const FaqTile({super.key, required this.faq});

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.faq.icon,
              color: const Color(0xFF7B61FF),
              size: 20,
            ),
          ),
          title: Text(
            widget.faq.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D2B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}