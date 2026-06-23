import 'package:flutter_test/flutter_test.dart';

import 'package:bidding_app/models/app_models.dart';

void main() {
  test('Product status is derived from timing and manual end', () {
    final now = DateTime.now();

    final upcoming = Product(
      id: 'p1',
      title: 'Upcoming item',
      description: 'Starts later',
      startingPrice: 100,
      currentHighestBid: 100,
      startTime: now.add(const Duration(hours: 1)),
      duration: const Duration(hours: 2),
      isPublished: true,
      adminId: 'admin-1',
    );

    final live = Product(
      id: 'p2',
      title: 'Live item',
      description: 'Bidding now',
      startingPrice: 100,
      currentHighestBid: 120,
      startTime: now.subtract(const Duration(minutes: 10)),
      duration: const Duration(hours: 1),
      isPublished: true,
      adminId: 'admin-1',
    );

    final endedByTime = Product(
      id: 'p3',
      title: 'Ended item',
      description: 'Auction finished',
      startingPrice: 100,
      currentHighestBid: 150,
      startTime: now.subtract(const Duration(hours: 3)),
      duration: const Duration(hours: 1),
      isPublished: true,
      adminId: 'admin-1',
    );

    final endedManually = Product(
      id: 'p4',
      title: 'Closed item',
      description: 'Manually ended',
      startingPrice: 100,
      currentHighestBid: 150,
      startTime: now.subtract(const Duration(minutes: 10)),
      duration: const Duration(hours: 1),
      endedAt: now,
      isPublished: true,
      adminId: 'admin-1',
    );

    expect(upcoming.status, BidStatus.upcoming);
    expect(live.status, BidStatus.live);
    expect(endedByTime.status, BidStatus.ended);
    expect(endedManually.status, BidStatus.ended);
  });

  test('AppUser and Bid map round-trips preserve data', () {
    final createdAt = DateTime.parse('2026-06-23T10:00:00.000Z');
    final user = AppUser(
      uid: 'user-1',
      name: 'Test User',
      email: 'test@example.com',
      role: UserRole.admin,
      fcmToken: 'token-123',
      createdAt: createdAt,
    );

    final userRoundTrip = AppUser.fromMap(user.toMap(), user.uid);
    expect(userRoundTrip.uid, user.uid);
    expect(userRoundTrip.name, user.name);
    expect(userRoundTrip.email, user.email);
    expect(userRoundTrip.role, user.role);
    expect(userRoundTrip.fcmToken, user.fcmToken);
    expect(userRoundTrip.createdAt, createdAt);

    final bidTime = DateTime.parse('2026-06-23T11:00:00.000Z');
    final bid = Bid(
      id: 'bid-1',
      productId: 'product-1',
      userId: 'user-1',
      userName: 'Test User',
      amount: 250.5,
      timestamp: bidTime,
    );

    final bidRoundTrip = Bid.fromMap(bid.toMap(), bid.id);
    expect(bidRoundTrip.id, bid.id);
    expect(bidRoundTrip.productId, bid.productId);
    expect(bidRoundTrip.userId, bid.userId);
    expect(bidRoundTrip.userName, bid.userName);
    expect(bidRoundTrip.amount, bid.amount);
    expect(bidRoundTrip.timestamp, bidTime);
  });

  test('Notification map round-trip preserves core fields', () {
    final timestamp = DateTime.parse('2026-06-23T12:00:00.000Z');
    final notification = AppNotification(
      id: 'notif-1',
      userId: 'user-1',
      title: 'Auction won',
      body: 'You won the bid.',
      productId: 'product-1',
      isRead: false,
      timestamp: timestamp,
    );

    final roundTrip = AppNotification.fromMap(
      notification.toMap(),
      notification.id,
    );
    expect(roundTrip.id, notification.id);
    expect(roundTrip.userId, notification.userId);
    expect(roundTrip.title, notification.title);
    expect(roundTrip.body, notification.body);
    expect(roundTrip.productId, notification.productId);
    expect(roundTrip.isRead, notification.isRead);
    expect(roundTrip.timestamp, timestamp);
  });
}
