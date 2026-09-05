import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter Framework Errors without terminating the app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Catch Uncaught Async Errors and return true to prevent "Application finished" termination on Web
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Caught Uncaught Async Error: $error');
    return true; // Prevents Flutter Web app termination
  };

  runApp(
    const ProviderScope(
      child: NagarDrishtiApp(),
    ),
  );
}
