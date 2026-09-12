import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/auth/auth_ui.dart';
import '../widgets/social_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _agreedToTerms = false;
  String _selectedGoal = 'Learn New Skills';

  final List<String> _learningGoals = [
    'Learn New Skills',
    'Improve Existing Skills',
    'Academic Learning',
    'Prepare for a Career',
    'Share My Skills',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
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

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      _showError('Please accept the Terms & Conditions and Privacy Policy');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.registerWithEmail(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        learningGoal: _selectedGoal,
      );
      if (!mounted) {
        return;
      }
      
      // Fetch user role from backend and respect the API redirect for moderators.
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
        _showError(
          AuthService.instance.authErrorMessage(error),
          actionLabel: error.code == 'email-already-in-use' ? 'Log in' : null,
          onAction: error.code == 'email-already-in-use'
              ? () => context.go('/login')
              : null,
        );
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AuthFormShell(
        leading: AuthBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: 'Create your account',
        subtitle:
            'Join PeerLearnHub and start your learning journey in minutes.',
        footer: AuthFooterLink(
          prompt: 'Already have an account?',
          actionLabel: 'Sign in',
          onTap: () => context.go('/login'),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Full name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
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
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Password',
                  hint: 'Create a password',
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
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: _fieldDecoration(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_reset_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 22),
              Text(
                'What do you want to achieve?',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _learningGoals.map((goal) {
                  final selected = _selectedGoal == goal;
                  return FilterChip(
                    label: Text(goal),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedGoal = goal),
                    selectedColor: AppTheme.iconBackground,
                    backgroundColor: const Color(0xFFF8FAFB),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE6EEF0),
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryDark
                          : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6EEF0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value ?? false),
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions and Privacy Policy',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Create account',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _register,
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