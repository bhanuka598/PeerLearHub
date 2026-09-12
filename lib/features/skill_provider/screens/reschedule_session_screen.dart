import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/booking_request.dart';
import '../services/booking_service.dart';
import '../widgets/app_header.dart';

class RescheduleSessionScreen extends StatefulWidget {
  const RescheduleSessionScreen({super.key, required this.booking});

  final BookingRequest booking;

  @override
  State<RescheduleSessionScreen> createState() =>
      _RescheduleSessionScreenState();
}

class _RescheduleSessionScreenState extends State<RescheduleSessionScreen> {
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _saving = false;

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rescheduling.')),
      );
      return;
    }
    setState(() => _saving = true);
    await BookingService.instance.rescheduleBooking(
      widget.booking.id,
      'New date: ${_selectedDate.toIso8601String().split('T').first} at ${_selectedTime.format(context)}. Reason: ${_reasonController.text.trim()}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reschedule request sent.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Reschedule Session'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reschedule for: ${widget.booking.lessonTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Learner: ${widget.booking.learnerName}',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New Date'),
                subtitle: Text(_selectedDate.toString().split(' ').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New Time'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rescheduling *',
                  hintText: 'Explain why the session needs to be rescheduled',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Send Reschedule Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
