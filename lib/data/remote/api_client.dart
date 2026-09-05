import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://api.nagardrishti.gov.bd/v1'; // Future Backend Base URL
  late final Dio _dio;

  ApiClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Future Auth Token Injection
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle API Errors gracefully
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Placeholder methods for future REST API integration
  Future<Response> sendOtp(String phone) async {
    return _dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<Response> verifyOtp(String phone, String code) async {
    return _dio.post('/auth/verify-otp', data: {'phone': phone, 'code': code});
  }

  Future<Response> fetchReports() async {
    return _dio.get('/reports');
  }

  Future<Response> submitReport(Map<String, dynamic> reportData) async {
    return _dio.post('/reports', data: reportData);
  }
}
