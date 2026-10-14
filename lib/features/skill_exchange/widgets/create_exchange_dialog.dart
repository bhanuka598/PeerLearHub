import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';
import '../providers/skill_exchange_provider.dart';

class CreateExchangeDialog extends StatefulWidget {
  final SkillExchangeProvider provider;
  final ExchangeCourse? preselectedTargetCourse;
  final ExchangeCourse? preselectedOfferedCourse;

  const CreateExchangeDialog({
    super.key,
    required this.provider,
    this.preselectedTargetCourse,
    this.preselectedOfferedCourse,
  });

  @override
  State<CreateExchangeDialog> createState() => _CreateExchangeDialogState();
}

class _CreateExchangeDialogState extends State<CreateExchangeDialog> {
  String? _offeredCourseId;
  String? _targetCourseId;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final myCourses = widget.provider.myCourses;
    final otherCourses = widget.provider.availableCourses
        .where((c) => c.ownerId != widget.provider.currentUser.id)
        .toList();

    if (widget.preselectedOfferedCourse != null &&
        myCourses.any((c) => c.id == widget.preselectedOfferedCourse!.id)) {
      _offeredCourseId = widget.preselectedOfferedCourse!.id;
    } else {
      _offeredCourseId = myCourses.isNotEmpty ? myCourses.first.id : null;
    }

    if (widget.preselectedTargetCourse != null &&
        otherCourses.any((c) => c.id == widget.preselectedTargetCourse!.id)) {
      _targetCourseId = widget.preselectedTargetCourse!.id;
    } else {
      _targetCourseId = otherCourses.isNotEmpty ? otherCourses.first.id : null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final myCourses = widget.provider.myCourses;
    final otherCourses = widget.provider.availableCourses
        .where((c) => c.ownerId != widget.provider.currentUser.id)
        .toList();

    final effectiveOfferedId = _offeredCourseId ?? (myCourses.isNotEmpty ? myCourses.first.id : null);
    final effectiveTargetId = _targetCourseId ?? (otherCourses.isNotEmpty ? otherCourses.first.id : null);

    ExchangeCourse? offered;
    try {
      offered = myCourses.firstWhere((c) => c.id == effectiveOfferedId);
    } catch (_) {}

    ExchangeCourse? target;
    try {
      target = otherCourses.firstWhere((c) => c.id == effectiveTargetId);
    } catch (_) {}

    if (offered == null || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both your offered course and the requested course.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.provider.sendExchangeRequest(
      offeredCourse: offered,
      targetCourse: target,
      message: _messageController.text.trim().isEmpty
          ? 'Hi, I would love to exchange knowledge and collaborate!'
          : _messageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            content: Text(
              widget.provider.currentUser.isLecturerOrTutor &&
                      target.ownerRole != UserRole.student
                  ? 'Exchange request sent directly to peer tutor!'
                  : 'Exchange request submitted (awaiting tutor approval)!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(widget.provider.errorMessage ?? 'Failed to send request. Check your connection.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myCourses = widget.provider.myCourses;
    final otherCourses = widget.provider.availableCourses
        .where((c) => c.ownerId != widget.provider.currentUser.id)
        .toList();

    ExchangeCourse? target;
    try {
      target = otherCourses.firstWhere((c) => c.id == _targetCourseId);
    } catch (_) {}

    final isDirectPeer = widget.provider.currentUser.isLecturerOrTutor &&
        (target?.ownerRole != UserRole.student);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Propose Skill Swap',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Business Rule Notice Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDirectPeer ? Colors.blue.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDirectPeer ? Colors.blue.shade200 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDirectPeer ? Icons.verified : Icons.info_outline,
                      color: isDirectPeer ? Colors.blue.shade800 : Colors.amber.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDirectPeer
                            ? 'Rule 1: Direct Tutor Exchange -> Will be routed for Peer Tutor approval directly.'
                            : 'Rule 2: Student Initiated -> Will require explicit Tutor approval before activation.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDirectPeer ? Colors.blue.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Select Your Offered Course
              const Text('1. Course You Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (myCourses.isEmpty)
                const Text('No courses available to offer.', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  initialValue: myCourses.any((c) => c.id == _offeredCourseId) ? _offeredCourseId : myCourses.first.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: myCourses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _offeredCourseId = val),
                ),
              const SizedBox(height: 14),

              // 2. Select Desired Target Course
              const Text('2. Course You Want In Exchange', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (otherCourses.isEmpty)
                const Text('No courses available to request in exchange.', style: TextStyle(color: Colors.grey))
              else
                DropdownButtonFormField<String>(
                  initialValue: otherCourses.any((c) => c.id == _targetCourseId) ? _targetCourseId : otherCourses.first.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: otherCourses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text('${c.title} (${c.ownerName})', maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _targetCourseId = val),
                ),
              const SizedBox(height: 14),

              // Message
              const Text('3. Proposal Message (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe how this swap benefits both parties...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Exchange Request', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
