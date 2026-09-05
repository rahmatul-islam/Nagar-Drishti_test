import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/about/screens/about_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/heatmap_screen.dart';
import '../features/report/screens/create_report_screen.dart';
import '../features/report/screens/image_preview_screen.dart';
import '../features/report/screens/report_success_screen.dart';
import '../features/my_reports/screens/report_details_screen.dart';
import '../features/authority/screens/authority_dashboard_screen.dart';
import '../features/authority/screens/officer_dashboard_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/notification/screens/notification_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String about = '/about';
  static const String home = '/home';
  static const String createReport = '/create-report';
  static const String imagePreview = '/image-preview';
  static const String reportSuccess = '/report-success';
  static const String reportDetails = '/report-details';
  static const String authorityDashboard = '/authority-dashboard';
  static const String officerDashboard = '/officer-dashboard';
  static const String appSettings = '/settings';
  static const String heatmap = '/heatmap';
  static const String notifications = '/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case otp:
        final args = routeSettings.arguments as Map<String, String>? ?? {};
        final phone = args['phone'] ?? '';
        final userId = args['userId'] ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: phone, userId: userId),
        );

      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case createReport:
        return MaterialPageRoute(builder: (_) => const CreateReportScreen());

      case imagePreview:
        final imagePath = routeSettings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imagePath: imagePath),
        );

      case reportSuccess:
        final report = routeSettings.arguments as ReportModel;
        return MaterialPageRoute(
          builder: (_) => ReportSuccessScreen(report: report),
        );

      case reportDetails:
        final report = routeSettings.arguments as ReportModel;
        return MaterialPageRoute(
          builder: (_) => ReportDetailsScreen(report: report),
        );

      case authorityDashboard:
        return MaterialPageRoute(
            builder: (_) => const AuthorityDashboardScreen());

      case officerDashboard:
        final officerId = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => OfficerDashboardScreen(initialOfficerId: officerId),
        );

      case appSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case heatmap:
        return MaterialPageRoute(builder: (_) => const HeatmapScreen());

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );
    }
  }
}
