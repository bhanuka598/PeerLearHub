import 'package:flutter/material.dart';
import 'package:peer_learn_hub/theme/app_spacing.dart';
import 'package:peer_learn_hub/theme/app_radius.dart';

class TextBox extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  const TextBox({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  @override
  State<TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<TextBox> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 300,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(_isFocused ? 0.3 : 0.1),
                  blurRadius: _isFocused ? 12 : 4,
                  offset: Offset(0, _isFocused ? 4 : 2),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              focusNode: _focusNode,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onBackground,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}