import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final List<PrivacySection> _sections = [
    PrivacySection(
      title: 'Information We Collect',
      icon: Icons.info_outline,
      content: '''
We collect the following types of information:

• Personal Information: Name, email address, phone number, date of birth
• Profile Information: Photos, bio, interests, travel preferences
• Verification Data: Student ID photos, face verification data
• Usage Data: Trip history, messages, interactions with other users
• Device Information: Device type, operating system, IP address
• Location Data: Approximate location for trip discovery''',
    ),
    PrivacySection(
      title: 'How We Use Your Information',
      icon: Icons.settings_applications,
      content: '''
Your information is used to:

• Create and manage your account
• Connect you with travel companions
• Verify your identity for safety
• Improve our services and user experience
• Send notifications and updates
• Ensure platform safety and security
• Comply with legal obligations''',
    ),
    PrivacySection(
      title: 'Information Sharing',
      icon: Icons.share,
      content: '''
We do not sell your personal information. We may share information:

• With other users as part of the service (profile information)
• With service providers who assist our operations
• When required by law or legal process
• To protect rights, safety, and property
• In connection with business transfers''',
    ),
    PrivacySection(
      title: 'Data Security',
      icon: Icons.security,
      content: '''
We implement security measures including:

• Encryption of sensitive data
• Secure servers and firewalls
• Regular security assessments
• Access controls and authentication
• Monitoring for suspicious activity

However, no method of transmission over the internet is 100% secure.''',
    ),
    PrivacySection(
      title: 'Your Rights',
      icon: Icons.gavel,
      content: '''
You have the right to:

• Access your personal information
• Correct inaccurate data
• Delete your account and data
• Export your data
• Opt-out of marketing communications
• Withdraw consent at any time''',
    ),
    PrivacySection(
      title: 'Cookies and Tracking',
      icon: Icons.cookie,
      content: '''
We use cookies and similar technologies to:

• Keep you logged in
• Remember your preferences
• Analyze app usage
• Improve performance
• Provide relevant content

You can control cookies through your browser settings.''',
    ),
    PrivacySection(
      title: 'Data Retention',
      icon: Icons.storage,
      content: '''
We retain your information as long as your account is active. If you delete your account, we will remove your information within 30 days, except where retention is required for legal purposes or legitimate business interests.''',
    ),
    PrivacySection(
      title: 'Children\'s Privacy',
      icon: Icons.child_care,
      content: '''
BuddyGO is not intended for users under 18. We do not knowingly collect information from children. If we learn that we have collected information from a child under 18, we will delete it promptly.''',
    ),
    PrivacySection(
      title: 'International Data Transfers',
      icon: Icons.public,
      content: '''
Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information in accordance with this policy.''',
    ),
    PrivacySection(
      title: 'Changes to Privacy Policy',
      icon: Icons.update,
      content: '''
We may update this policy from time to time. We will notify you of significant changes through the app or email. Your continued use after changes constitutes acceptance.''',
    ),
    PrivacySection(
      title: 'Contact Us',
      icon: Icons.contact_mail,
      content: '''
For privacy-related questions:

Email: privacy@buddygo.com
Address: BuddyGO Headquarters, Mumbai, India
Phone: +91 98765 43210''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
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
                    Icons.privacy_tip,
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
                        'Privacy Policy',
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
              ],
            ),
          ),
          const Divider(height: 1),

          // Privacy Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                return PrivacySectionTile(
                  section: _sections[index],
                  isLast: index == _sections.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacySection {
  final String title;
  final IconData icon;
  final String content;

  PrivacySection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class PrivacySectionTile extends StatefulWidget {
  final PrivacySection section;
  final bool isLast;

  const PrivacySectionTile({
    super.key,
    required this.section,
    required this.isLast,
  });

  @override
  State<PrivacySectionTile> createState() => _PrivacySectionTileState();
}

class _PrivacySectionTileState extends State<PrivacySectionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
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