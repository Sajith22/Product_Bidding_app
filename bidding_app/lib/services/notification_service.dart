// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_models.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final _fcm       = FirebaseMessaging.instance;
  final _db        = FirebaseFirestore.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'bidforge_channel',
      'BidForge Notifications',
      description: 'Auction results and bid alerts',
      importance: Importance.high,
    );

    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    // ── FIX: v17 requires named parameters ──────────────────────────────────
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle tap on notification if needed
      },
    );

    // Foreground FCM handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ── Get FCM token ──────────────────────────────────────────────────────────
  Future<String?> getToken() => _fcm.getToken();

  // ── Topic subscriptions ────────────────────────────────────────────────────
  Future<void> subscribeToProduct(String productId) =>
      _fcm.subscribeToTopic('product_$productId');

  Future<void> unsubscribeFromProduct(String productId) =>
      _fcm.unsubscribeFromTopic('product_$productId');

  // ── Show local notification for foreground messages ────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // ── FIX: v17 requires named parameters in show() ─────────────────────
    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bidforge_channel',
          'BidForge Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

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

  /// Save a notification exactly once (idempotent) using a deterministic document id.
  /// Useful for "winner" notifications where multiple clients may race.
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