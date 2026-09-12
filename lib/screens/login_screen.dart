import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
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
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      
      // Fetch user role from backend and send moderators straight to the dashboard.
      try {
        final loginData = await AuthService.instance.loginWithRole();
        final roleString = loginData['user']['role'] as String?;
        final redirectRoute = (loginData['redirectRoute'] as String?) ??
            AppAuth.instance.getHomeRouteForRole(roleString);

        AppAuth.instance.setRoleFromApi(roleString);
        context.go(redirectRoute);
        return;
      } catch (e) {
        final fallbackRole = await AuthService.instance.getCurrentUserRole();
        AppAuth.instance.setRoleFromApi(fallbackRole);
      }

      context.go(AppAuth.instance.getHomeRoute());
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

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EEF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EEF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFormShell(
        leading: AuthBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: 'Welcome back',
        subtitle:
            'Sign in to continue learning and sharing skills with your community.',
        footer: AuthFooterLink(
          prompt: "Don't have an account?",
          actionLabel: 'Sign up',
          onTap: () => context.go('/register'),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Email address',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: _fieldDecoration(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: 'Sign in',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _login,
              ),
              const SizedBox(height: 24),
              const AuthSectionDivider(),
              const SizedBox(height: 20),
              SocialAuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                isLoading: _isGoogleSubmitting,
                onPressed: _isGoogleSubmitting ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 12),
              SocialAuthButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/moderation/register'),
                  child: const Text(
                    'Register as Moderator',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}