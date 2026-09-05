import 'package:flutter/material.dart';

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PhoneInput({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: 'মোবাইল নম্বর',
        hintText: '01712345678',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          margin: const EdgeInsets.only(right: 10),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF006A4E),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF44336),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '+880',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
