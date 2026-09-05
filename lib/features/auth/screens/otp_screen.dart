import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String userId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.userId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final  List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _secondsRemaining = 45;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onVerifyPressed() async {
    final code = _controllers.map((e) => e.text).join();
    if (code.length == 4) {
      setState(() => _isLoading = true);
      
      final authService = AppwriteAuthService();
      final session = await authService.verifyPhoneOtp(widget.userId, code);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (session != null) {
          // Success - Appwrite session created
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ওটিপি কোড সঠিক নয়। আবার চেষ্টা করুন।'),
              backgroundColor: Colors.deepOrange,
            ),
          );
        }
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('৪ ডিজিটের ওটিপি কোড সম্পূর্ণ প্রদান করুন')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.otpTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'ওটিপি কোড লিখুন',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  children: [
                    const TextSpan(text: 'আপনার '),
                    TextSpan(
                      text: widget.phoneNumber.isEmpty ? '017XXXXXXXX' : widget.phoneNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: ' নম্বরে পাঠানো ৪ ডিজিটের ওটিপি কোডটি লিখুন।'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // OTP Pin Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 60,
                    height: 64,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer / Resend
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: () async {
                          setState(() {
                            _secondsRemaining = 45;
                            _canResend = false;
                          });
                          _startTimer();
                          final authService = AppwriteAuthService();
                          await authService.sendPhoneOtp(widget.phoneNumber);
                        },
                        child: const Text(
                          AppStrings.resendOtp,
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      )
                    : Text(
                        'পুনরায় কোড পাঠাতে অপেক্ষা করুন: $_secondsRemaining সেকেন্ড',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
              ),
              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _onVerifyPressed,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.verifyOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
