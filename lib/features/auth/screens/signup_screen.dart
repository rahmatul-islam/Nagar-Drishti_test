import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController(); // Phone or Email
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _areaController = TextEditingController();

  // bool _isAuthority = false; // Removed client-side authority signup
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উভয় পাসওয়ার্ড হুবহু এক হতে হবে!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = AppwriteAuthService();
    final result = await authService.signUpUser(
      name: _nameController.text.trim(),
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ নাগরিক অ্যাকাউন্ট সফলভাবে খোলা হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'নিবন্ধনে সমস্যা হয়েছে!'),
            backgroundColor: Colors.deepOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন একাউন্ট সাইন-আপ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'নগর দৃষ্টি পোর্টালে স্বাগতম',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'আপনার সঠিক তথ্য দিয়ে দ্রুত অ্যাকাউন্ট তৈরি করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Form Fields Container
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'পূর্ণ নাম (Full Name)',
                            hintText: 'যেমন: আব্দুল করিম',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'অনুগ্রহ করে আপনার নাম লিখুন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone or Email Input
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'মোবাইল নম্বর অথবা ইমেইল',
                            hintText: '017XXXXXXXX বা user@mail.com',
                            prefixIcon: Icon(Icons.phone_android_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'মোবাইল নম্বর বা ইমেইল লিখুন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Area / Ward Input
                        TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(
                            labelText: 'এলাকা / ওয়ার্ড নম্বর (Area)',
                            hintText: 'যেমন: মিরপুর ১০, ওয়ার্ড নং ৩',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'পাসওয়ার্ড (Password)',
                            hintText: 'কমপক্ষে ৮ অক্ষরের পাসওয়ার্ড',
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
                            if (val == null || val.length < 8) {
                              return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'পাসওয়ার্ড পুনরায় লিখুন',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val != _passwordController.text) {
                              return 'পাসওয়ার্ড দুটি হুবহু মিলছে না';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Sign Up Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _onSignUpPressed,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('সাইন-আপ সম্পন্ন করুন'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account? Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ইতিমধ্যে অ্যাকাউন্ট আছে? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'লগইন করুন',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
