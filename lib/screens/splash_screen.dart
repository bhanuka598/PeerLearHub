import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/welcome_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static bool hasCompleted = false;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _progress;
  late final Animation<Offset> _slide;
  late final Future<String> _destination;

  @override
  void initState() {
    super.initState();
    _destination = _resolveDestination();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.08, 0.46, curve: Curves.easeOutCubic),
          ),
        );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward().whenComplete(_openNext);
  }

  Future<String> _resolveDestination() async {
    final seenWelcome = await WelcomeStore.load();
    final restoredHome = await _restoredHome();
    if (restoredHome != null) {
      if (!seenWelcome) {
        await WelcomeStore.markSeen();
      }
      return restoredHome;
    }

    if (AppAuth.instance.currentRole != null) {
      return AppAuth.instance.getHomeRoute();
    }

    return seenWelcome ? '/login' : '/welcome';
  }

  Future<String?> _restoredHome() async {
    try {
      final user = await AuthService.instance.currentUserOrNull();
      if (user == null) {
        return null;
      }

      final session = await AuthService.instance.resolveLoginSession().timeout(
        const Duration(seconds: 5),
      );
      AppAuth.instance.setRoleFromApi(session.role);
      return session.redirectRoute ?? AppAuth.instance.getHomeRoute();
    } catch (error) {
      debugPrint('Saved session was not restored: $error');
      return null;
    }
  }

  Future<void> _openNext() async {
    if (!mounted) {
      return;
    }

    SplashScreen.hasCompleted = true;
    final destination = await _destination;
    if (!mounted) {
      return;
    }
    context.go(destination);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF006B62),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF006B62),
                AppTheme.primaryColor,
                Color(0xFF00B4A6),
              ],
              stops: [0.0, 0.46, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    blurRadius: 42,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const AppLogo(size: 128, showShadow: false),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'PeerLearnHub',
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SlideTransition(
                              position: _slide,
                              child: Text(
                                'Learn. Share. Grow.',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              width: 168,
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.22,
                                ),
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Preparing your learning space',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                        const SizedBox(height: 12),
                      ],
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
