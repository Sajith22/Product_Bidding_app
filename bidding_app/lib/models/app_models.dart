// ─────────────────────────────────────────────────────────────────────────────
// models/app_models.dart
// Shared data models used by BOTH admin and user sides.
// ─────────────────────────────────────────────────────────────────────────────

// ── Bid Status Enum ───────────────────────────────────────────────────────────
enum BidStatus { upcoming, live, ended }

extension BidStatusExt on BidStatus {
  String get label {
    switch (this) {
      case BidStatus.upcoming: return 'Upcoming';
      case BidStatus.live:     return 'Live';
      case BidStatus.ended:    return 'Ended';
    }
  }
}

// ── User Role Enum ────────────────────────────────────────────────────────────
enum UserRole { admin, user }

// ─────────────────────────────────────────────────────────────────────────────
// AppUser  →  Firestore: /users/{uid}
// ─────────────────────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? fcmToken;      // updated on every login
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.fcmToken,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.user,
      fcmToken: map['fcmToken'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role == UserRole.admin ? 'admin' : 'user',
    'fcmToken': fcmToken,
    'createdAt': createdAt.toIso8601String(),
  };

  AppUser copyWith({String? fcmToken}) => AppUser(
    uid: uid, name: name, email: email, role: role,
    fcmToken: fcmToken ?? this.fcmToken, createdAt: createdAt,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Product  →  Firestore: /products/{productId}
// ─────────────────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? category;
  final double startingPrice;
  final double currentHighestBid;
  final String? highestBidderId;
  final String? highestBidderName;
  final DateTime startTime;
  final Duration duration;          // bidding window length
  final DateTime? endedAt;          // manual/forced end (null = time-based only)
  final double? minIncrement;
  final bool isPublished;
  final String? winnerId;
  final String? winnerName;
  final double? winningBid;
  final String adminId;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.category,
    required this.startingPrice,
    required this.currentHighestBid,
    this.highestBidderId,
    this.highestBidderName,
    required this.startTime,
    required this.duration,
    this.endedAt,
    this.minIncrement,
    required this.isPublished,
    this.winnerId,
    this.winnerName,
    this.winningBid,
    required this.adminId,
  });

  /// Derived status — computed from current time vs startTime + duration
  BidStatus get status {
    if (endedAt != null) return BidStatus.ended;
    final now = DateTime.now();
    final endTime = startTime.add(duration);
    if (now.isBefore(startTime)) return BidStatus.upcoming;
    if (now.isAfter(endTime))    return BidStatus.ended;
    return BidStatus.live;
  }

  DateTime get endTime => startTime.add(duration);

  Duration get remaining {
    final r = endTime.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      category: map['category'],
      startingPrice: (map['startingPrice'] ?? 0).toDouble(),
      currentHighestBid: (map['currentHighestBid'] ?? 0).toDouble(),
      highestBidderId: map['highestBidderId'],
      highestBidderName: map['highestBidderName'],
      startTime: DateTime.parse(map['startTime']),
      duration: Duration(minutes: (map['durationMinutes'] ?? 2880)),
      endedAt: DateTime.tryParse(map['endedAt'] ?? ''),
      minIncrement: map['minIncrement']?.toDouble(),
      isPublished: map['isPublished'] ?? false,
      winnerId: map['winnerId'],
      winnerName: map['winnerName'],
      winningBid: map['winningBid']?.toDouble(),
      adminId: map['adminId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'category': category,
    'startingPrice': startingPrice,
    'currentHighestBid': currentHighestBid,
    'highestBidderId': highestBidderId,
    'highestBidderName': highestBidderName,
    'startTime': startTime.toIso8601String(),
    'durationMinutes': duration.inMinutes,
    'endedAt': endedAt?.toIso8601String(),
    'minIncrement': minIncrement,
    'isPublished': isPublished,
    'winnerId': winnerId,
    'winnerName': winnerName,
    'winningBid': winningBid,
    'adminId': adminId,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid  →  Firestore: /products/{productId}/bids/{bidId}
// ─────────────────────────────────────────────────────────────────────────────
class Bid {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double amount;
  final DateTime timestamp;

  const Bid({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.timestamp,
  });

  factory Bid.fromMap(Map<String, dynamic> map, String id) {
    return Bid(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      amount: (map['amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNotification  →  Firestore: /notifications/{notifId}
// ─────────────────────────────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? productId;
  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.productId,
    required this.isRead,
    required this.timestamp,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      productId: map['productId'],
      isRead: map['isRead'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'productId': productId,
    'isRead': isRead,
    'timestamp': timestamp.toIso8601String(),
  };
}
