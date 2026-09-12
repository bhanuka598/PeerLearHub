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
  static bool useMockData = true;

  static const _collection = 'bookingRequests';
  final List<BookingRequest> _bookings = [];

  Future<List<BookingRequest>> getBookingsByProvider(String providerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _bookings
          .where((b) => b.providerId == providerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(BookingRequest.fromFirestore).toList();
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
    await _updateStatus(id, BookingStatus.accepted);
    final booking = await getBookingById(id);
    if (booking != null) {
      await SessionService.instance.createFromBooking(booking);
    }
  }

  Future<void> declineBooking(String id) async {
    await _updateStatus(id, BookingStatus.declined);
  }

  Future<void> rescheduleBooking(String id, String reason) async {
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
