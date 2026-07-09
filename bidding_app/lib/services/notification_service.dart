// services/notification_service.dart
// FIX: requestPermission() removed from automatic init() — browsers refuse
// permission prompts that aren't triggered by a real user click. init()
// now only sets up listeners/handlers, which is safe to do automatically.
// Call requestPermission() separately, from inside a real button's onPressed.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _db  = FirebaseFirestore.instance;

  void Function(RemoteMessage message)? onForegroundMessage;

  // ── Safe to call automatically at app startup — no permission prompt here ──
  Future<void> init() async {
    FirebaseMessaging.onMessage.listen((message) {
      onForegroundMessage?.call(message);
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ── NEW: call this from inside a real click handler, e.g. the Sign In
  // button's onPressed, as the very first synchronous line — before any
  // `await`. That's what makes the browser treat it as a genuine user
  // gesture instead of silently blocking it.
  Future<void> requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() => _fcm.getToken();

  Future<void> subscribeToProduct(String productId) =>
      _fcm.subscribeToTopic('product_$productId');

  Future<void> unsubscribeFromProduct(String productId) =>
      _fcm.unsubscribeFromTopic('product_$productId');

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

  Future<void> markRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}