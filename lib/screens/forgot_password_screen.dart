import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../core/router/app_navigation.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/auth/auth_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.requestPasswordResetCode(
        _emailController.text,
      );
      if (mounted) {
        context.push(
          '/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}&mode=reset',
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFormShell(
        leading: const AuthBackButton(fallbackRoute: '/login'),
        title: 'Forgot Password?',
        subtitle:
            "Enter your email address and we'll send you instructions to reset your password.",
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ResetSteps(),
              const SizedBox(height: 18),
              const AuthFieldLabel('Email address'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onFieldSubmitted: (_) => _submit(),
                decoration: authFieldDecoration(
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) {
                    return 'Please enter your email address';
                  }
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                  if (!emailRegex.hasMatch(email)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'A 6-digit verification code will be sent to this email.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              AuthPrimaryButton(
                label: 'Send Verification Code',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 10),
              AuthSecondaryButton(
                label: 'Back to Login',
                onPressed: () => popOrGo(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetSteps extends StatelessWidget {
  const _ResetSteps();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ResetStep(number: '1', label: 'Email', active: true),
        _ResetStepLine(active: true),
        _ResetStep(number: '2', label: 'Code'),
        _ResetStepLine(),
        _ResetStep(number: '3', label: 'Reset'),
      ],
    );
  }
}

class _ResetStep extends StatelessWidget {
  const _ResetStep({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryDark : const Color(0xFF8B9694);

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.iconBackground : const Color(0xFFF3F6F6),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppTheme.primaryColor : const Color(0xFFD5E3E0),
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ResetStepLine extends StatelessWidget {
  const _ResetStepLine({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: active ? AppTheme.primaryLight : const Color(0xFFD5E3E0),
        ),
      ),
    );
  }
}
