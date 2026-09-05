import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../data/remote/appwrite_client.dart';

class AiDetectionResult {
  final String category; // 'POTHOLE', 'GARBAGE', 'WATERLOGGING', 'BROKEN_STREET_LIGHT', 'OTHER'
  final double confidence; // Normalized decimal 0.0 - 1.0 (e.g. 0.91)
  final String description;
  final bool isRealAi;
  final bool isLowConfidence;

  AiDetectionResult({
    required this.category,
    required this.confidence,
    required this.description,
    this.isRealAi = false,
    this.isLowConfidence = false,
  });

  int get confidencePercentage => (confidence * 100).clamp(0, 100).round();
}

class AiService {
  static const double confidenceThreshold = 0.75;

  static const String categoryPothole = 'POTHOLE';
  static const String categoryGarbage = 'GARBAGE';
  static const String categoryWaterlogging = 'WATERLOGGING';
  static const String categoryBrokenLight = 'BROKEN_STREET_LIGHT';
  static const String categoryOther = 'OTHER';

  static const List<String> validCategories = [
    categoryPothole,
    categoryGarbage,
    categoryWaterlogging,
    categoryBrokenLight,
    categoryOther,
  ];

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Maps an AI-detected category to one of the manual dropdown values used
  /// on the Create Report form, so an AI prediction can prefill the
  /// citizen-editable category selector (AI suggestion + manual correction).
  static String toCreateReportCategory(String aiCategory) {
    switch (normalizeCategory(aiCategory)) {
      case categoryPothole:
        return 'Large pothole';
      case categoryGarbage:
        return 'Garbage/illegal dumping';
      case categoryWaterlogging:
        return 'Severe waterlogging';
      case categoryBrokenLight:
        return 'Broken street light';
      case categoryOther:
      default:
        return 'Other';
    }
  }

  /// Safely normalizes any category string into one of the 5 allowed target categories
  static String normalizeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return categoryOther;
    final clean = raw.trim().toUpperCase().replaceAll(' ', '_');

    if (clean.contains('POTHOLE') || clean.contains('HOLE') || clean.contains('CRACK')) {
      return categoryPothole;
    }
    if (clean.contains('GARBAGE') || clean.contains('TRASH') || clean.contains('WASTE') || clean.contains('DUMP')) {
      return categoryGarbage;
    }
    if (clean.contains('WATERLOGGING') || clean.contains('WATER_LOGGING') || clean.contains('FLOOD')) {
      return categoryWaterlogging;
    }
    if (clean.contains('BROKEN') || clean.contains('LIGHT') || clean.contains('LAMP') || clean.contains('STREETLIGHT')) {
      return categoryBrokenLight;
    }
    if (validCategories.contains(clean)) {
      return clean;
    }

    return categoryOther;
  }

  /// Analyzes an image via secure backend (Appwrite Function or secure HTTP API).
  /// NEVER exposes secret API keys in Flutter source code.
  Future<AiDetectionResult> detectIssue(
    String imagePath, {
    String? userDescription,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return _fallbackResult('চিত্র ফাইলটি পাওয়া যায়নি');
      }

      final imageBytes = await file.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 1. First attempt execution via Appwrite Function (backend secrets layer)
      final appwriteConfig = AppwriteClientConfig();
      if (AppwriteClientConfig.projectId != 'YOUR_APPWRITE_PROJECT_ID') {
        try {
          final execution = await appwriteConfig.functions.createExecution(
            functionId: 'classify-image',
            body: jsonEncode({
              'image': base64Image,
              'userDescription': userDescription ?? '',
            }),
          ).timeout(const Duration(seconds: 12));

          if (execution.status == 'completed' && execution.responseBody.isNotEmpty) {
            final parsed = _parseResponseJson(execution.responseBody);
            if (parsed != null) return parsed;
          }
        } catch (e) {
          debugPrint('Appwrite Function AI Execution fallback to secure endpoint: $e');
        }
      }

      // 2. Second attempt via secure environment endpoint if defined
      const secureEndpoint = String.fromEnvironment('AI_BACKEND_URL', defaultValue: '');
      if (secureEndpoint.isNotEmpty) {
        try {
          final response = await _dio.post(
            secureEndpoint,
            data: {
              'image': base64Image,
              'userDescription': userDescription ?? '',
            },
          );
          if (response.statusCode == 200 && response.data != null) {
            final parsed = _parseResponseJson(jsonEncode(response.data));
            if (parsed != null) return parsed;
          }
        } catch (e) {
          debugPrint('Secure AI Endpoint request error: $e');
        }
      }

      // 3. Fallback when backend AI function is not connected: Return unverified state so user selects manually
      return _fallbackResult('AI ক্লাউড সার্ভিস সংযোগ করা নেই। অনুগ্রহ করে ম্যানুয়ালি ক্যাটাগরি বেছে নিন।');

    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      return _fallbackResult('এআই বিশ্লেষণ ব্যর্থ হয়েছে');
    }
  }

  /// Parses standardized JSON response: {"category": "GARBAGE", "confidence": 0.91, "description": "..."}
  AiDetectionResult? _parseResponseJson(String rawResponseBody) {
    try {
      String cleaned = rawResponseBody.trim();
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      final Map<String, dynamic> json = jsonDecode(cleaned);
      final rawCat = json['category']?.toString();
      final category = normalizeCategory(rawCat);

      double confidence = 0.0;
      final rawConf = json['confidence'];
      if (rawConf is num) {
        confidence = rawConf.toDouble();
        if (confidence > 1.0) {
          confidence = confidence / 100.0; // Normalize percentage to decimal if needed
        }
      }
      confidence = confidence.clamp(0.0, 1.0);

      final description = json['description']?.toString() ?? 'এআই ভিশন বিশ্লেষণ সম্পন্ন হয়েছে।';
      final isLow = confidence < confidenceThreshold || category == categoryOther;

      return AiDetectionResult(
        category: category,
        confidence: confidence,
        description: description,
        isRealAi: true,
        isLowConfidence: isLow,
      );
    } catch (e) {
      debugPrint('AI Response parsing error: $e');
      return null;
    }
  }

  AiDetectionResult _fallbackResult(String message) {
    return AiDetectionResult(
      category: categoryOther,
      confidence: 0.0,
      description: message,
      isRealAi: false,
      isLowConfidence: true,
    );
  }
}
