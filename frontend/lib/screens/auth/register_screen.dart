import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../main_navigation.dart';
import 'profile_completion_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _firstNameKey = GlobalKey();
  final _lastNameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _confirmPasswordKey = GlobalKey();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'male';
  String _selectedRole = 'talent';
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _scrollToFirstError() {
    // Scroll ke field pertama yang error
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_firstNameController.text.isEmpty) {
        Scrollable.ensureVisible(_firstNameKey.currentContext!);
      } else if (_lastNameController.text.isEmpty) {
        Scrollable.ensureVisible(_lastNameKey.currentContext!);
      } else if (_emailController.text.isEmpty ||
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(_emailController.text)) {
        Scrollable.ensureVisible(_emailKey.currentContext!);
      } else if (_passwordController.text.isEmpty ||
          _passwordController.text.length < 6) {
        Scrollable.ensureVisible(_passwordKey.currentContext!);
      } else if (_confirmPasswordController.text.isEmpty ||
          _confirmPasswordController.text != _passwordController.text) {
        Scrollable.ensureVisible(_confirmPasswordKey.currentContext!);
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      location: _locationController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registrasi gagal'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Status bar
          SliverToBoxAdapter(
            child: Container(
              height: 59,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.only(left: 10, bottom: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 21,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                                // Clock removed as requested
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: double.infinity,
                  ),
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.only(right: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(29),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Judul
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Back button dan Have account text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Have an account? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Login instead',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Form register
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _firstNameController,
                          hintText: 'First Name',
                          fieldKey: _firstNameKey,
                          errorText: _firstNameError,
                          onClearError: () {
                            setState(() {
                              _firstNameError = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _firstNameError = 'Nama depan diperlukan';
                              });
                              return '';
                            }
                            setState(() {
                              _firstNameError = null;
                            });
                            return null;
                          },
                        ),

                        SizedBox(height: _firstNameError != null ? 12 : 16),

                        _buildInputField(
                          controller: _lastNameController,
                          hintText: 'Last Name',
                          fieldKey: _lastNameKey,
                          errorText: _lastNameError,
                          onClearError: () {
                            setState(() {
                              _lastNameError = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _lastNameError = 'Nama belakang diperlukan';
                              });
                              return '';
                            }
                            setState(() {
                              _lastNameError = null;
                            });
                            return null;
                          },
                        ),

                        SizedBox(height: _lastNameError != null ? 12 : 16),

                        _buildInputField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          fieldKey: _emailKey,
                          errorText: _emailError,
                          onClearError: () {
                            setState(() {
                              _emailError = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _emailError = 'Email diperlukan';
                              });
                              return '';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              setState(() {
                                _emailError = 'Format email tidak valid';
                              });
                              return '';
                            }
                            setState(() {
                              _emailError = null;
                            });
                            return null;
                          },
                        ),

                        SizedBox(height: _emailError != null ? 12 : 16),

                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Create a Password',
                          obscureText: _obscurePassword,
                          fieldKey: _passwordKey,
                          errorText: _passwordError,
                          onClearError: () {
                            setState(() {
                              _passwordError = null;
                            });
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _passwordError = 'Password diperlukan';
                              });
                              return '';
                            }
                            if (value.length < 6) {
                              setState(() {
                                _passwordError = 'Password minimal 6 karakter';
                              });
                              return '';
                            }
                            setState(() {
                              _passwordError = null;
                            });
                            return null;
                          },
                        ),

                        SizedBox(height: _passwordError != null ? 12 : 16),

                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          fieldKey: _confirmPasswordKey,
                          errorText: _confirmPasswordError,
                          onClearError: () {
                            setState(() {
                              _confirmPasswordError = null;
                            });
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _confirmPasswordError =
                                    'Konfirmasi password diperlukan';
                              });
                              return '';
                            }
                            if (value != _passwordController.text) {
                              setState(() {
                                _confirmPasswordError = 'Password tidak sama';
                              });
                              return '';
                            }
                            setState(() {
                              _confirmPasswordError = null;
                            });
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Role Selection
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              hint: const Text('Select Role'),
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(
                                    value: 'talent',
                                    child: Text(
                                        '🔍 Looking for Job (Talent) - Default')),
                                DropdownMenuItem(
                                    value: 'company',
                                    child: Text('🏢 Hiring (Company)')),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Gender Selection
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              hint: const Text('Select Gender'),
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Other')),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date of Birth
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(
                                  const Duration(days: 6570)), // 18 years ago
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _dateOfBirthController.text =
                                    "${picked.day}/${picked.month}/${picked.year}";
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildInputField(
                              controller: _dateOfBirthController,
                              hintText: 'Date of Birth (DD/MM/YYYY)',
                              suffixIcon: const Icon(Icons.calendar_today),
                              validator: (value) {
                                // Date of birth is optional
                                return null;
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _locationController,
                          hintText: 'Enter your location (city/country)',
                          validator: (value) {
                            // Location is optional, no validation needed
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _phoneNumberController,
                          hintText: 'WhatsApp Number',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            // Phone number is optional, no validation needed
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Social sign up
                        const Text(
                          'Sign up with',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            final result =
                                await authProvider.signInWithGoogle();

                            if (result == 'success' && mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const MainNavigation()),
                              );
                            } else if (result == 'profile_incomplete' &&
                                mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileCompletionScreen()),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.error ??
                                      'Google Sign In gagal'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          "https://developers.google.com/identity/images/g-logo.png"),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Create Account button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          height: 1.50,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    GlobalKey? fieldKey,
    String? errorText,
    VoidCallback? onClearError,
  }) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: AppColors.error, width: 1)
                : null,
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 10,
                offset: Offset(1, 0),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: 1,
            onTap: onClearError,
            onChanged: (value) {
              if (onClearError != null) {
                onClearError();
              }

              // Auto-format email untuk field email
              if (hintText == 'Email' &&
                  value.isNotEmpty &&
                  !value.contains('@') &&
                  value.contains(' ')) {
                String formatted = value.replaceAll(' ', '@');
                controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
            decoration: InputDecoration(
              hintText: hintText,
              errorStyle: const TextStyle(height: 0),
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
          ),
        ),
        // Error message dengan space sendiri
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }
}
