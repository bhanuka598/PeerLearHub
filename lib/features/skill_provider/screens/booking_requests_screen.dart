import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/booking_request.dart';
import '../services/booking_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/booking_card.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final _service = BookingService.instance;
  List<BookingRequest> _bookings = [];
  String _filter = 'All';
  bool _loading = true;

  static const _filters = ['All', 'Pending', 'Accepted', 'Declined'];

  @override
  void initState() {
    super.initState();
    _service.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _service.getBookingsByProvider(getCurrentProviderId());
    if (mounted) setState(() { _bookings = list; _loading = false; });
  }

  List<BookingRequest> get _filtered {
    if (_filter == 'All') return _bookings;
    return _bookings.where((b) => b.status.name.toLowerCase() == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TealPageHeader(
        title: 'Booking Requests',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TealFilterBar(
            filters: _filters,
            selectedFilter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No booking requests found.')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => BookingCard(booking: _filtered[i]),
                    ),
            ),
    );
  }
}
