import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = AppwriteAuthService();
    final result = await authService.loginUser(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        final roleName = result.role == UserRole.admin
            ? 'সিটি এডমিন'
            : (result.role == UserRole.officer ? 'সিটি কর্মকর্তা' : 'নাগরিক');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $roleName হিসেবে সফলভাবে লগইন হয়েছে!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        if (result.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, '/authority-dashboard');
        } else if (result.role == UserRole.officer) {
          Navigator.pushReplacementNamed(context, '/officer-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'লগইনে সমস্যা হয়েছে! সঠিক ইমেইল ও পাসওয়ার্ড লিখুন।'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Main Auth Card Container
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'অ্যাকাউন্ট সাইন-ইন (Appwrite Authentication)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'আপনার নিবন্ধিত ইমেইল/মোবাইল এবং পাসওয়ার্ড লিখুন',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 20),

                        // Email / Phone Input Field
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'ইমেইল বা মোবাইল নম্বর',
                            hintText: 'admin@nagardrishti.gov.bd বা user@mail.com',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'অনুগ্রহ করে ইউজার আইডি/ইমেইল লিখুন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'পাসওয়ার্ড (Password)',
                            hintText: 'পাসওয়ার্ড প্রবেশ করুন',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _onLoginPressed,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('সাইন-ইন করুন (Login)'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Navigation Option
                Card(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.primaryLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'নতুন ব্যবহারকারী? অ্যাকাউন্ট নেই?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text('সাইন-আপ করুন', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Security Note Footer
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'নিরাপদ Appwrite সার্ভার অথেনটিকেশন ও এনক্রিপশন এনফোর্সড।',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
