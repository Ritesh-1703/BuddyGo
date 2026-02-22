import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/core/widgets/custom_textfield.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/user/presentation/user_controller.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedImageUrl;

  final List<String> _interests = [
    'Adventure', 'Beach', 'Mountains', 'Cultural',
    'Food', 'Photography', 'Backpacking', 'Luxury',
    'Solo Travel', 'Group Travel', 'Budget', 'Wildlife'
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      _selectedImageUrl = user.photoUrl;
      _selectedInterests = user.interests ?? [];

      // Update UserController with current values
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
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
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

        // Upload new image if selected
        if (_selectedImage != null) {
          imageUrl = await firebaseService.uploadImage(user.id, _selectedImage!.path);
        }

        // Update in Firebase
        await firebaseService.updateUserProfile(user.id, {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'photoUrl': imageUrl,
          'interests': _selectedInterests,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local controllers
        await authController.updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          interests: _selectedInterests,
        );

        userController.updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          imageUrl: imageUrl,
        );

        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );

        // Go back
        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF647C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7B61FF)),
            SizedBox(height: 16),
            Text('Updating profile...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7B61FF),
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_selectedImageUrl != null
                              ? NetworkImage(_selectedImageUrl!)
                              : const AssetImage('assets/images/default_avatar.png')) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B61FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: Color(0xFF7B61FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),

              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email Field (Read-only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            user?.email ?? 'No email',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionTitle('About You'),
              const SizedBox(height: 16),

              // Bio Field
              CustomTextField(
                controller: _bioController,
                label: 'Bio',
                hintText: 'Tell us about yourself...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Location Field
              CustomTextField(
                controller: _locationController,
                label: 'Location',
                hintText: 'e.g., Mumbai, India',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 24),

              // Interests Section
              _buildSectionTitle('Travel Interests'),
              const SizedBox(height: 8),
              Text(
                'Select your interests (tap to select)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _buildInterestsGrid(),
              const SizedBox(height: 32),

              // Verification Section (if not verified)
              if (!(user?.isEmailVerified ?? false)) ...[
                _buildSectionTitle('Verification'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email not verified',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify your email to get a verified badge',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Send verification email
                        },
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Student Verification
              _buildSectionTitle('Student Verification'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.isStudentVerified ?? false
                                ? 'Your student ID is verified'
                                : 'Upload your student ID to get verified',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user?.isStudentVerified ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          // Upload student ID
                        },
                        child: const Text('Upload'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button (for form submission)
              CustomButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D2B),
        ),
      ),
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
          selectedColor: const Color(0xFF7B61FF),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1A1D2B),
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}