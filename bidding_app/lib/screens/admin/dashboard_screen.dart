// ─────────────────────────────────────────────────────────────────────────────
// screens/admin/dashboard_screen.dart
// Replaces your old dashboard_screen.dart — now wired to Firestore.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/admin_theme.dart';
import '../../models/app_models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'add_product_screen.dart';
import 'bid_history_screen.dart';
import '../../../main.dart' show RoleGateway;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _productService = ProductService();
  final _authService    = AuthService();
  String _filter = 'all';   // all | upcoming | live | ended
  final Set<String> _finalizing = <String>{};

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleGateway()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.watchAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          _maybeFinalizeEnded(all);
          final products = _filter == 'all'
              ? all
              : all.where((p) => p.status.label.toLowerCase() == _filter).toList();

          return Column(
            children: [
              // Stats bar
              _StatsBar(products: all, isWide: isWide),

              // Filter chips
              _FilterBar(
                selected: _filter,
                onSelect: (f) => setState(() => _filter = f),
              ),

              // Product list
              Expanded(
                child: products.isEmpty
                    ? const _EmptyState()
                    : isWide
                        ? _ProductGrid(
                            products: products,
                            service: _productService,
                          )
                        : _ProductList(
                            products: products,
                            service: _productService,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _maybeFinalizeEnded(List<Product> products) {
    for (final p in products) {
      if (p.status != BidStatus.ended) continue;
      if (p.winnerId != null || p.endedAt != null) continue;
      if (p.highestBidderId == null) continue;
      if (_finalizing.contains(p.id)) continue;

      _finalizing.add(p.id);
      () async {
        final res = await _productService.closeProduct(p.id);
        if (res.isSuccess && res.winnerId != null && res.winningBid != null) {
          await NotificationService().saveNotificationOnce(
            userId: res.winnerId!,
            key: 'winner_${p.id}',
            title: 'Auction won',
            body:
                'You won "${p.title}" with a bid of \$${res.winningBid!.toStringAsFixed(2)}.',
            productId: p.id,
          );
        }
        _finalizing.remove(p.id);
      }();
    }
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final List<Product> products;
  final bool isWide;

  const _StatsBar({required this.products, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final live     = products.where((p) => p.status == BidStatus.live).length;
    final upcoming = products.where((p) => p.status == BidStatus.upcoming).length;
    final ended    = products.where((p) => p.status == BidStatus.ended).length;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: '${products.length}',
              color: AppTheme.primary),
          const SizedBox(width: 10),
          _StatChip(label: 'Live', value: '$live',
              color: AppTheme.success),
          const SizedBox(width: 10),
          _StatChip(label: 'Upcoming', value: '$upcoming',
              color: AppTheme.warning),
          const SizedBox(width: 10),
          _StatChip(label: 'Ended', value: '$ended',
              color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['all', 'live', 'upcoming', 'ended'].map((f) {
            final isActive = selected == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    f[0].toUpperCase() + f.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Product list (mobile) ─────────────────────────────────────────────────────
class _ProductList extends StatelessWidget {
  final List<Product> products;
  final ProductService service;

  const _ProductList({required this.products, required this.service});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _ProductCard(product: products[i], service: service),
    );
  }
}

// ── Product grid (desktop/tablet) ─────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ProductService service;

  const _ProductGrid({required this.products, required this.service});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) =>
          _ProductCard(product: products[i], service: service),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final ProductService service;

  const _ProductCard({required this.product, required this.service});

  Color get _statusColor {
    switch (product.status) {
      case BidStatus.live:     return AppTheme.success;
      case BidStatus.upcoming: return AppTheme.warning;
      case BidStatus.ended:    return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.border,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: AppTheme.textSecondary),
                        ),
                      )
                    : Container(
                        color: AppTheme.border,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined,
                            color: AppTheme.textSecondary, size: 34),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    product.status.label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              product.description,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Bid',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                    Text(
                      '\$${product.currentHighestBid.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
                // Winner chip
                if (product.status == BidStatus.ended &&
                    product.winnerName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.success),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            size: 14, color: AppTheme.success),
                        const SizedBox(width: 6),
                        Text(
                          product.winnerName!,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions row
            Row(
              children: [
                // Publish toggle
                Expanded(
                  child: GestureDetector(
                    onTap: () => service.setPublished(
                        product.id, !product.isPublished),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: product.isPublished
                            ? AppTheme.success.withOpacity(0.08)
                            : AppTheme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isPublished ? 'Published' : 'Unpublished',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: product.isPublished
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bid history
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 20),
                  tooltip: 'Bid History',
                  color: AppTheme.primary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BidHistoryScreen(product: product),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 56, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          const Text('No products yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Tap + to add your first auction product.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
