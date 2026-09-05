import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import 'routes.dart';
import 'theme.dart';

class NagarDrishtiApp extends StatelessWidget {
  const NagarDrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
