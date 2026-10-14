import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';
import '../core/widgets/auth/auth_ui.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                const Expanded(child: AuthBrandPanel(showHighlights: true)),
                Expanded(
                  child: AuthPageBackground(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: const _WelcomeContent(compact: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: AuthPageBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const _WelcomeContent(compact: true),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) ...[
          Row(
            children: [
              const AppLogo(size: 40, borderRadius: 14),
              const SizedBox(width: 12),
              Text(
                'PeerLearnHub',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: compact ? 190 : 210,
                height: compact ? 190 : 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryLight.withValues(alpha: 0.28),
                      AppTheme.primaryLight.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              AppLogo(size: compact ? 148 : 168, borderRadius: 36),
            ],
          ),
        ),
        SizedBox(height: compact ? 24 : 28),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.iconBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.primaryLight.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'Your peer learning community',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Learn. Share. Grow.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Discover new skills, learn from others, and share what you know.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const AuthFeatureTile(
          title: 'Discover Skills',
          subtitle: 'Find courses and learning content that match your goals.',
          icon: Icons.explore_outlined,
        ),
        const SizedBox(height: 12),
        const AuthFeatureTile(
          title: 'Learn & Progress',
          subtitle: 'Build skills through structured lessons and milestones.',
          icon: Icons.track_changes_rounded,
        ),
        const SizedBox(height: 12),
        const AuthFeatureTile(
          title: 'Share Knowledge',
          subtitle: 'Connect with peers and teach what you already know.',
          icon: Icons.people_alt_outlined,
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          label: 'Get Started',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/register'),
        ),
        const SizedBox(height: 12),
        AuthSecondaryButton(
          label: 'I already have an account',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Learn skills. Connect with people. Grow together.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
