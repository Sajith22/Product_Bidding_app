// services/notification_service.dart
// Rewritten — flutter_local_notifications REMOVED entirely.
// Its API has broken between versions repeatedly; it's not actually required
// by the assignment. FCM (firebase_messaging) handles background system
// notifications automatically. Foreground messages + the in-app bell/badge
// are handled via the Firestore-backed AppNotification stream below.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by this point.
  // Background system notifications are shown automatically by the OS
  // when the FCM payload includes a `notification` block — no extra
  // package needed for that.
}

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _db  = FirebaseFirestore.instance;

  /// Optional hook the UI can set to react to a foreground push
  /// (e.g. show a SnackBar / in-app banner). Safe to leave unset.
  void Function(RemoteMessage message)? onForegroundMessage;

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Request permission (iOS / Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Foreground message handler — just forwards to the optional hook,
    // and the Firestore AppNotification system covers the in-app bell/badge.
    FirebaseMessaging.onMessage.listen((message) {
      onForegroundMessage?.call(message);
    });

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ── Get FCM token ──────────────────────────────────────────────────────────
  Future<String?> getToken() => _fcm.getToken();

  // ── Topic subscriptions ────────────────────────────────────────────────────
  Future<void> subscribeToProduct(String productId) =>
      _fcm.subscribeToTopic('product_$productId');

  Future<void> unsubscribeFromProduct(String productId) =>
      _fcm.unsubscribeFromTopic('product_$productId');

  // ── Save in-app notification record to Firestore ───────────────────────────
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String? productId,
  }) async {
    final notif = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      productId: productId,
      isRead: false,
      timestamp: DateTime.now(),
    );
    await _db.collection('notifications').add(notif.toMap());
  }

  /// Save a notification exactly once (idempotent) using a deterministic
  /// document id. Useful for "winner" notifications where multiple clients
  /// might race to write the same event.
  Future<void> saveNotificationOnce({
    required String userId,
    required String key,
    required String title,
    required String body,
    String? productId,
  }) async {
    final docId = '${userId}_$key';
    final ref = _db.collection('notifications').doc(docId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) return;

      final notif = AppNotification(
        id: docId,
        userId: userId,
        title: title,
        body: body,
        productId: productId,
        isRead: false,
        timestamp: DateTime.now(),
      );
      txn.set(ref, notif.toMap());
    });
  }

  // ── Real-time notification stream for a user ───────────────────────────────
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Mark a notification as read ────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  // ── Unread count stream ────────────────────────────────────────────────────
  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}