import 'package:flutter/material.dart';
import 'dart:math';
// import 'package:crypton_frontend/services/storage_service.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _navigateAfterDelay();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  /// بررسی وضعیت لاگین و هدایت کاربر به مسیر مناسب
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    // final hasRefreshToken = await StorageService.getRefreshToken() != null;

    // if (!mounted) return;

    // final userRole = await StorageService.getUserRole();

    // if (hasRefreshToken) {
    //   Navigator.pushReplacementNamed(
    //     context,
    //     userRole == 'admin' ? '/admin/dashboard' : '/user/dashboard',
    //   );
    // } else {
    //   // در غیر این صورت، برو به لاگین
    //   Navigator.pushReplacementNamed(context, '/login');
    // }
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAsset =
        isDarkMode ? 'assets/icons/dark.png' : 'assets/icons/light.png';

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder:
              (_, __) => Transform.rotate(
                angle: _rotationAnimation.value,
                child: Image.asset(logoAsset, width: 120),
              ),
        ),
      ),
    );
  }
}
