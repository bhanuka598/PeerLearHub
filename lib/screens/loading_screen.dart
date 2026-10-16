import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/welcome_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';
import '../core/widgets/auth/auth_ui.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WelcomeStore.markSeen();
  }

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
                          constraints: const BoxConstraints(maxWidth: 440),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(child: AppLogo(size: compact ? 88 : 96, borderRadius: 26)),
        const SizedBox(height: 22),
        Text(
          'PeerLearnHub',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Learn. Share. Grow.',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Discover skills, learn from peers, and share what you know.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          label: 'Get Started',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.push('/register'),
        ),
        const SizedBox(height: 10),
        AuthSecondaryButton(
          label: 'I already have an account',
          onPressed: () => context.push('/login'),
        ),
        if (compact) ...[
          const SizedBox(height: 22),
          const _FeaturePanel(),
        ],
      ],
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel();

  static const _items = [
    (
      Icons.explore_outlined,
      'Discover',
      'Find courses that match your goals',
    ),
    (
      Icons.track_changes_rounded,
      'Learn',
      'Follow lessons and track progress',
    ),
    (
      Icons.people_alt_outlined,
      'Share',
      'Teach a skill you already know',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEEE)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _items.length; index++) ...[
            if (index > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _items[index].$1,
                      size: 20,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _items[index].$2,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _items[index].$3,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
