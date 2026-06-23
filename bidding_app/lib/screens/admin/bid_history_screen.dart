// ─────────────────────────────────────────────────────────────────────────────
// screens/admin/bid_history_screen.dart
// Replaces old bid_history_screen.dart — live Firestore stream.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../models/app_models.dart';
import '../../services/product_service.dart';
import '../../services/notification_service.dart';

class BidHistoryScreen extends StatelessWidget {
  final Product product;

  const BidHistoryScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final service = ProductService();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          product.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Admin can manually close auction
          if (product.status == BidStatus.live)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Close Auction?'),
                    content: const Text(
                        'This will end the bidding and declare a winner.'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        child: const Text('Close Auction'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final result = await service.closeProduct(product.id);
                  if (!result.isSuccess) return;

                  // Send winner notification (idempotent)
                  if (result.winnerId != null && result.winningBid != null) {
                    await NotificationService().saveNotificationOnce(
                      userId: result.winnerId!,
                      key: 'winner_${product.id}',
                      title: 'Auction won',
                      body:
                          'You won "${product.title}" with a bid of \$${result.winningBid!.toStringAsFixed(2)}.',
                      productId: product.id,
                    );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.gavel_rounded, size: 18),
              label: const Text('Close Auction'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            ),
        ],
      ),
      body: Column(
        children: [
          // Product summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Starting Price',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '\$${product.startingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppTheme.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Highest',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '\$${product.currentHighestBid.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
                if (product.highestBidderName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Leading Bidder',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                        product.highestBidderName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                if (product.status == BidStatus.ended &&
                    product.winnerName != null) ...[
                  const Divider(height: 20, color: AppTheme.border),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: AppTheme.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          product.winningBid != null
                              ? 'Winner: ${product.winnerName} — \$${product.winningBid!.toStringAsFixed(2)}'
                              : 'Winner: ${product.winnerName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bids header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Bid History',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                StreamBuilder<List<Bid>>(
                  stream: ProductService().watchBids(product.id),
                  builder: (_, snap) {
                    final count = snap.data?.length ?? 0;
                    return Text('$count bids',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bid list
          Expanded(
            child: StreamBuilder<List<Bid>>(
              stream: service.watchBids(product.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bids = snapshot.data!;
                if (bids.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('No bids placed yet',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: bids.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final bid = bids[i];
                    final isTop = i == 0;
                    return Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: isTop
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isTop
                              ? AppTheme.success.withOpacity(0.4)
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isTop
                                ? AppTheme.success.withOpacity(0.2)
                                : AppTheme.border,
                            child: Text(
                              bid.userName.isNotEmpty
                                  ? bid.userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isTop
                                    ? AppTheme.success
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(bid.userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    if (isTop) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('LEADING',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTime(bid.timestamp),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${bid.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isTop
                                  ? AppTheme.success
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
