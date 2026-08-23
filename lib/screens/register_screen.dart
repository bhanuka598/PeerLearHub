import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';
import '../core/auth/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/google_role_picker.dart';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
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
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) {
      return;
    }

    AppAuth.instance.setRole(AppUserRole.student);
    setState(() => _isSubmitting = false);
    context.go('/otp-verification');
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSubmitting = true);

    try {
      final success = await AppAuth.instance.signInWithGoogle();
      if (!mounted) {
        return;
      }

      if (success) {
        if (AppAuth.instance.currentRole == null) {
          final selectedRole = await GoogleRolePicker.show(context);
          if (!mounted) {
            return;
          }
          if (selectedRole == null ||
              !await AppAuth.instance.saveGoogleRole(selectedRole)) {
            _showError('Unable to save your selected role. Please try again.');
            return;
          }
          if (!mounted) {
            return;
          }
        }
        context.go(AppAuth.instance.getHomeRoute());
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.iconBackground,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Your Account',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join PeerLearnHub and start your learning journey.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What do you want to achieve?',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _learningGoals.map((goal) {
                          final selected = _selectedGoal == goal;
                          return ChoiceChip(
                            label: Text(goal),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedGoal = goal),
                            selectedColor: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppTheme.primaryDark
                                  : AppTheme.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value ?? false),
                        title: Text(
                          'I agree to the Terms & Conditions and Privacy Policy',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _register,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: textTheme.labelLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SocialAuthButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata_rounded,
                        isLoading: _isGoogleSubmitting,
                        onPressed: _isGoogleSubmitting
                            ? null
                            : _signInWithGoogle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Log In',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
