import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';

class InteractionButtonInvert extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const InteractionButtonInvert({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(
          color: AppTheme.primaryColor,
          width: 2,
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          : Text(label),
    );
  }
}
