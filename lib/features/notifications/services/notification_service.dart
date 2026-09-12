import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../skill_provider/utils/provider_id_helper.dart';
import '../models/app_notification.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static bool useMockData = true;

  static const _collection = 'notifications';
  final List<AppNotification> _notifications = [];

  Future<AppNotification> createIfAbsent(AppNotification notification) async {
    final existing = await _findById(notification.id);
    if (existing != null) return existing;

    if (useMockData) {
      _notifications.add(notification);
      notifyListeners();
      return notification;
    }

    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(notification.id)
        .set(notification.toFirestore(), SetOptions(merge: true));
    _notifications.add(notification);
    notifyListeners();
    return notification;
  }

  Future<List<AppNotification>> getForCurrentUser() async {
    final items = await _all();
    return items.where(_visibleToCurrentUser).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCountForCurrentUser() {
    return _notifications.where(_visibleToCurrentUser).where((n) => !n.read).length;
  }

  Future<void> markRead(String id) async {
    if (useMockData) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
      return;
    }
    await FirebaseFirestore.instance.collection(_collection).doc(id).update({
      'read': true,
    });
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
    }
    notifyListeners();
  }

  Future<List<AppNotification>> _all() async {
    if (useMockData) {
      return List<AppNotification>.from(_notifications);
    }
    final snapshot =
        await FirebaseFirestore.instance.collection(_collection).get();
    _notifications
      ..clear()
      ..addAll(snapshot.docs.map(AppNotification.fromFirestore));
    return List<AppNotification>.from(_notifications);
  }

  Future<AppNotification?> _findById(String id) async {
    if (useMockData) {
      try {
        return _notifications.firstWhere((n) => n.id == id);
      } catch (_) {
        return null;
      }
    }
    final local = _notifications.cast<AppNotification?>().firstWhere(
      (n) => n?.id == id,
      orElse: () => null,
    );
    if (local != null) return local;
    final doc =
        await FirebaseFirestore.instance.collection(_collection).doc(id).get();
    return doc.exists ? AppNotification.fromFirestore(doc) : null;
  }

  bool _visibleToCurrentUser(AppNotification notification) {
    final role = AppAuth.instance.currentRole;
    if (useMockData) {
      if (role == AppUserRole.teacher || role == AppUserRole.admin) {
        return notification.recipientRole == NotificationRecipientRole.teacher;
      }
      return notification.recipientRole == NotificationRecipientRole.learner;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? getCurrentProviderId();
    if (notification.recipientId == uid) return true;
    if (notification.recipientId == AppConstants.demoProviderId &&
        (role == AppUserRole.teacher || uid == AppConstants.demoProviderId)) {
      return true;
    }
    return false;
  }
}
