import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/core/widgets/custom_button.dart';
import 'package:buddygoapp/core/widgets/custom_textfield.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';


class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '4');

  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedImage;
  String _groupType = 'public';
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  final List<String> _availableTags = [
    'Adventure',
    'Beach',
    'Mountains',
    'City',
    'Cultural',
    'Budget',
    'Luxury',
    'Party',
    'Family',
    'Backpacking',
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null
                        ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Trip Cover Photo in jpg Format',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              // Trip Title
              CustomTextField(
                controller: _titleController,
                label: 'Trip Title *',
                hintText: 'e.g., Goa Beach Adventure',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter trip title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Destination
              CustomTextField(
                controller: _destinationController,
                label: 'Destination *',
                hintText: 'e.g., Goa, India',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6E7A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectStartDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _startDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                      .format(_startDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? const Color(0xFF1A1D2B)
                                        : const Color(0xFFA0A8B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Date *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6E7A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectEndDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _endDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                      .format(_endDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? const Color(0xFF1A1D2B)
                                        : const Color(0xFFA0A8B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Budget & Members
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _budgetController,
                      label: 'Budget (₹) *',
                      hintText: '15000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter budget';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _maxMembersController,
                      label: 'Max Members *',
                      hintText: '4',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.people_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter max members';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description *',
                hintText: 'Describe your trip...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Tags
              const Text(
                'Add Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF7B61FF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF6E7A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Group Type
              const Text(
                'Visibility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Public'),
                      subtitle: const Text('Anyone can join'),
                      value: 'public',
                      groupValue: _groupType,
                      onChanged: (value) {
                        setState(() => _groupType = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Private'),
                      subtitle: const Text('Invite only'),
                      value: 'private',
                      groupValue: _groupType,
                      onChanged: (value) {
                        setState(() => _groupType = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Create Button
              CustomButton(
                text: 'Create Trip',
                isLoading: _isLoading,
                onPressed: _createTrip,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final firstDate = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createTrip() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null) {

      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be after start date'),
            backgroundColor: Color(0xFFFF647C),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authController = context.read<AuthController>();
        final user = authController.currentUser;

        if (user == null) {
          throw Exception('User not logged in');
        }

        final firebaseService = FirebaseService();
        String? imageUrl;

        // Upload image if selected
        if (_selectedImage != null) {
          imageUrl = await firebaseService.uploadImage(user.id, _selectedImage!.path);
        }

        // Create trip object
        final trip = Trip(
          id: '', // Will be set by Firebase
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          destination: _destinationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          maxMembers: int.parse(_maxMembersController.text),
          currentMembers: 1, // Host is first member
          budget: double.parse(_budgetController.text),
          hostId: user.id,
          hostName: user.name ?? 'Anonymous',
          hostImage: user.photoUrl ?? '',
          images: imageUrl != null ? [imageUrl] : [],
          tags: _selectedTags,
          isPublic: _groupType == 'public',
        );

        // Save to Firebase
        final tripId = await firebaseService.createTrip(trip);

        // Update user's trip count
        await authController.updateProfile();

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip created successfully!'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );

        // Navigate back after delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });

      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating trip: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF647C),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Color(0xFFFF647C),
        ),
      );
    }
  }
}