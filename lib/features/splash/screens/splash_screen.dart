import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _authService = AppwriteAuthService();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 2.2 seconds total splash duration
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    UserRole role;
    try {
      role = await _authService.getCurrentUserRole();
    } catch (_) {
      role = UserRole.unknown;
    }

    if (!mounted || _hasNavigated) return;

    final String targetRoute;
    switch (role) {
      case UserRole.admin:
        targetRoute = '/authority-dashboard';
        break;
      case UserRole.officer:
        targetRoute = '/officer-dashboard';
        break;
      case UserRole.citizen:
        targetRoute = '/home';
        break;
      case UserRole.unknown:
      default:
        targetRoute = '/welcome';
        break;
    }

    _hasNavigated = true;
    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildLogoWidget() {
    return Image.asset(
      AppAssets.logo,
      width: 72,
      height: 72,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback when assets/images/logo.png is not found
        // TODO: Replace fallback Icon with Image.asset('assets/images/logo.png') when asset file is placed in assets/images/
        return const Icon(
          Icons.remove_red_eye_rounded,
          size: 64,
          color: AppColors.primary,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.background, Color(0xFFEAF6F0)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth > 600 ? 48.0 : 24.0;
                return Center(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.14),
                                      blurRadius: 24,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: _buildLogoWidget(),
                              ),
                              const SizedBox(height: 26),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.appNameEn,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.appNameBn,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  AppStrings.taglineEn,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 44),
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
