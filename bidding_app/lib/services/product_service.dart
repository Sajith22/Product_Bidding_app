// ─────────────────────────────────────────────────────────────────────────────
// services/product_service.dart
// All Firestore reads/writes for products and bids.
// Used by both admin and user screens.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_models.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference get _products => _db.collection('products');

  // ── ADMIN: Create product ─────────────────────────────────────────────────
  Future<String?> createProduct(Product product) async {
    try {
      final doc = _products.doc();
      await doc.set(product.toMap());
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // ── ADMIN: Upload product image (bytes) ────────────────────────────────────
  Future<String?> uploadProductImageBytes({
    required String productId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = (fileName.split('.').length > 1)
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      final safeExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';

      final ref = _storage.ref('products/$productId/main.$safeExt');
      final metadata = SettableMetadata(contentType: 'image/$safeExt');
      final task = await ref.putData(bytes, metadata);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ── ADMIN: Update product ─────────────────────────────────────────────────
  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _products.doc(productId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── ADMIN: Publish / Unpublish ────────────────────────────────────────────
  Future<bool> setPublished(String productId, bool published) async {
    return updateProduct(productId, {'isPublished': published});
  }

  // ── ADMIN: Delete product ─────────────────────────────────────────────────
  Future<bool> deleteProduct(String productId) async {
    try {
      await _products.doc(productId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── USER: Real-time stream of ALL published products ──────────────────────
  // Ordered by startTime ascending (Upcoming first, then Live, then Ended)
  Stream<List<Product>> watchPublishedProducts() {
    return _products
        .where('isPublished', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── ADMIN: Real-time stream of ALL products (including unpublished) ────────
  Stream<List<Product>> watchAllProducts() {
    return _products
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── Single product stream (for detail page real-time updates) ─────────────
  Stream<Product?> watchProduct(String productId) {
    return _products.doc(productId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Product.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  // ── Bid history stream for a product ─────────────────────────────────────
  Stream<List<Bid>> watchBids(String productId) {
    return _products
        .doc(productId)
        .collection('bids')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Bid.fromMap(d.data(), d.id))
            .toList());
  }

  // ── USER: Place a bid (Firestore transaction = race-condition safe) ────────
  Future<BidResult> placeBid({
    required String productId,
    required String userId,
    required String userName,
    required double amount,
  }) async {
    try {
      final productRef = _products.doc(productId);
      final bidRef = productRef.collection('bids').doc();

      return await _db.runTransaction<BidResult>((txn) async {
        final productSnap = await txn.get(productRef);

        if (!productSnap.exists) {
          return BidResult.failure('Product not found.');
        }

        final product = Product.fromMap(
            productSnap.data() as Map<String, dynamic>, productSnap.id);

        // ── Validate status ──────────────────────────────────────────────
        if (product.status != BidStatus.live) {
          return BidResult.failure(
              'Bidding is not active for this product.');
        }

        // ── Validate amount ──────────────────────────────────────────────
        final minRequired = product.currentHighestBid +
            (product.minIncrement ?? 1);
        if (amount < minRequired) {
          return BidResult.failure(
              'Your bid must be at least \$${minRequired.toStringAsFixed(2)}.');
        }

        // ── Write bid document ───────────────────────────────────────────
        final bid = Bid(
          id: bidRef.id,
          productId: productId,
          userId: userId,
          userName: userName,
          amount: amount,
          timestamp: DateTime.now(),
        );
        txn.set(bidRef, bid.toMap());

        // ── Update product highest bid ───────────────────────────────────
        txn.update(productRef, {
          'currentHighestBid': amount,
          'highestBidderId': userId,
          'highestBidderName': userName,
        });

        return BidResult.success(bid);
      });
    } on FirebaseException catch (e) {
      return BidResult.failure(e.message ?? 'Firestore error.');
    } catch (e) {
      return BidResult.failure('Failed to place bid. Please try again.');
    }
  }

  // ── Mark winner when bid ends (called by close-bid logic) ─────────────────
  Future<CloseProductResult> closeProduct(String productId) async {
    try {
      final productRef = _products.doc(productId);

      return await _db.runTransaction<CloseProductResult>((txn) async {
        final snap = await txn.get(productRef);
        if (!snap.exists) {
          return const CloseProductResult.failure('Product not found.');
        }

        final data = snap.data() as Map<String, dynamic>;
        final product = Product.fromMap(data, snap.id);

        // Already closed / already has winner
        if (product.endedAt != null || product.winnerId != null) {
          return CloseProductResult.success(
            productId: productId,
            winnerId: product.winnerId,
            winnerName: product.winnerName,
            winningBid: product.winningBid,
            didUpdate: false,
          );
        }

        // If no bids, just end the auction (no winner)
        if (product.highestBidderId == null) {
          txn.update(productRef, {
            'endedAt': DateTime.now().toIso8601String(),
          });
          return CloseProductResult.success(
            productId: productId,
            winnerId: null,
            winnerName: null,
            winningBid: null,
            didUpdate: true,
          );
        }

        final nowIso = DateTime.now().toIso8601String();
        txn.update(productRef, {
          'endedAt': nowIso,
          'winnerId': product.highestBidderId,
          'winnerName': product.highestBidderName,
          'winningBid': product.currentHighestBid,
        });

        return CloseProductResult.success(
          productId: productId,
          winnerId: product.highestBidderId,
          winnerName: product.highestBidderName,
          winningBid: product.currentHighestBid,
          didUpdate: true,
        );
      });
    } on FirebaseException catch (e) {
      return CloseProductResult.failure(e.message ?? 'Firestore error.');
    } catch (_) {
      return const CloseProductResult.failure('Failed to close auction.');
    }
  }
}

// ── Bid result wrapper ────────────────────────────────────────────────────────
class BidResult {
  final bool isSuccess;
  final Bid? bid;
  final String? errorMessage;

  const BidResult._({required this.isSuccess, this.bid, this.errorMessage});

  factory BidResult.success(Bid bid) =>
      BidResult._(isSuccess: true, bid: bid);

  factory BidResult.failure(String msg) =>
      BidResult._(isSuccess: false, errorMessage: msg);
}

class CloseProductResult {
  final bool isSuccess;
  final String? errorMessage;
  final String productId;
  final String? winnerId;
  final String? winnerName;
  final double? winningBid;
  final bool didUpdate; // true if this call actually updated the product doc

  const CloseProductResult._({
    required this.isSuccess,
    this.errorMessage,
    required this.productId,
    required this.winnerId,
    required this.winnerName,
    required this.winningBid,
    required this.didUpdate,
  });

  const CloseProductResult.success({
    required this.productId,
    required this.winnerId,
    required this.winnerName,
    required this.winningBid,
    required this.didUpdate,
  }) : isSuccess = true,
       errorMessage = null;

  const CloseProductResult.failure(String msg)
      : this._(
          isSuccess: false,
          errorMessage: msg,
          productId: '',
          winnerId: null,
          winnerName: null,
          winningBid: null,
          didUpdate: false,
        );
}
