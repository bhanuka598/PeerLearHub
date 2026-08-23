import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';
import 'package:peer_learn_hub/core/theme/app_spacing.dart';
import 'package:peer_learn_hub/core/theme/app_radius.dart';

class DropdownMenu extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onChanged;

  const DropdownMenu({
    Key? key,
    required this.label,
    required this.options,
    this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<DropdownMenu> {
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: AppTheme.primaryColor.withOpacity(_isFocused ? 0.3 : 0.1),
                  blurRadius: _isFocused ? 12 : 4,
                  offset: Offset(0, _isFocused ? 4 : 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(
                  color: _isFocused
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.3),
                  width: _isFocused ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedOption,
                  isExpanded: true,
                  focusNode: _focusNode,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.primaryColor,
                  ),
                  items: widget.options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(option),
                      ),
                    );
                  }).toList(),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
