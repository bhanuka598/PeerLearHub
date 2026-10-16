import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/welcome_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/auth/auth_ui.dart';
import '../widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_handleEmailFocus);
    _passwordFocus.addListener(_handlePasswordFocus);
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_handleEmailFocus);
    _passwordFocus.removeListener(_handlePasswordFocus);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailFocus() => _centerFocusedField(_emailFocus);

  void _handlePasswordFocus() => _centerFocusedField(_passwordFocus);

  void _centerFocusedField(FocusNode node) {
    if (!node.hasFocus) {
      return;
    }

    void reveal() {
      final fieldContext = node.context;
      if (fieldContext == null || !fieldContext.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.42,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => reveal());
    Future<void>.delayed(const Duration(milliseconds: 320), reveal);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      final session = await AuthService.instance.resolveLoginSession();
      final redirectRoute =
          session.redirectRoute ??
          AppAuth.instance.getHomeRouteForRole(session.role);
      AppAuth.instance.setRoleFromApi(session.role);
      if (!mounted) return;
      context.go(redirectRoute);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showError(AuthService.instance.authErrorMessage(error));
      }
    } on Exception catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSubmitting = true);

    try {
      final success = await AppAuth.instance.signInWithGoogle();
      if (!mounted) {
        return;
      }

      if (success) {
        context.go(
          AppAuth.instance.currentRole == null
              ? '/select-role'
              : AppAuth.instance.getHomeRoute(),
        );
      } else {
        _showError(
          AuthService.instance.lastError ??
              'Google sign-in failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showError(
          AuthService.instance.lastError ??
              'Google sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFormShell(
        leading: context.canPop()
            ? const AuthBackButton(fallbackRoute: '/login')
            : WelcomeStore.seen
            ? const SizedBox(width: 44, height: 44)
            : const AuthBackButton(fallbackRoute: '/welcome'),
        title: 'Welcome back',
        subtitle: 'Sign in to continue learning and sharing skills.',
        footer: Column(
          children: [
            AuthFooterLink(
              prompt: "Don't have an account?",
              actionLabel: 'Sign up',
              onTap: () => context.push('/register'),
            ),
            const SizedBox(height: 8),
            AuthQuietLink(
              label: 'Register as Moderator',
              onTap: () => context.push('/moderation/register'),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screen = MediaQuery.sizeOf(context);
              final compact =
                  constraints.maxWidth < 360 || screen.height < 700;
              final gap = compact ? 12.0 : 16.0;
              final fieldScrollPadding = EdgeInsets.fromLTRB(
                20,
                screen.height * 0.16,
                20,
                MediaQuery.viewInsetsOf(context).bottom > 0
                    ? screen.height * 0.28
                    : 32,
              );
              return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthFieldLabel('Email address'),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                scrollPadding: fieldScrollPadding,
                decoration: authFieldDecoration(
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: _validateEmail,
              ),
              SizedBox(height: gap),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                scrollPadding: fieldScrollPadding,
                onFieldSubmitted: (_) => _login(),
                decoration: authFieldDecoration(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: gap),
              AuthPrimaryButton(
                label: 'Sign in',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _login,
              ),
              SizedBox(height: compact ? 14 : 20),
              const AuthSectionDivider(),
              SizedBox(height: gap),
              SocialAuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                isLoading: _isGoogleSubmitting,
                onPressed: _isGoogleSubmitting ? null : _signInWithGoogle,
              ),
            ],
              );
            },
          ),
        ),
      ),
    );
  }
}
