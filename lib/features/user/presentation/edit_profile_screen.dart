import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/core/widgets/custom_textfield.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/user/presentation/user_controller.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';

// ==================== CONSTANTS ====================
class EditProfileColors {
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
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedImageUrl;

  // Track if phone number changed
  bool _phoneNumberChanged = false;
  String? _originalPhoneNumber;

  late AnimationController _pulseAnimationController;

  final List<String> _interests = [
    'Adventure',
    'Beach',
    'Mountains',
    'Cultural',
    'Food',
    'Photography',
    'Backpacking',
    'Luxury',
    'Wildlife',
    'Travel',
    'Foodie Destination',
    'Group Travel',
    'Budget',
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadUserData();
    _phoneController.addListener(_onPhoneNumberChanged);
  }

  void _onPhoneNumberChanged() {
    setState(() {
      _phoneNumberChanged = _phoneController.text != _originalPhoneNumber;
    });
  }

  void _loadUserData() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userController = Provider.of<UserController>(context, listen: false);
    final user = authController.currentUser;

    if (user != null) {
      _nameController.text = user.name ?? '';
      _bioController.text = user.bio ?? '';
      _locationController.text = user.location ?? '';
      _phoneController.text = user.phone ?? '';
      _originalPhoneNumber = user.phone ?? '';
      _selectedImageUrl = user.photoUrl;
      _selectedInterests = user.interests ?? [];

      userController.updateProfile(
        name: user.name,
        bio: user.bio,
        location: user.location,
        imageUrl: user.photoUrl,
      );
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.removeListener(_onPhoneNumberChanged);
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 🔥 SIMPLE: Validate Indian phone number (10 digits and starts with +91 or 91)
  bool _isValidIndianPhoneNumber(String phone) {
    // Remove any spaces, dashes, parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it has +91 or 91 prefix
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91')) {
      cleaned = cleaned.substring(2);
    }

    // Should be exactly 10 digits and start with 6-9
    return cleaned.length == 10 &&
        RegExp(r'^[6-9]').hasMatch(cleaned) &&
        RegExp(r'^\d+$').hasMatch(cleaned);
  }

  // Check if phone number has proper format (+91 or 91 prefix)
  bool _hasValidIndianPrefix(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return cleaned.startsWith('+91') || cleaned.startsWith('91');
  }

  // Format phone number for display
  String _formatPhoneForDisplay(String phone) {
    if (phone.isEmpty) return phone;
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length == 10) {
      return '+91 $cleaned';
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+91 ${cleaned.substring(2)}';
    } else if (cleaned.startsWith('+91') && cleaned.length == 13) {
      return '+91 ${cleaned.substring(3)}';
    }
    return phone;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authController = context.read<AuthController>();
        final userController = context.read<UserController>();
        final firebaseService = FirebaseService();

        final user = authController.currentUser;
        if (user == null) throw Exception('User not logged in');

        String? imageUrl = _selectedImageUrl;

        if (_selectedImage != null) {
          imageUrl = await firebaseService.uploadImage(
            user.id,
            _selectedImage!.path,
          );
        }

        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'photoUrl': imageUrl,
          'interests': _selectedInterests,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 🔥 UPDATED: Phone number validation logic
        if (_phoneNumberChanged) {
          final phone = _phoneController.text.trim();
          updateData['phone'] = phone;

          // Auto-verify only if BOTH conditions are true:
          // 1. Has +91 or 91 prefix
          // 2. Is a valid 10-digit Indian number
          if (_hasValidIndianPrefix(phone) &&
              _isValidIndianPhoneNumber(phone)) {
            updateData['isPhoneVerified'] = true;
            print(
              '✅ Phone number verified with proper format (+91 and 10 digits)',
            );
          } else {
            updateData['isPhoneVerified'] = false;
            print(
              '⚠️ Phone number not verified - must have +91 and be valid 10-digit Indian number',
            );
          }
        }

        await firebaseService.updateUserProfile(user.id, updateData);

        await authController.updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          interests: _selectedInterests,
          phone: _phoneNumberChanged ? _phoneController.text.trim() : null,
        );

        userController.updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          imageUrl: imageUrl,
        );

        setState(() => _isLoading = false);

        String successMessage = 'Profile updated successfully!';
        if (_phoneNumberChanged) {
          if (_hasValidIndianPrefix(_phoneController.text.trim()) &&
              _isValidIndianPhoneNumber(_phoneController.text.trim())) {
            successMessage =
                'Profile updated and phone number verified! (+91 ${_phoneController.text.trim()})';
          } else {
            successMessage =
                'Profile updated. Please use format +91XXXXXXXXXX for verification.';
          }
        }

        _showSnackbar(
          successMessage,
          isSuccess:
              _phoneNumberChanged &&
              _hasValidIndianPrefix(_phoneController.text.trim()) &&
              _isValidIndianPhoneNumber(_phoneController.text.trim()),
        );

        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackbar('Error updating profile: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackbar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    Color getColor() {
      if (isError) return EditProfileColors.error;
      if (isSuccess) return EditProfileColors.success;
      return EditProfileColors.warning;
    }

    IconData getIcon() {
      if (isError) return Icons.error_outline;
      if (isSuccess) return Icons.check_circle;
      return Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: getColor(),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: EditProfileColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EditProfileColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.close, color: EditProfileColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [EditProfileColors.primary, EditProfileColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Edit Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: EditProfileColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: EditProfileColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          EditProfileColors.primary.withOpacity(0.1),
                          EditProfileColors.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        EditProfileColors.primary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Updating profile...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: EditProfileColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Animated Profile Image
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      EditProfileColors.primary,
                                      EditProfileColors.secondary,
                                      EditProfileColors.tertiary,
                                    ],
                                    stops: [0.3, 0.6, 0.9],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: EditProfileColors.primary
                                          .withOpacity(
                                            0.3 *
                                                _pulseAnimationController.value,
                                          ),
                                      blurRadius: 20,
                                      spreadRadius:
                                          5 * _pulseAnimationController.value,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            )
                                          : (_selectedImageUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl:
                                                        _selectedImageUrl!,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                              color: Colors
                                                                  .grey[100],
                                                            ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => Container(
                                                          color:
                                                              Colors.grey[100],
                                                          child: const Icon(
                                                            Icons.person,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    color: Colors.grey[100],
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: EditProfileColors
                                                          .primary,
                                                    ),
                                                  )),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        EditProfileColors.primary,
                                        EditProfileColors.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: EditProfileColors.primary
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        foregroundColor: EditProfileColors.primary,
                      ),
                      child: Text(
                        'Change Profile Photo',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: EditProfileColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Information Section
                    _buildSectionTitle(
                      'Personal Information',
                      EditProfileColors.primary,
                    ),
                    const SizedBox(height: 16),

                    // Name Field with Neon Style
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EditProfileColors.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: EditProfileColors.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field with enhanced validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: EditProfileColors.secondary.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hintText: 'Enter with +91 (e.g., +91 9876543210)',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: EditProfileColors.secondary,
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Phone validation status with enhanced UI
                        if (_phoneController.text.isNotEmpty) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getValidationColors(),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getValidationIcon(),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getValidationTitle(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getValidationMessage(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Current verification status
                        if (user?.isPhoneVerified == true &&
                            !_phoneNumberChanged)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  EditProfileColors.success,
                                  EditProfileColors.tertiary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Phone number verified',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email Field (Read-only with Neon Style)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EditProfileColors.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: EditProfileColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color: EditProfileColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: EditProfileColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  user?.email ?? 'No email',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: EditProfileColors.textPrimary,
                                  ),
                                ),
                                if (user?.isEmailVerified == true)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: EditProfileColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: EditProfileColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About Section
                    _buildSectionTitle(
                      'About You',
                      EditProfileColors.secondary,
                    ),
                    const SizedBox(height: 16),

                    // Bio Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EditProfileColors.secondary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        controller: _bioController,
                        label: 'Bio',
                        hintText: 'Tell us about yourself...',
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EditProfileColors.tertiary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        controller: _locationController,
                        label: 'Location',
                        hintText: 'e.g., Mumbai, India',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: EditProfileColors.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Interests Section
                    _buildSectionTitle(
                      'Travel Interests',
                      EditProfileColors.tertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your interests (tap to select)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: EditProfileColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInterestsGrid(),
                    const SizedBox(height: 32),

                    // Email Verification Section
                    if (!(user?.isEmailVerified ?? false)) ...[
                      _buildSectionTitle(
                        'Verification',
                        EditProfileColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              EditProfileColors.warning.withOpacity(0.1),
                              EditProfileColors.secondary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: EditProfileColors.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: EditProfileColors.warning.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: EditProfileColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email not verified',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: EditProfileColors.warning,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Verify your email to get a verified badge',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: EditProfileColors.warning
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    EditProfileColors.warning,
                                    EditProfileColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseAuth.instance.currentUser
                                        ?.sendEmailVerification();
                                    _showSnackbar(
                                      'Verification email sent!',
                                      isSuccess: true,
                                    );
                                  } catch (e) {
                                    _showSnackbar('Error: $e', isError: true);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Verify'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Student Verification
                    _buildSectionTitle(
                      'Student Verification',
                      EditProfileColors.lavender,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            EditProfileColors.lavender.withOpacity(0.1),
                            EditProfileColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: EditProfileColors.lavender.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: EditProfileColors.lavender.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: EditProfileColors.lavender,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student Verification',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: EditProfileColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.isStudentVerified ?? false
                                      ? 'Your student ID is verified'
                                      : 'Upload your student ID to get verified',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: EditProfileColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user?.isStudentVerified ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    EditProfileColors.success,
                                    EditProfileColors.tertiary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Verified',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    EditProfileColors.lavender,
                                    EditProfileColors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  _showSnackbar(
                                    'Student ID upload coming soon',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Upload'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button with Gradient
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            EditProfileColors.primary,
                            EditProfileColors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: EditProfileColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saveProfile,
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper methods for phone validation UI
  List<Color> _getValidationColors() {
    if (_hasValidIndianPrefix(_phoneController.text) &&
        _isValidIndianPhoneNumber(_phoneController.text)) {
      return [EditProfileColors.success, EditProfileColors.tertiary];
    } else if (_isValidIndianPhoneNumber(_phoneController.text)) {
      return [EditProfileColors.warning, EditProfileColors.secondary];
    } else {
      return [EditProfileColors.error, EditProfileColors.secondary];
    }
  }

  IconData _getValidationIcon() {
    if (_hasValidIndianPrefix(_phoneController.text) &&
        _isValidIndianPhoneNumber(_phoneController.text)) {
      return Icons.verified;
    } else if (_isValidIndianPhoneNumber(_phoneController.text)) {
      return Icons.warning;
    } else {
      return Icons.error_outline;
    }
  }

  String _getValidationTitle() {
    if (_hasValidIndianPrefix(_phoneController.text) &&
        _isValidIndianPhoneNumber(_phoneController.text)) {
      return 'Valid Indian Number';
    } else if (_isValidIndianPhoneNumber(_phoneController.text)) {
      return 'Missing +91 Prefix';
    } else {
      return 'Invalid Phone Number';
    }
  }

  String _getValidationMessage() {
    if (_hasValidIndianPrefix(_phoneController.text) &&
        _isValidIndianPhoneNumber(_phoneController.text)) {
      return 'This number will be auto-verified';
    } else if (_isValidIndianPhoneNumber(_phoneController.text)) {
      return 'Add +91 prefix to verify (e.g., +91 9876543210)';
    } else {
      return 'Must be 10 digits starting with 6-9';
    }
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EditProfileColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: EditProfileColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : EditProfileColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isSelected ? Colors.transparent : EditProfileColors.border,
              width: 1,
            ),
          ),
          elevation: isSelected ? 4 : 0,
          shadowColor: EditProfileColors.primary.withOpacity(0.3),
        );
      }).toList(),
    );
  }
}
