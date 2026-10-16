import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_bookings.dart';
import '../models/booking_request.dart';
import 'session_service.dart';

class BookingService extends ChangeNotifier {
  BookingService._() {
    _bookings.addAll(createDemoBookings());
  }

  static final BookingService instance = BookingService._();
  static bool useMockData = false;

  static const _collection = 'bookingRequests';
  final List<BookingRequest> _bookings = [];

  String? _cachedProviderId;
  List<BookingRequest>? _cachedForProvider;
  DateTime? _cacheFetchedAt;
  static const _cacheMaxAge = Duration(seconds: 45);

  void _invalidateProviderCache([String? providerId]) {
    if (providerId == null ||
        providerId == _cachedProviderId ||
        _cachedProviderId == null) {
      _cachedProviderId = null;
      _cachedForProvider = null;
      _cacheFetchedAt = null;
    }
  }

  Future<List<BookingRequest>> getBookingsByProvider(
    String providerId, {
    bool forceRefresh = false,
  }) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _bookings
          .where((b) => b.providerId == providerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final cacheFresh = !forceRefresh &&
        _cachedProviderId == providerId &&
        _cachedForProvider != null &&
        _cacheFetchedAt != null &&
        DateTime.now().difference(_cacheFetchedAt!) < _cacheMaxAge;
    if (cacheFresh) {
      return List<BookingRequest>.from(_cachedForProvider!);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('providerId', isEqualTo: providerId)
          .get();
      final list = snapshot.docs.map(BookingRequest.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cachedProviderId = providerId;
      _cachedForProvider = list;
      _cacheFetchedAt = DateTime.now();
      return List<BookingRequest>.from(list);
    } catch (e) {
      debugPrint('Bookings load failed: $e');
      if (_cachedProviderId == providerId && _cachedForProvider != null) {
        return List<BookingRequest>.from(_cachedForProvider!);
      }
      rethrow;
    }
  }

  Future<BookingRequest?> getBookingById(String id) async {
    if (useMockData) {
      try {
        return _bookings.firstWhere((b) => b.id == id);
      } catch (_) {
        return null;
      }
    }
    final doc =
        await FirebaseFirestore.instance.collection(_collection).doc(id).get();
    return doc.exists ? BookingRequest.fromFirestore(doc) : null;
  }

  Future<void> acceptBooking(String id) async {
    _invalidateProviderCache();
    await _updateStatus(id, BookingStatus.accepted);
    final booking = await getBookingById(id);
    if (booking != null) {
      await SessionService.instance.createFromBooking(booking);
    }
  }

  Future<void> declineBooking(String id) async {
    _invalidateProviderCache();
    await _updateStatus(id, BookingStatus.declined);
  }

  Future<void> rescheduleBooking(String id, String reason) async {
    _invalidateProviderCache();
    if (useMockData) {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: BookingStatus.rescheduled,
          rescheduleReason: reason,
        );
        notifyListeners();
      }
      return;
    }
    await FirebaseFirestore.instance.collection(_collection).doc(id).update({
      'status': BookingStatus.rescheduled.name,
      'rescheduleReason': reason,
    });
    notifyListeners();
  }

  Future<void> _updateStatus(String id, BookingStatus status) async {
    if (useMockData) {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
        notifyListeners();
      }
      return;
    }
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(id)
        .update({'status': status.name});
    notifyListeners();
  }
}
