import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/safety/data/report_model.dart';

import '../../user/data/user_model.dart';

class ReportScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;
  final String? targetId; // Optional: for reporting specific trips/groups
  final ReportType reportType; // Type of report

  const ReportScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
    this.targetId,
    this.reportType = ReportType.user,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasReportedRecently = false;

  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _checkRecentReports();
  }

  Future<void> _checkRecentReports() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final reporterId = authController.currentUser?.id;

    if (reporterId != null) {
      final hasRecent = await _firebaseService.hasUserReportedRecently(
        reporterId: reporterId,
        reportedUserId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _hasReportedRecently = hasRecent;
        });
      }
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUser = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report User'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF7B61FF),
                      backgroundImage: widget.userImage != null
                          ? NetworkImage(widget.userImage!)
                          : null,
                      child: widget.userImage == null
                          ? Text(
                        widget.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D2B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getReportTypeText(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E7A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Report Warning
            if (_hasReportedRecently) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have already reported this user recently. Multiple reports may be reviewed for abuse.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Reason Selection
            const Text(
              'Select a reason for reporting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2B),
              ),
            ),
            const SizedBox(height: 16),
            ...ReportReason.values.map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<ReportReason>(
                  title: Text(reason.displayName),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  tileColor: Colors.grey[50],
                  activeColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 32),

            // Additional Details
            const Text(
              'Additional details (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Please provide any additional information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA940).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFA940).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Color(0xFFFFA940),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your report will be reviewed by our safety team. False reports may result in account suspension.',
                      style: TextStyle(
                        color: Color(0xFFFFA940),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: 'Submit Report',
              isLoading: _isSubmitting,
              backgroundColor: const Color(0xFFFF647C),
              onPressed: _selectedReason == null
                  ? null
                  : () => _submitReport(currentUser),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6E7A8A),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Center(
                  child: Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReportTypeText() {
    switch (widget.reportType) {
      case ReportType.user:
        return 'Report this user for inappropriate behavior';
      case ReportType.trip:
        return 'Report this trip for inappropriate content';
      case ReportType.group:
        return 'Report this group for inappropriate content';
      case ReportType.message:
        return 'Report this message for inappropriate content';
    }
  }

  Future<void> _submitReport(UserModel? currentUser) async {
    if (_selectedReason == null || currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Create report model
      final report = ReportModel(
        id: _uuid.v4(),
        reporterId: currentUser.id,
        reporterName: currentUser.name ?? 'Anonymous',
        reporterImage: currentUser.photoUrl,
        reportedUserId: widget.userId,
        reportedUserName: widget.userName,
        reportType: widget.reportType,
        targetId: widget.targetId,
        reason: _selectedReason!,
        details: _detailsController.text.isNotEmpty
            ? _detailsController.text
            : null,
        status: ReportStatus.pending,
      );

      // Submit to Firebase
      await _firebaseService.submitReport(report);

      setState(() => _isSubmitting = false);

      if (context.mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Color(0xFF00D4AA),
              size: 60,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Report Submitted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your report. Our safety team will review it within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'OK',
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close report screen
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: const Color(0xFFFF647C),
          ),
        );
      }
    }
  }
}