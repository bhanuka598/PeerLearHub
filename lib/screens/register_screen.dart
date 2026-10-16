import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/welcome_store.dart';
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

      final session = await AuthService.instance.resolveLoginSession();
      final redirectRoute =
          session.redirectRoute ??
          AppAuth.instance.getHomeRouteForRole(session.role);
      AppAuth.instance.setRoleFromApi(session.role);
      if (!mounted) return;
      context.go(redirectRoute);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showError(
          AuthService.instance.authErrorMessage(error),
          actionLabel: error.code == 'email-already-in-use' ? 'Log in' : null,
          onAction: error.code == 'email-already-in-use'
              ? () => context.push('/login')
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AuthFormShell(
        leading: AuthBackButton(
          fallbackRoute: WelcomeStore.seen ? '/login' : '/welcome',
        ),
        title: 'Create your account',
        subtitle: 'Join PeerLearnHub and start your learning journey.',
        footer: Column(
          children: [
            AuthFooterLink(
              prompt: 'Already have an account?',
              actionLabel: 'Sign in',
              onTap: () => context.push('/login'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthFieldLabel('Full name'),
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: authFieldDecoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Email address'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: authFieldDecoration(
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: authFieldDecoration(
                  hint: 'Create a password',
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
                validator: _validatePassword,
              ),
              const SizedBox(height: 6),
              Text(
                'Use at least 6 characters.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Confirm password'),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _register(),
                decoration: authFieldDecoration(
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
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
              const SizedBox(height: 20),
              const AuthFieldLabel('What do you want to achieve?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _learningGoals.map((goal) {
                  final selected = _selectedGoal == goal;
                  return FilterChip(
                    label: Text(goal),
                    selected: selected,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => setState(() => _selectedGoal = goal),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: const Color(0xFFF8FBFA),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFD5E3E0),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                    activeColor: AppTheme.primaryColor,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Text(
                        'I agree to the Terms & Conditions and Privacy Policy',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                label: 'Create account',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _register,
              ),
              const SizedBox(height: 20),
              const AuthSectionDivider(),
              const SizedBox(height: 16),
              SocialAuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                isLoading: _isGoogleSubmitting,
                onPressed: _isGoogleSubmitting ? null : _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
