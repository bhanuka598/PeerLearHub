import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../models/lesson.dart';

/// Data class for lesson form submission.
class LessonFormData {
  const LessonFormData({
    required this.title,
    required this.description,
    required this.category,
    required this.skillLevel,
    required this.duration,
    required this.lessonType,
    required this.availableDays,
    required this.preferredTime,
    required this.location,
    required this.isFree,
    required this.price,
    required this.publishAsActive,
  });

  final String title;
  final String description;
  final LessonCategory category;
  final SkillLevel skillLevel;
  final String duration;
  final LessonType lessonType;
  final List<String> availableDays;
  final String preferredTime;
  final String location;
  final bool isFree;
  final double? price;
  final bool publishAsActive;
}

class LessonForm extends StatefulWidget {
  const LessonForm({
    super.key,
    this.initialLesson,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onPublish,
    this.showPublishButton = true,
    this.saveButtonLabel = 'Save Changes',
  });

  final Lesson? initialLesson;
  final VoidCallback onCancel;
  final Future<void> Function(LessonFormData data) onSaveDraft;
  final Future<void> Function(LessonFormData data) onPublish;
  final bool showPublishButton;
  final String saveButtonLabel;

  @override
  State<LessonForm> createState() => LessonFormState();
}

class LessonFormState extends State<LessonForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();

  LessonCategory? _category;
  SkillLevel? _skillLevel;
  String? _duration;
  LessonType? _lessonType;
  bool _isFree = true;
  bool _isSaving = false;
  final Set<String> _selectedDays = {};

  static const _durationOptions = [
    '30 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours',
    '3 hours',
  ];

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool get isEditing => widget.initialLesson != null;

  @override
  void initState() {
    super.initState();
    _populateFromLesson(widget.initialLesson);
  }

  void _populateFromLesson(Lesson? lesson) {
    if (lesson == null) return;

    _titleController.text = lesson.title;
    _descriptionController.text = lesson.description;
    _preferredTimeController.text = lesson.availability.preferredTime;
    _locationController.text = lesson.location;
    _category = lesson.category;
    _skillLevel = lesson.skillLevel;
    _duration = lesson.duration;
    _lessonType = lesson.lessonType;
    _isFree = lesson.isFree;
    _selectedDays.addAll(lesson.availability.availableDays);
    if (!lesson.isFree && lesson.price != null) {
      _priceController.text = lesson.price!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _preferredTimeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  LessonFormData? _collectFormData({required bool publishAsActive}) {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one available day.')),
      );
      return null;
    }

    return LessonFormData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      skillLevel: _skillLevel!,
      duration: _duration!,
      lessonType: _lessonType!,
      availableDays: _selectedDays.toList(),
      preferredTime: _preferredTimeController.text.trim(),
      location: _locationController.text.trim(),
      isFree: _isFree,
      price: _isFree ? null : double.tryParse(_priceController.text.trim()),
      publishAsActive: publishAsActive,
    );
  }

  Future<void> _handleSave({required bool publishAsActive}) async {
    final data = _collectFormData(publishAsActive: publishAsActive);
    if (data == null) return;

    setState(() => _isSaving = true);
    try {
      if (publishAsActive) {
        await widget.onPublish(data);
      } else {
        await widget.onSaveDraft(data);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _locationLabel() {
    switch (_lessonType) {
      case LessonType.online:
        return 'Meeting Platform / Online Details';
      case LessonType.inPerson:
        return 'Location';
      case LessonType.both:
        return 'Location / Meeting Details';
      case null:
        return 'Location / Meeting Details';
    }
  }

  String? _locationHint() {
    switch (_lessonType) {
      case LessonType.online:
        return 'e.g. Zoom, Google Meet link';
      case LessonType.inPerson:
        return 'e.g. Room 204, University Campus';
      case LessonType.both:
        return 'e.g. Campus Room or Zoom link';
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Lesson Title *',
              hintText: 'Introduction to Flutter Development',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lesson title is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe what learners will gain from this lesson',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<LessonCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category *'),
            items: LessonCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value),
            validator: (value) {
              if (value == null) {
                return 'Please select a category.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SkillLevel>(
            initialValue: _skillLevel,
            decoration: const InputDecoration(labelText: 'Skill Level *'),
            items: SkillLevel.values
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(level.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _skillLevel = value),
            validator: (value) {
              if (value == null) {
                return 'Please select a skill level.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _duration,
            decoration: const InputDecoration(labelText: 'Duration *'),
            items: _durationOptions
                .map(
                  (duration) => DropdownMenuItem(
                    value: duration,
                    child: Text(duration),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _duration = value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a duration.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Availability'),
          const SizedBox(height: 12),
          Text(
            'Available Days',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _preferredTimeController,
            decoration: const InputDecoration(
              labelText: 'Preferred Time *',
              hintText: 'e.g. 6:00 PM - 8:00 PM',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Preferred time is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Lesson Details'),
          const SizedBox(height: 12),
          DropdownButtonFormField<LessonType>(
            initialValue: _lessonType,
            decoration: const InputDecoration(labelText: 'Lesson Type *'),
            items: LessonType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _lessonType = value),
            validator: (value) {
              if (value == null) {
                return 'Please select a lesson type.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: '${_locationLabel()} *',
              hintText: _locationHint(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Pricing'),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Free')),
              ButtonSegment(value: false, label: Text('Paid')),
            ],
            selected: {_isFree},
            onSelectionChanged: (selection) {
              setState(() => _isFree = selection.first);
            },
          ),
          if (!_isFree) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (USD) *',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (_isFree) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid price.';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Image / Thumbnail'),
          const SizedBox(height: 12),
          _buildImagePlaceholder(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image upload will be available with Firebase Storage integration.',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add lesson thumbnail',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            Text(
              'Firebase Storage integration coming soon',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        final cancelButton = OutlinedButton(
          onPressed: _isSaving ? null : widget.onCancel,
          child: const Text('Cancel'),
        );

        final draftButton = OutlinedButton(
          onPressed: _isSaving ? null : () => _handleSave(publishAsActive: false),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? widget.saveButtonLabel : 'Save as Draft'),
        );

        final publishButton = ElevatedButton(
          onPressed: _isSaving ? null : () => _handleSave(publishAsActive: true),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.showPublishButton && !isEditing
                      ? 'Publish Lesson'
                      : widget.saveButtonLabel,
                ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cancelButton),
              const SizedBox(width: 12),
              if (widget.showPublishButton && !isEditing) ...[
                Expanded(child: draftButton),
                const SizedBox(width: 12),
              ],
              Expanded(child: publishButton),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showPublishButton && !isEditing) ...[
              draftButton,
              const SizedBox(height: 12),
            ],
            publishButton,
            const SizedBox(height: 12),
            cancelButton,
          ],
        );
      },
    );
  }

  Lesson buildLessonFromFormData(
    LessonFormData data, {
    String? id,
    String? providerId,
    LessonStatus? status,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return Lesson(
      id: id ?? widget.initialLesson?.id ?? '',
      providerId: providerId ?? widget.initialLesson?.providerId ?? AppConstants.demoProviderId,
      title: data.title,
      description: data.description,
      category: data.category,
      skillLevel: data.skillLevel,
      duration: data.duration,
      lessonType: data.lessonType,
      availability: LessonAvailability(
        availableDays: data.availableDays,
        preferredTime: data.preferredTime,
      ),
      location: data.location,
      isFree: data.isFree,
      price: data.isFree ? null : data.price,
      status: status ??
          (data.publishAsActive ? LessonStatus.active : LessonStatus.draft),
      imageUrl: widget.initialLesson?.imageUrl,
      createdAt: createdAt ?? widget.initialLesson?.createdAt ?? now,
      updatedAt: now,
    );
  }
}
