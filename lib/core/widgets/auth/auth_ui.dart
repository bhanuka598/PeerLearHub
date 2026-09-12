import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_logo.dart';

const double _authBreakpoint = 900;
const double _authContentMaxWidth = 440;

class AuthPageBackground extends StatelessWidget {
  const AuthPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4FBFA),
            Color(0xFFF8FAFC),
            Colors.white,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6EEF0)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    super.key,
    this.compact = false,
    this.showHighlights = true,
  });

  final bool compact;
  final bool showHighlights;

  static const _highlights = [
    (
      icon: Icons.explore_outlined,
      title: 'Discover skills',
      subtitle: 'Find courses tailored to your goals.',
    ),
    (
      icon: Icons.track_changes_rounded,
      title: 'Track progress',
      subtitle: 'Learn with structure and momentum.',
    ),
    (
      icon: Icons.people_alt_outlined,
      title: 'Share knowledge',
      subtitle: 'Connect with learners and mentors.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006B62),
            AppTheme.primaryColor,
            Color(0xFF00B4A6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -32,
            child: _GlowCircle(
              size: compact ? 160 : 220,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -72,
            left: -40,
            child: _GlowCircle(
              size: compact ? 180 : 260,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 24 : 48,
                compact ? 24 : 40,
                compact ? 24 : 48,
                compact ? 28 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppLogo(
                        size: compact ? 40 : 48,
                        borderRadius: compact ? 14 : 16,
                        showShadow: false,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PeerLearnHub',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 24 : 40),
                  Text(
                    'Learn. Share. Grow.',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Discover new skills, learn from others, and share what you know in one collaborative space.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.55,
                    ),
                  ),
                  if (showHighlights) ...[
                    SizedBox(height: compact ? 24 : 36),
                    ..._highlights.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _BrandHighlight(
                          icon: item.icon,
                          title: item.title,
                          subtitle: item.subtitle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _authBreakpoint;

        if (isWide) {
          return Row(
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
                        constraints: const BoxConstraints(
                          maxWidth: _authContentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(height: 16),
                            ],
                            _AuthFormCard(
                              title: title,
                              subtitle: subtitle,
                              child: child,
                              footer: footer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return AuthPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      leading ?? const AuthBackButton(),
                      const Spacer(),
                      const AppLogo(size: 36, borderRadius: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _authContentMaxWidth,
                        ),
                        child: _AuthFormCard(
                          title: title,
                          subtitle: subtitle,
                          child: child,
                          footer: footer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                ),
          color: onPressed == null ? Colors.grey.shade300 : null,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD7E7E5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class AuthSectionDivider extends StatelessWidget {
  const AuthSectionDivider({super.key, this.label = 'or continue with'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE6EEF0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE6EEF0))),
      ],
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: '$prompt ',
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  actionLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFeatureTile extends StatelessWidget {
  const AuthFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F0F2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.iconBackground,
                  AppTheme.primaryLight.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F0F2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          child,
          if (footer != null) ...[
            const SizedBox(height: 20),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _BrandHighlight extends StatelessWidget {
  const _BrandHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
