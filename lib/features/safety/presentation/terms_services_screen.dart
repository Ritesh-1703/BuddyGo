import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsServicesScreen extends StatefulWidget {
  const TermsServicesScreen({super.key});

  @override
  State<TermsServicesScreen> createState() => _TermsServicesScreenState();
}

class _TermsServicesScreenState extends State<TermsServicesScreen> {
  final List<TermsSection> _sections = [
    TermsSection(
      title: '1. Acceptance of Terms',
      icon: Icons.check_circle_outline,
      content: '''
By accessing or using BuddyGO ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you may not use the App. We reserve the right to modify these Terms at any time, and your continued use of the App constitutes acceptance of any changes.''',
    ),
    TermsSection(
      title: '2. Eligibility',
      icon: Icons.person_outline,
      content: '''
You must be at least 18 years old to use BuddyGO. By using the App, you represent and warrant that you are 18 years or older and have the legal capacity to enter into these Terms. The App is intended for users who are looking for travel companions and group travel experiences.''',
    ),
    TermsSection(
      title: '3. Account Registration',
      icon: Icons.app_registration,
      content: '''
To use certain features of the App, you must create an account. You agree to provide accurate, current, and complete information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use.''',
    ),
    TermsSection(
      title: '4. User Conduct',
      icon: Icons.gavel,
      content: '''
You agree to use the App responsibly and agree not to:

• Harass, abuse, or harm other users
• Post false, misleading, or deceptive content
• Impersonate any person or entity
• Violate any applicable laws or regulations
• Share inappropriate or offensive material
• Attempt to gain unauthorized access to other accounts
• Use the App for commercial purposes without consent
• Engage in any activity that disrupts the App's functionality''',
    ),
    TermsSection(
      title: '5. User Content',
      icon: Icons.article_outlined,
      content: '''
You retain ownership of any content you post on BuddyGO. By posting content, you grant us a non-exclusive, royalty-free license to use, display, and distribute your content within the App. You represent that you have the right to share any content you post and that it does not violate any third-party rights.''',
    ),
    TermsSection(
      title: '6. Privacy',
      icon: Icons.privacy_tip_outlined,
      content: '''
Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using the App, you consent to our collection and use of information as described in the Privacy Policy. We do not share your personal information with third parties without your consent.''',
    ),
    TermsSection(
      title: '7. Safety & Verification',
      icon: Icons.security,
      content: '''
BuddyGO implements safety features including:
• Email and phone verification
• Optional student ID verification
• Face recognition for identity verification
• Block and report functionality
• Moderation of user content

However, we cannot guarantee the authenticity of all users. You are responsible for your own safety when interacting with others. We recommend meeting in public places and informing someone of your travel plans.''',
    ),
    TermsSection(
      title: '8. Trip Creation & Participation',
      icon: Icons.travel_explore,
      content: '''
When creating or joining trips:
• Trip creators are responsible for trip details and coordination
• Participants join at their own risk
• We are not liable for any disputes between trip members
• Trip cancellations should be communicated promptly
• You agree to respect trip rules set by the organizer
• Payment arrangements are between trip members only''',
    ),
    TermsSection(
      title: '9. Prohibited Activities',
      icon: Icons.block,
      content: '''
The following activities are strictly prohibited:
• Commercial solicitation without permission
• Posting spam or repetitive content
• Sharing contact information in public areas
• Creating fake or misleading profiles
• Organizing illegal activities
• Harassment or bullying of any kind
• Sharing explicit or offensive material''',
    ),
    TermsSection(
      title: '10. Reporting & Moderation',
      icon: Icons.flag,
      content: '''
We encourage users to report any violations of these Terms. Our moderation team reviews reports and may take action including:
• Issuing warnings
• Temporary suspension
• Permanent account ban
• Removal of content

False reports may result in action against the reporting account.''',
    ),
    TermsSection(
      title: '11. Intellectual Property',
      icon: Icons.copyright,
      content: '''
The App, including its design, logos, and original content, is owned by BuddyGO and protected by copyright and intellectual property laws. You may not copy, modify, distribute, or reverse engineer any part of the App without our express written consent.''',
    ),
    TermsSection(
      title: '12. Third-Party Links',
      icon: Icons.link,
      content: '''
The App may contain links to third-party websites or services. We are not responsible for the content or practices of these third parties. Your use of third-party services is at your own risk and subject to their terms and conditions.''',
    ),
    TermsSection(
      title: '13. Limitation of Liability',
      icon: Icons.gpp_bad,
      content: '''
To the maximum extent permitted by law, BuddyGO shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App. We are not responsible for any disputes, injuries, or losses that occur during trips arranged through the App.''',
    ),
    TermsSection(
      title: '14. Disclaimers',
      icon: Icons.warning_amber,
      content: '''
The App is provided "as is" without warranties of any kind. We do not guarantee that the App will be uninterrupted, secure, or error-free. We are not responsible for the conduct of any user, whether online or offline.''',
    ),
    TermsSection(
      title: '15. Termination',
      icon: Icons.exit_to_app,
      content: '''
We reserve the right to suspend or terminate your account at any time for violations of these Terms or for any other reason at our discretion. You may delete your account at any time through the App settings.''',
    ),
    TermsSection(
      title: '16. Governing Law',
      icon: Icons.gavel,
      content: '''
These Terms shall be governed by the laws of India. Any disputes arising from these Terms shall be resolved in the courts of Mumbai, India.''',
    ),
    TermsSection(
      title: '17. Changes to Terms',
      icon: Icons.update,
      content: '''
We may update these Terms from time to time. We will notify you of any material changes through the App or via email. Your continued use of the App after changes constitutes acceptance of the revised Terms.''',
    ),
    TermsSection(
      title: '18. Contact Information',
      icon: Icons.contact_mail,
      content: '''
For questions about these Terms, please contact us at:

Email: legal@buddygo.com
Address: BuddyGO Headquarters, Mumbai, India
Phone: +91 98765 43210''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _printTerms,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareTerms,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with last updated
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFF7B61FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D2B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Last Updated: February 22, 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Terms Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                return TermsSectionTile(
                  section: _sections[index],
                  isLast: index == _sections.length - 1,
                );
              },
            ),
          ),

          // Acceptance Footer
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'By using BuddyGO, you agree to these Terms',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 2.0.1',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'I Agree',
                    style: TextStyle(
                      color: Color(0xFF7B61FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _printTerms() {
    // Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
        backgroundColor: Color(0xFF7B61FF),
      ),
    );
  }

  void _shareTerms() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Color(0xFF7B61FF),
      ),
    );
  }
}

class TermsSection {
  final String title;
  final IconData icon;
  final String content;

  TermsSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class TermsSectionTile extends StatefulWidget {
  final TermsSection section;
  final bool isLast;

  const TermsSectionTile({
    super.key,
    required this.section,
    required this.isLast,
  });

  @override
  State<TermsSectionTile> createState() => _TermsSectionTileState();
}

class _TermsSectionTileState extends State<TermsSectionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
          elevation: _isExpanded ? 4 : 2,
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
                  widget.section.icon,
                  color: const Color(0xFF7B61FF),
                  size: 20,
                ),
              ),
              title: Text(
                widget.section.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2B),
                ),
              ),
              trailing: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF7B61FF),
              ),
              onExpansionChanged: (expanded) {
                setState(() => _isExpanded = expanded);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildContentParagraphs(widget.section.content),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContentParagraphs(String content) {
    final lines = content.split('\n');
    return lines.map((line) {
      if (line.trim().startsWith('•')) {
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B61FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.replaceFirst('•', '').trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A4A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (line.trim().isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.trim(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
              height: 1.5,
            ),
          ),
        );
      } else {
        return const SizedBox(height: 4);
      }
    }).toList();
  }
}

// Quick Summary Card Widget
class TermsSummaryCard extends StatelessWidget {
  const TermsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: const Color(0xFF7B61FF).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF7B61FF).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF7B61FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• You must be 18+ to use BuddyGO',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Be respectful and follow community guidelines',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Your safety is your responsibility',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 4),
            const Text(
              '• We can suspend accounts for violations',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Read full terms above'),
            ),
          ],
        ),
      ),
    );
  }
}