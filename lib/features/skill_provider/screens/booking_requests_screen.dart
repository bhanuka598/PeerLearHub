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
  bool _loadInProgress = false;
  bool _reloadQueued = false;

  static const _filters = ['All', 'Pending', 'Accepted', 'Declined'];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _load(forceRefresh: false);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    _load(forceRefresh: true);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (_loadInProgress) {
      _reloadQueued = true;
      return;
    }
    _loadInProgress = true;
    final showSpinner = _bookings.isEmpty;
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    try {
      final providerId = await resolveProviderId();
      final list = await _service.getBookingsByProvider(
        providerId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _bookings = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    } finally {
      _loadInProgress = false;
      if (_reloadQueued) {
        _reloadQueued = false;
        await _load(forceRefresh: true);
      }
    }
  }

  List<BookingRequest> get _filtered {
    if (_filter == 'All') return _bookings;
    return _bookings.where((b) => b.status.name.toLowerCase() == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
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
              onRefresh: () => _load(forceRefresh: true),
              child: _filtered.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 72),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.teacherTintedCard(
                              AppTheme.teacherAccentAmber,
                            ),
                            child: const Text(
                              'No booking requests found.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => BookingCard(booking: _filtered[i]),
                    ),
            ),
    );
  }
}
