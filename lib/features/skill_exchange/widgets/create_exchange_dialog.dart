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
  ExchangeCourse? _offeredCourse;
  ExchangeCourse? _targetCourse;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final myCourses = widget.provider.myCourses;
    final otherCourses = widget.provider.availableCourses
        .where((c) => c.ownerId != widget.provider.currentUser.id)
        .toList();

    _offeredCourse = widget.preselectedOfferedCourse ?? (myCourses.isNotEmpty ? myCourses.first : null);
    _targetCourse = widget.preselectedTargetCourse ?? (otherCourses.isNotEmpty ? otherCourses.first : null);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_offeredCourse == null || _targetCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both your offered course and the requested course.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.provider.sendExchangeRequest(
      offeredCourse: _offeredCourse!,
      targetCourse: _targetCourse!,
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
                      _targetCourse!.ownerRole != UserRole.student
                  ? 'Exchange request sent directly to peer tutor!'
                  : 'Exchange request submitted (awaiting tutor approval)!',
            ),
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
    final isDirectPeer = widget.provider.currentUser.isLecturerOrTutor &&
        (_targetCourse?.ownerRole != UserRole.student);

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
                DropdownButtonFormField<ExchangeCourse>(
                  initialValue: _offeredCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: myCourses.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _offeredCourse = val),
                ),
              const SizedBox(height: 14),

              // 2. Select Desired Target Course
              const Text('2. Course You Want In Exchange', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ExchangeCourse>(
                initialValue: _targetCourse,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: otherCourses.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text('${c.title} (${c.ownerName})', maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _targetCourse = val),
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
