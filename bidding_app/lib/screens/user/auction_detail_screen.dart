// screens/user/auction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/user_theme.dart';
import '../../models/app_models.dart';
import '../../services/product_service.dart';
import '../../services/notification_service.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Product product;
  const AuctionDetailScreen({super.key, required this.product});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _productService = ProductService();
  final _notifService   = NotificationService();

  double _bidAmount = 0;
  bool _placing = false;
  String? _bidError;
  String? _bidSuccess;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _userName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email?.split('@').first ??
      'User';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _productService.watchProduct(widget.product.id),
      builder: (context, snap) {
        final product = snap.data ?? widget.product;

        // Initialize bid amount when data first loads
        if (_bidAmount == 0) {
          _bidAmount = product.currentHighestBid +
              (product.minIncrement ?? 50);
        }

        // Check if current user just won
        final justWon = product.status == BidStatus.ended &&
            product.winnerId == _uid;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(product.title,
                overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border_rounded)),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined)),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: double.infinity,
                        height: Responsive.isMobile(context)
                            ? 240
                            : 320,
                        color: const Color(0xFF1E293B),
                        child: product.imageUrl != null
                            ? Image.network(product.imageUrl!,
                                fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.white30)),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // YOU WON banner
                            if (justWon) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8)
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.emoji_events_rounded,
                                        color: Colors.white, size: 36),
                                    SizedBox(height: 8),
                                    Text('YOU WON',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                            letterSpacing: 1)),
                                    SizedBox(height: 4),
                                    Text(
                                        'Congratulations! Your bid won this auction.',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Status bar
                            _StatusBar(product: product),

                            const SizedBox(height: 14),

                            Text(product.title,
                                style: UserTextStyles.h2),
                            const SizedBox(height: 4),
                            Text(product.description,
                                style: UserTextStyles.body.copyWith(
                                    color: UserTheme.textSecondary)),

                            const SizedBox(height: 16),

                            // Current bid card
                            _BidInfoCard(
                                product: product, uid: _uid),

                            const SizedBox(height: 16),

                            // Bid feedback
                            if (_bidError != null)
                              _Banner(
                                  message: _bidError!,
                                  color: UserTheme.errorRed,
                                  icon: Icons.error_outline_rounded),
                            if (_bidSuccess != null)
                              _Banner(
                                  message: _bidSuccess!,
                                  color: UserTheme.successGreen,
                                  icon: Icons.check_circle_rounded),

                            const SizedBox(height: 8),

                            // Bid history
                            _BidHistorySection(
                                productId: product.id),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bid bar — only show when live
              if (product.status == BidStatus.live)
                _BidBar(
                  bidAmount: _bidAmount,
                  minIncrement: product.minIncrement ?? 50,
                  isPlacing: _placing,
                  onAmountChanged: (v) =>
                      setState(() => _bidAmount = v),
                  onPlaceBid: () =>
                      _placeBid(product),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _placeBid(Product product) async {
    setState(() {
      _placing = true;
      _bidError = null;
      _bidSuccess = null;
    });

    // Get current user name from Firestore
    String userName = _userName;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] ?? _userName;
      }
    } catch (_) {}

    final result = await _productService.placeBid(
      productId: product.id,
      userId: _uid,
      userName: userName,
      amount: _bidAmount,
    );

    if (!mounted) return;

    setState(() {
      _placing = false;
      if (result.isSuccess) {
        _bidSuccess =
            'Your bid of \$${_bidAmount.toStringAsFixed(2)} was placed!';
        _bidAmount += (product.minIncrement ?? 50);
      } else {
        _bidError = result.errorMessage;
      }
    });
  }
}

// ── Status bar ────────────────────────────────────────────────────────────────
class _StatusBar extends StatefulWidget {
  final Product product;
  const _StatusBar({required this.product});

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.product.remaining;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _remaining = widget.product.remaining);
        if (_remaining > Duration.zero) _tick();
      }
    });
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (widget.product.status) {
      case BidStatus.live:
        color = UserTheme.errorRed;
        label = 'Live Auction — Ends in';
        break;
      case BidStatus.upcoming:
        color = UserTheme.warningGold;
        label = 'Starts in';
        break;
      case BidStatus.ended:
        color = UserTheme.textMuted;
        label = 'Auction Ended';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          if (widget.product.status != BidStatus.ended)
            Text(_format(_remaining),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

// ── Bid info card ─────────────────────────────────────────────────────────────
class _BidInfoCard extends StatelessWidget {
  final Product product;
  final String uid;
  const _BidInfoCard({required this.product, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isLeading = product.highestBidderId == uid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UserTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UserTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Highest Bid', style: UserTextStyles.label),
          const SizedBox(height: 4),
          Text('\$${product.currentHighestBid.toStringAsFixed(2)}',
              style: UserTextStyles.price),
          if (product.highestBidderName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: UserTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  isLeading
                      ? '🎯 You are leading!'
                      : 'Leading: ${product.highestBidderName}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isLeading
                          ? UserTheme.successGreen
                          : UserTheme.textSecondary,
                      fontWeight: isLeading
                          ? FontWeight.w700
                          : FontWeight.w400),
                ),
              ],
            ),
          ],
          if (product.minIncrement != null) ...[
            const SizedBox(height: 4),
            Text('Min increment: \$${product.minIncrement!.toStringAsFixed(0)}',
                style: UserTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

// ── Bid history section ───────────────────────────────────────────────────────
class _BidHistorySection extends StatelessWidget {
  final String productId;
  const _BidHistorySection({required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bid>>(
      stream: ProductService().watchBids(productId),
      builder: (context, snap) {
        final bids = snap.data ?? [];
        if (bids.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Bid History', style: UserTextStyles.h3),
                const SizedBox(width: 8),
                Text('${bids.length} bids',
                    style: UserTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),
            ...bids.take(5).map((bid) => _BidRow(bid: bid)),
          ],
        );
      },
    );
  }
}

class _BidRow extends StatelessWidget {
  final Bid bid;
  const _BidRow({required this.bid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: UserTheme.primaryBlue.withOpacity(0.1),
            child: Text(
              bid.userName.isNotEmpty
                  ? bid.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: UserTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(bid.userName, style: UserTextStyles.body),
          ),
          Text('\$${bid.amount.toStringAsFixed(2)}',
              style: UserTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Bid bar ───────────────────────────────────────────────────────────────────
class _BidBar extends StatelessWidget {
  final double bidAmount, minIncrement;
  final bool isPlacing;
  final Function(double) onAmountChanged;
  final VoidCallback onPlaceBid;

  const _BidBar({
    required this.bidAmount,
    required this.minIncrement,
    required this.isPlacing,
    required this.onAmountChanged,
    required this.onPlaceBid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: UserTheme.divider)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Minus
            _AdjBtn(
              icon: Icons.remove_rounded,
              onTap: () =>
                  onAmountChanged(bidAmount - minIncrement),
            ),
            const SizedBox(width: 10),
            // Amount display
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: UserTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: UserTheme.divider),
                ),
                child: Text(
                  '\$${bidAmount.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: UserTextStyles.h3.copyWith(
                      color: UserTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Plus
            _AdjBtn(
              icon: Icons.add_rounded,
              onTap: () =>
                  onAmountChanged(bidAmount + minIncrement),
            ),
            const SizedBox(width: 10),
            // Place bid
            SizedBox(
              width: 110,
              height: 46,
              child: ElevatedButton(
                onPressed: isPlacing ? null : onPlaceBid,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isPlacing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('PLACE BID',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AdjBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: UserTheme.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _Banner(
      {required this.message, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
