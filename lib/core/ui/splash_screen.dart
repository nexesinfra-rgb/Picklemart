import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/admin/application/admin_auth_controller.dart';
import '../config/splash_config.dart';
import '../layout/responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Play animation first (2 seconds)
    await _controller.forward();

    // Wait for auth controllers to initialize, then check auth state
    // Poll every 200ms until both are initialized (max 4 seconds)
    final maxWaitTime = DateTime.now().add(const Duration(seconds: 4));

    while (DateTime.now().isBefore(maxWaitTime)) {
      if (!mounted) return;

      final adminAuthState = ref.read(adminAuthControllerProvider);
      final authState = ref.read(authControllerProvider);

      // Check if both auth controllers have finished initializing
      if (adminAuthState.isInitialized && authState.isInitialized) {
        _checkAuthAndNavigate();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Fallback: check auth state after timeout
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    if (_hasNavigated || !mounted) return;

    // Check admin authentication first
    final adminAuthState = ref.read(adminAuthControllerProvider);
    if (adminAuthState.isAuthenticated) {
      _hasNavigated = true;
      context.goNamed('admin-dashboard');
      return;
    }

    // Check regular user authentication
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated) {
      _hasNavigated = true;
      context.goNamed('home');
      return;
    }

    // Not authenticated - go to role selection
    // Only navigate if we haven't already (from the timeout)
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      context.goNamed('admin-login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style for golden yellow background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final screenSize = Responsive.getScreenSize(context);
    final logoSize =
        screenSize == ScreenSize.mobile
            ? SplashConfig.logoSizeMobile
            : screenSize == ScreenSize.tablet
            ? SplashConfig.logoSizeTablet
            : SplashConfig.logoSizeUltraCompact;

    return Scaffold(
      backgroundColor: const Color(0xFFfbc801),
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _logoOpacityAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Image.asset(
                  'assets/picklemart.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _textOpacityAnimation,
                child: Column(
                  children: [
                    Text(
                      'with love from',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'nexes',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
