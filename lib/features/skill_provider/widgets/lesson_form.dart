import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../core/utils/lesson_image.dart';
import '../../../models/lesson.dart';
import '../services/storage_service.dart';
import '../utils/pick_local_image.dart';

/// Data class for lesson form submission.
class LessonFormData {
  const LessonFormData({
    required this.title,
    required this.description,
    required this.learningOutcomes,
    required this.category,
    required this.skillLevel,
    required this.duration,
    required this.lessonType,
    required this.exchangeType,
    required this.availableDays,
    required this.preferredTime,
    required this.location,
    required this.isFree,
    required this.price,
    required this.learningMaterials,
    required this.publishAsActive,
  });

  final String title;
  final String description;
  final String learningOutcomes;
  final LessonCategory category;
  final SkillLevel skillLevel;
  final String duration;
  final LessonType lessonType;
  final ExchangeType exchangeType;
  final List<String> availableDays;
  final String preferredTime;
  final String location;
  final bool isFree;
  final double? price;
  final List<String> learningMaterials;
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
  final _outcomesController = TextEditingController();
  final _materialsController = TextEditingController();

  LessonCategory? _category;
  SkillLevel? _skillLevel;
  String? _duration;
  LessonType? _lessonType;
  ExchangeType? _exchangeType;
  bool _isFree = true;
  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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

  static const _weekDayLabels = {
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sunday': 'Sun',
  };

  bool get isEditing => widget.initialLesson != null;

  bool get _isDraftLesson =>
      !isEditing || widget.initialLesson?.status == LessonStatus.draft;

  @override
  void initState() {
    super.initState();
    _populateFromLesson(widget.initialLesson);
  }

  void _populateFromLesson(Lesson? lesson) {
    if (lesson == null) return;

    _titleController.text = lesson.title;
    _descriptionController.text = lesson.description;
    _parsePreferredTime(lesson.availability.preferredTime);
    _locationController.text = lesson.location;
    _category = lesson.category;
    _skillLevel = lesson.skillLevel;
    _duration = _durationOptions.contains(lesson.duration) ? lesson.duration : null;
    _lessonType = lesson.lessonType;
    _exchangeType = lesson.exchangeType;
    _isFree = lesson.isFree;
    _imageUrl = lesson.imageUrl;
    _outcomesController.text = lesson.learningOutcomes.join('\n');
    _materialsController.text = lesson.learningMaterials.join('\n');
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
    _outcomesController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  LessonFormData? _collectFormData({required bool publishAsActive}) {
    if (publishAsActive) {
      if (!_formKey.currentState!.validate()) {
        return null;
      }

      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one available day.')),
        );
        return null;
      }

      if (_outcomesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning outcomes are required.')),
        );
        return null;
      }
    }

    final title = _titleController.text.trim();
    return LessonFormData(
      title: title.isEmpty ? 'Untitled draft' : title,
      description: _descriptionController.text.trim(),
      learningOutcomes: _outcomesController.text.trim(),
      category: _category ?? LessonCategory.other,
      skillLevel: _skillLevel ?? SkillLevel.beginner,
      duration: _duration ?? '',
      lessonType: _lessonType ?? LessonType.online,
      exchangeType: _exchangeType ?? ExchangeType.paid,
      availableDays: _selectedDays.toList(),
      preferredTime: _preferredTimeController.text.trim(),
      location: _locationController.text.trim(),
      isFree: _isFree,
      price: _isFree ? null : double.tryParse(_priceController.text.trim()),
      learningMaterials: _materialsController.text
          .trim()
          .split('\n')
          .where((s) => s.isNotEmpty)
          .toList(),
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

  void _parsePreferredTime(String preferredTime) {
    if (preferredTime.isEmpty) return;

    final parts = preferredTime.split('-').map((s) => s.trim()).toList();
    if (parts.length == 2) {
      _startTime = _parseTimeOfDay(parts[0]);
      _endTime = _parseTimeOfDay(parts[1]);
      if (_startTime != null && _endTime != null) {
        _preferredTimeController.text =
            '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}';
        return;
      }
    }

    _preferredTimeController.text = preferredTime;
  }

  TimeOfDay? _parseTimeOfDay(String text) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _pickPreferredTime() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Select start time',
    );
    if (start == null || !mounted) return;

    var endInitial = _endTime ?? TimeOfDay(hour: start.hour + 2, minute: start.minute);
    if (endInitial.hour >= 24) {
      endInitial = const TimeOfDay(hour: 23, minute: 59);
    }

    final end = await showTimePicker(
      context: context,
      initialTime: endInitial,
      helpText: 'Select end time',
    );
    if (end == null || !mounted) return;

    if (_timeToMinutes(end) <= _timeToMinutes(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() {
      _startTime = start;
      _endTime = end;
      _preferredTimeController.text =
          '${_formatTime(start)} - ${_formatTime(end)}';
    });
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

  Future<void> _pickAndUploadThumbnail() async {
    if (_isUploadingImage) return;

    try {
      final picked = await pickLocalImage();
      if (picked == null) return;

      final bytes = picked.bytes;
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read the selected image.')),
          );
        }
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _isUploadingImage = true;
      });

      final lessonId = widget.initialLesson?.id ??
          'draft_${DateTime.now().millisecondsSinceEpoch}';
      final fileName =
          picked.fileName.isNotEmpty ? picked.fileName : 'thumbnail.jpg';
      final url = await StorageService.instance.uploadLessonImage(
        lessonId: lessonId,
        bytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;

      if (url != null) {
        setState(() => _imageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail added successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not prepare the thumbnail. Try a smaller image.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file picker.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageIntro(),
          const SizedBox(height: 20),
          _buildSectionCard(
            icon: Icons.menu_book_outlined,
            title: 'Basic Information',
            subtitle: 'Tell learners what they will learn and who it is for.',
            child: Column(
              children: [
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
                TextFormField(
                  controller: _outcomesController,
                  decoration: const InputDecoration(
                    labelText: 'Learning Outcomes *',
                    hintText: 'One outcome per line',
                    helperText: 'List the skills or results learners can expect.',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildResponsivePair(
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
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      _durationOptions.contains(_duration) ? _duration : null,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Availability',
            subtitle: 'Choose the days and time learners can book.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Days *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 10),
                _buildDayChips(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _preferredTimeController,
                  readOnly: true,
                  onTap: _pickPreferredTime,
                  decoration: InputDecoration(
                    labelText: 'Preferred Time *',
                    hintText: 'Tap to select time range',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _pickPreferredTime,
                      tooltip: 'Pick time',
                    ),
                  ),
                  validator: (value) {
                    if (_startTime == null || _endTime == null) {
                      return 'Please select a preferred time range.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.tune_outlined,
            title: 'Lesson Details',
            subtitle: 'How you will teach and how learners can join.',
            child: Column(
              children: [
                _buildResponsivePair(
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
                  DropdownButtonFormField<ExchangeType>(
                    initialValue: _exchangeType,
                    decoration: const InputDecoration(labelText: 'Exchange Type *'),
                    items: ExchangeType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _exchangeType = value),
                    validator: (value) {
                      if (value == null) return 'Please select an exchange type.';
                      return null;
                    },
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.payments_outlined,
            title: 'Pricing',
            subtitle: 'Set whether this lesson is free or paid.',
            child: Column(
              children: [
                _buildPricingOptions(),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.folder_open_outlined,
            title: 'Learning Materials',
            subtitle: 'Optional resources learners can use before or after class.',
            child: TextFormField(
              controller: _materialsController,
              decoration: const InputDecoration(
                labelText: 'Materials (one per line)',
                hintText: 'PDF links, resource names, etc.',
                helperText: 'Add one material or link on each line.',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.image_outlined,
            title: 'Lesson Thumbnail',
            subtitle: 'A clear cover image helps your lesson stand out.',
            child: _buildImagePlaceholder(),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPageIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update your lesson' : 'Share your expertise',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Edit the details below. Saving will keep the current lesson status.'
                      : 'Fill in the details below, then save a draft or publish when you are ready.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildResponsivePair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildDayChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _weekDays.map((day) {
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(_weekDayLabels[day] ?? day),
          tooltip: day,
          selected: isSelected,
          showCheckmark: false,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
          selectedColor: AppTheme.primaryColor,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceTile(
            selected: _isFree,
            icon: Icons.volunteer_activism_outlined,
            title: 'Free',
            subtitle: 'No charge for learners',
            onTap: () => setState(() => _isFree = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildChoiceTile(
            selected: !_isFree,
            icon: Icons.attach_money,
            title: 'Paid',
            subtitle: 'Set a lesson price',
            onTap: () => setState(() => _isFree = false),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceTile({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.iconBackground : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnailPreview() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    final image = lessonImageProvider(_imageUrl);
    if (image != null) {
      return Image(image: image, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  Widget _buildImagePlaceholder() {
    final hasPreview = _imageBytes != null;
    final hasImage = hasPreview || lessonImageProvider(_imageUrl) != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isUploadingImage ? null : _pickAndUploadThumbnail,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 176,
          decoration: BoxDecoration(
            color: hasImage
                ? Colors.black
                : AppTheme.iconBackground.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage
                  ? Colors.transparent
                  : AppTheme.primaryLight.withValues(alpha: 0.7),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _thumbnailPreview(),
                      if (_isUploadingImage)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Tap to change thumbnail',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 26,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add a lesson thumbnail',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _imageUrl != null
                                ? 'Thumbnail uploaded'
                                : 'JPG, PNG, or WEBP from your files',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
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
                : Text(isEditing && !_isDraftLesson
                    ? widget.saveButtonLabel
                    : 'Save as Draft'),
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
                    _isDraftLesson ? 'Publish Lesson' : widget.saveButtonLabel,
                  ),
          );

          final helper = Text(
            _isDraftLesson
                ? 'Drafts stay private. You can save incomplete details, then publish when ready.'
                : 'Your updates will be saved to this lesson.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          );

          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                helper,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 12),
                    if (_isDraftLesson) ...[
                      Expanded(child: draftButton),
                      const SizedBox(width: 12),
                    ],
                    Expanded(flex: 2, child: publishButton),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              helper,
              const SizedBox(height: 16),
              if (_isDraftLesson) ...[
                draftButton,
                const SizedBox(height: 12),
              ],
              publishButton,
              const SizedBox(height: 12),
              cancelButton,
            ],
          );
        },
      ),
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
      imageUrl: _imageUrl ?? widget.initialLesson?.imageUrl,
      learningOutcomes: data.learningOutcomes
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList(),
      exchangeType: data.exchangeType,
      learningMaterials: data.learningMaterials,
      createdAt: createdAt ?? widget.initialLesson?.createdAt ?? now,
      updatedAt: now,
    );
  }
}
