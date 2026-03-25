import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../home/presentation/home_screen.dart';
import '/../core/widgets/custom_button.dart';
import '/../core/widgets/custom_textfield.dart';
import '/../features/auth/presentation/auth_controller.dart';

// ==================== CONSTANTS ====================
class RegisterColors {
  static const Color primary = Color(0xFF8B5CF6); // Purple
  static const Color secondary = Color(0xFFFF6B6B); // Coral
  static const Color tertiary = Color(0xFF4FD1C5); // Teal
  static const Color accent = Color(0xFFFBBF24); // Yellow
  static const Color lavender = Color(0xFF9F7AEA); // Lavender
  static const Color success = Color(0xFF06D6A0); // Mint Green
  static const Color error = Color(0xFFFF6B6B); // Coral for errors
  static const Color background = Color(0xFFF0F2FE); // Light purple tint
  static const Color warning = Color(0xFFFBBF24); // Yellow for warnings
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Gender selection
  String? _selectedGender;
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Date of Birth
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
      _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: RegisterColors.primary,
              onPrimary: Colors.white,
              surface: RegisterColors.surface,
              onSurface: RegisterColors.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: RegisterColors.background,
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
                color: RegisterColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: RegisterColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [RegisterColors.primary, RegisterColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [
                            RegisterColors.primary,
                            RegisterColors.tertiary,
                          ],
                          stops: [0.3, 0.9],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: RegisterColors.primary.withOpacity(
                              0.3 * _pulseAnimationController.value,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5 * _pulseAnimationController.value,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Name Field with Neon Style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.primary.withOpacity(0.1),
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
                      color: RegisterColors.primary,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Email Field with Neon Style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.secondary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'hello@example.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: RegisterColors.secondary,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Gender Selection Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.tertiary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RegisterColors.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.wc,
                                color: RegisterColors.tertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Gender',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: RegisterColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _genders.map((gender) {
                            final isSelected = _selectedGender == gender;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = gender;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                    colors: [
                                      RegisterColors.tertiary,
                                      RegisterColors.success,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : null,
                                  color: isSelected ? null : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : RegisterColors.border,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: RegisterColors.tertiary
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Text(
                                  gender,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : RegisterColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Date of Birth Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.lavender.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RegisterColors.lavender.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.cake,
                                color: RegisterColors.lavender,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Date of Birth',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: RegisterColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: RegisterColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: RegisterColors.lavender,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dateController.text.isEmpty
                                        ? 'Select your date of birth'
                                        : _dateController.text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: _dateController.text.isEmpty
                                          ? RegisterColors.textSecondary
                                          : RegisterColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: RegisterColors.lavender.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: RegisterColors.lavender,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password Field with Neon Style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Create a strong password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: RegisterColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: RegisterColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    obscureText: !_showPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Confirm Password Field with Neon Style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.secondary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: RegisterColors.secondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: RegisterColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(
                              () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Up Button with Gradient
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        RegisterColors.primary,
                        RegisterColors.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: RegisterColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedGender == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Please select your gender',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: RegisterColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                            return;
                          }

                          if (_selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Please select your date of birth',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: RegisterColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                            return;
                          }

                          // 🔥 UPDATED: Call signUpWithEmail with named parameters
                          final success = await authController.signUpWithEmail(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                            name: _nameController.text.trim(),
                            dateOfBirth: _selectedDate,
                            gender: _selectedGender?.toLowerCase(), // Convert to lowercase for consistency
                          );

                          if (success && context.mounted) {
                            // TODO: Save additional user data (gender, DOB) to Firestore
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => const HomeScreen(),
                            //   ),
                            // );
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text("Verify your email"),
                                content: Text(
                                  "A verification email has been sent to ${_emailController.text}. "
                                      "Please verify your email before logging in.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: authController.isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Create Account',
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

                const SizedBox(height: 24),

                // Terms with Neon Style
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: RegisterColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: RegisterColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'By signing up, you agree to our Terms & Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: RegisterColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}