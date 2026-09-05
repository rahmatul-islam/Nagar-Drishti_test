class Validators {
  /// Validates Bangladeshi phone numbers (e.g. 01712345678 or +8801712345678)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'অনুগ্রহ করে মোবাইল নম্বর প্রদান করুন';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\s+'), '');
    final bdPhoneRegex = RegExp(r'^(?:\+8801|01)[3-9]\d{8}$');
    if (!bdPhoneRegex.hasMatch(cleanPhone)) {
      return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 01712345678)';
    }
    return null;
  }

  /// Validates 4-digit OTP code
  static String? validateOtp(String? value) {
    if (value == null || value.trim().length != 4) {
      return '৪ ডিজিটের সঠিক ওটিপি দিন';
    }
    return null;
  }
}
