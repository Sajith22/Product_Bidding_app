// screens/user/auctions_screen.dart
// Full bottom nav — all 4 tabs implemented properly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/user_theme.dart';
import '../../models/app_models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'auction_detail_screen.dart';
import '../../../main.dart' show RoleGateway;

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen>
    with SingleTickerProviderStateMixin {
  final _productService = ProductService();
  final _authService    = AuthService();
  final _notifService   = NotificationService();

  int    _navIndex  = 0;
  String _search    = '';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _AuctionsTab(
            productService: _productService,
            notifService:   _notifService,
            uid:            _uid,
            search:         _search,
            onSearchChanged: (v) => setState(() => _search = v),
          ),
          _ExploreTab(productService: _productService),
          _MyBidsTab(uid: _uid, productService: _productService),
          _ProfileTab(uid: _uid, onSignOut: _signOut),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        uid:          _uid,
        notifService: _notifService,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Auctions (Live / Upcoming / Ended)
// ─────────────────────────────────────────────────────────────────────────────
class _AuctionsTab extends StatefulWidget {
  final ProductService     productService;
  final NotificationService notifService;
  final String             uid;
  final String             search;
  final Function(String)   onSearchChanged;

  const _AuctionsTab({
    required this.productService,
    required this.notifService,
    required this.uid,
    required this.search,
    required this.onSearchChanged,
  });

  @override
  State<_AuctionsTab> createState() => _AuctionsTabState();
}

class _AuctionsTabState extends State<_AuctionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final Set<String> _finalizing = <String>{};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  void _maybeFinalizeEnded(List<Product> products) {
    for (final p in products) {
      if (p.status != BidStatus.ended) continue;
      if (p.winnerId != null || p.endedAt != null) continue;
      if (p.highestBidderId == null) continue;
      if (_finalizing.contains(p.id)) continue;

      _finalizing.add(p.id);
      unawaited(() async {
        final res = await ProductService().closeProduct(p.id);
        if (res.isSuccess &&
            res.winnerId != null &&
            res.winningBid != null) {
          await widget.notifService.saveNotificationOnce(
            userId: res.winnerId!,
            key: 'winner_${p.id}',
            title: 'Auction won',
            body:
                'You won "${p.title}" with a bid of \$${res.winningBid!.toStringAsFixed(2)}.',
            productId: p.id,
          );
        }
        _finalizing.remove(p.id);
      }());
    }
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.45,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<AppNotification>>(
                      stream: widget.notifService
                          .watchNotifications(widget.uid),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF3B82F6)),
                          );
                        }
                        final notifs = snap.data!;
                        if (notifs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 52,
                                      color: Color(0xFF334155)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Winners and bid alerts will show up here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: notifs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = notifs[i];
                            return GestureDetector(
                              onTap: () async {
                                if (!n.isRead) {
                                  await widget.notifService.markRead(n.id);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: n.isRead
                                        ? const Color(0xFF334155)
                                        : const Color(0xFF3B82F6)
                                            .withOpacity(0.45),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: n.isRead
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF3B82F6)
                                                .withOpacity(0.18),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        n.isRead
                                            ? Icons.notifications_outlined
                                            : Icons.notifications_active_outlined,
                                        color: n.isRead
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF3B82F6),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: n.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            n.body,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Logo
                    Container(
                      width:  36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:        const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'BidForge',
                      style: TextStyle(
                        color:       Colors.white,
                        fontSize:    22,
                        fontWeight:  FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),

                    // Notification bell
                    StreamBuilder<int>(
                      stream: widget.notifService
                          .watchUnreadCount(widget.uid),
                      builder: (_, snap) {
                        final count = snap.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _openNotifications,
                              child: Container(
                                width:  40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:        const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF334155)),
                                ),
                                child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 20),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top:   -4,
                                right: -4,
                                child: Container(
                                  width:  18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('$count',
                                        style: const TextStyle(
                                          color:      Colors.white,
                                          fontSize:   10,
                                          fontWeight: FontWeight.w800,
                                        )),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color:        const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: TextField(
                    onChanged: widget.onSearchChanged,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search auctions...',
                      hintStyle: const TextStyle(
                          color: Color(0xFF475569), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF475569), size: 18),
                      suffixIcon: widget.search.isNotEmpty
                          ? GestureDetector(
                              onTap: () =>
                                  widget.onSearchChanged(''),
                              child: const Icon(Icons.close_rounded,
                                  color: Color(0xFF475569),
                                  size: 18),
                            )
                          : null,
                      border:         InputBorder.none,
                      enabledBorder:  InputBorder.none,
                      focusedBorder:  InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tab bar
                TabBar(
                  controller:            _tabCtrl,
                  indicatorColor:        const Color(0xFF3B82F6),
                  indicatorWeight:       2.5,
                  labelColor:            const Color(0xFF3B82F6),
                  unselectedLabelColor:  const Color(0xFF475569),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Live'),
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Ended'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: widget.productService.watchPublishedProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6)),
                  );
                }

                final all = snapshot.data!;
                _maybeFinalizeEnded(all);
                final filtered = widget.search.isEmpty
                    ? all
                    : all.where((p) => p.title
                        .toLowerCase()
                        .contains(widget.search.toLowerCase()))
                        .toList();

                final live     = filtered.where((p) => p.status == BidStatus.live).toList();
                final upcoming = filtered.where((p) => p.status == BidStatus.upcoming).toList();
                final ended    = filtered.where((p) => p.status == BidStatus.ended).toList();

                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ProductGrid(products: live,     emptyLabel: 'No live auctions right now'),
                    _ProductGrid(products: upcoming, emptyLabel: 'No upcoming auctions'),
                    _ProductGrid(products: ended,    emptyLabel: 'No ended auctions yet'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Explore (all products, no filter)
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreTab extends StatelessWidget {
  final ProductService productService;
  const _ExploreTab({required this.productService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Explore',
                    style: TextStyle(
                      color:       Colors.white,
                      fontSize:    28,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 4),
                const Text('Discover all auction items',
                    style: TextStyle(
                      color:    Color(0xFF64748B),
                      fontSize: 14,
                    )),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productService.watchPublishedProducts(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6)));
                }
                final products = snap.data!;
                if (products.isEmpty) {
                  return const _EmptyState(
                    icon:    Icons.explore_outlined,
                    title:   'Nothing to explore yet',
                    subtitle: 'Check back soon for new auctions',
                  );
                }
                return _ProductGrid(
                    products: products, emptyLabel: '');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — My Bids
// ─────────────────────────────────────────────────────────────────────────────
class _MyBidsTab extends StatelessWidget {
  final String         uid;
  final ProductService productService;
  const _MyBidsTab({required this.uid, required this.productService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bids',
                    style: TextStyle(
                      color:       Colors.white,
                      fontSize:    28,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: -0.5,
                    )),
                SizedBox(height: 4),
                Text('Track your bidding activity',
                    style: TextStyle(
                      color:    Color(0xFF64748B),
                      fontSize: 14,
                    )),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productService.watchPublishedProducts(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6)));
                }

                // We need to find products where user has bid
                // We check each product's bids subcollection
                return _MyBidsList(
                    uid: uid, products: snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MyBidsList extends StatelessWidget {
  final String         uid;
  final List<Product>  products;
  const _MyBidsList({required this.uid, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyState(
        icon:     Icons.gavel_rounded,
        title:    'No bids yet',
        subtitle: 'Start bidding on live auctions!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final product = products[i];
        return _MyBidProductCard(uid: uid, product: product);
      },
    );
  }
}

class _MyBidProductCard extends StatelessWidget {
  final String  uid;
  final Product product;
  const _MyBidProductCard(
      {required this.uid, required this.product});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bid>>(
      stream: ProductService().watchBids(product.id),
      builder: (context, snap) {
        final bids = snap.data ?? [];
        final myBids = bids.where((b) => b.userId == uid).toList();

        if (myBids.isEmpty) return const SizedBox.shrink();

        final myHighest   = myBids.map((b) => b.amount).reduce(
            (a, b) => a > b ? a : b);
        final isLeading   = product.highestBidderId == uid;
        final iWon        = product.status == BidStatus.ended &&
            product.winnerId == uid;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                AuctionDetailScreen(product: product),
          )),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iWon
                  ? const Color(0xFF22C55E).withOpacity(0.08)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iWon
                    ? const Color(0xFF22C55E).withOpacity(0.4)
                    : isLeading
                        ? const Color(0xFF3B82F6).withOpacity(0.4)
                        : const Color(0xFF334155),
              ),
            ),
            child: Row(
              children: [
                // Product image / icon
                Container(
                  width:  52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:        const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.imageUrl!,
                              fit: BoxFit.cover),
                        )
                      : const Icon(Icons.inventory_2_outlined,
                          color: Color(0xFF475569), size: 24),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize:   14,
                          ),
                          maxLines:  1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('My highest: \$${myHighest.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color:    Color(0xFF64748B),
                                fontSize: 12,
                              )),
                          const SizedBox(width: 6),
                          Text('· ${myBids.length} bid${myBids.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color:    Color(0xFF475569),
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      iWon:      iWon,
                      isLeading: isLeading,
                      status:    product.status,
                    ),
                    const SizedBox(height: 4),
                    Text('\$${product.currentHighestBid.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color:      Color(0xFF3B82F6),
                          fontWeight: FontWeight.w800,
                          fontSize:   14,
                        )),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool      iWon, isLeading;
  final BidStatus status;
  const _StatusBadge({
    required this.iWon,
    required this.isLeading,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (iWon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('WON',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   10,
              fontWeight: FontWeight.w800,
            )),
      );
    }
    if (isLeading && status == BidStatus.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('LEADING',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   10,
              fontWeight: FontWeight.w800,
            )),
      );
    }
    if (status == BidStatus.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        const Color(0xFFEF4444).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.4)),
        ),
        child: const Text('OUTBID',
            style: TextStyle(
              color:      Color(0xFFEF4444),
              fontSize:   10,
              fontWeight: FontWeight.w800,
            )),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        const Color(0xFF334155),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label.toUpperCase(),
          style: const TextStyle(
            color:      Color(0xFF64748B),
            fontSize:   10,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — Profile
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String       uid;
  final VoidCallback onSignOut;
  const _ProfileTab({required this.uid, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
          builder: (context, snap) {
            final name  = snap.data?.get('name')  ?? 'User';
            final email = snap.data?.get('email') ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile',
                    style: TextStyle(
                      color:       Colors.white,
                      fontSize:    28,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: -0.5,
                    )),

                const SizedBox(height: 24),

                // Avatar card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0F172A)
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width:  60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF2563EB)
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   18,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 3),
                            Text(email,
                                style: const TextStyle(
                                  color:    Color(0xFF64748B),
                                  fontSize: 13,
                                )),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:        const Color(0xFF22C55E)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF22C55E)
                                        .withOpacity(0.4)),
                              ),
                              child: const Text('Verified Bidder',
                                  style: TextStyle(
                                    color:      Color(0xFF22C55E),
                                    fontSize:   10,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats row
                StreamBuilder<List<Product>>(
                  stream: ProductService().watchPublishedProducts(),
                  builder: (context, snap) {
                    final products = snap.data ?? [];
                    int totalBids = 0;
                    int wins      = 0;
                    int active    = 0;

                    for (final p in products) {
                      if (p.winnerId == uid) wins++;
                      if (p.highestBidderId == uid &&
                          p.status == BidStatus.live) active++;
                    }

                    return Row(
                      children: [
                        _StatCard(
                            label: 'Active Bids',
                            value: '$active',
                            color: const Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        _StatCard(
                            label: 'Auctions Won',
                            value: '$wins',
                            color: const Color(0xFF22C55E)),
                        const SizedBox(width: 10),
                        _StatCard(
                            label: 'Total Items',
                            value: '${products.length}',
                            color: const Color(0xFFF59E0B)),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Menu items
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                        icon:  Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        onTap: () {}),
                    _MenuItem(
                        icon:  Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () {}),
                    _MenuItem(
                        icon:  Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: () {}),
                  ],
                ),

                const SizedBox(height: 16),

                _MenuSection(
                  title: 'Support',
                  items: [
                    _MenuItem(
                        icon:  Icons.help_outline_rounded,
                        label: 'Help Center',
                        onTap: () {}),
                    _MenuItem(
                        icon:  Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () {}),
                    _MenuItem(
                        icon:  Icons.info_outline_rounded,
                        label: 'About BidForge',
                        onTap: () {}),
                  ],
                ),

                const SizedBox(height: 16),

                // Sign out button
                GestureDetector(
                  onTap: onSignOut,
                  child: Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFEF4444)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 8),
                        Text('Sign Out',
                            style: TextStyle(
                              color:      Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize:   15,
                            )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  color:      color,
                  fontSize:   22,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                  color:    Color(0xFF64748B),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String        title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                color:       Color(0xFF475569),
                fontSize:    11,
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.5,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color:        const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i    = e.key;
              final item = e.value;
              return Column(
                children: [
                  item,
                  if (i < items.length - 1)
                    const Divider(
                        height: 1,
                        color: Color(0xFF334155),
                        indent: 48),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF334155), size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Grid
// ─────────────────────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final String        emptyLabel;
  const _ProductGrid(
      {required this.products, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _EmptyState(
        icon:     Icons.search_off_rounded,
        title:    emptyLabel,
        subtitle: 'Check back soon!',
      );
    }

    final isWide = MediaQuery.of(context).size.width > 600;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   isWide ? 2 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
        childAspectRatio: isWide ? 1.2 : 1.6,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(product: products[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AuctionDetailScreen(product: product),
      )),
      child: Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Background image or gradient
            Positioned.fill(
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!,
                      fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A)
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined,
                            size: 48, color: Color(0xFF334155)),
                      ),
                    ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left:   14,
              right:  14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badges row
                  Row(
                    children: [
                      _CardBadge(product: product),
                      if (product.status == BidStatus.live) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('HOT',
                              style: TextStyle(
                                color:      Colors.white,
                                fontSize:   9,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(product.title,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines:  2,
                      overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Current Bid',
                              style: TextStyle(
                                color:    Color(0xFF94A3B8),
                                fontSize: 10,
                              )),
                          Text(
                            '\$${product.currentHighestBid.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color:       Color(0xFF3B82F6),
                              fontSize:    20,
                              fontWeight:  FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      if (product.status == BidStatus.live)
                        _CountdownChip(product: product)
                      else if (product.status == BidStatus.ended &&
                          product.winnerName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E)
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF22C55E)
                                    .withOpacity(0.4)),
                          ),
                          child: Text(
                          product.winnerName!,
                            style: const TextStyle(
                              color:      Color(0xFF22C55E),
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final Product product;
  const _CardBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    Color  color;
    String label;

    switch (product.status) {
      case BidStatus.live:
        color = const Color(0xFF22C55E);
        label = '● LIVE';
        break;
      case BidStatus.upcoming:
        color = const Color(0xFFF59E0B);
        label = 'UPCOMING';
        break;
      case BidStatus.ended:
        color = const Color(0xFF64748B);
        label = 'ENDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
            color:       color,
            fontSize:    9,
            fontWeight:  FontWeight.w800,
            letterSpacing: 0.3,
          )),
    );
  }
}

class _CountdownChip extends StatefulWidget {
  final Product product;
  const _CountdownChip({required this.product});

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  late Timer    _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.product.remaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = widget.product.remaining);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
    }
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined,
              color: Color(0xFFEF4444), size: 12),
          const SizedBox(width: 4),
          Text(
            _fmt(_remaining),
            style: const TextStyle(
              color:       Color(0xFFEF4444),
              fontSize:    11,
              fontWeight:  FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int              currentIndex;
  final String           uid;
  final NotificationService notifService;
  final Function(int)    onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.uid,
    required this.notifService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon:     Icons.gavel_rounded,
                label:    'Auctions',
                index:    0,
                current:  currentIndex,
                onTap:    onTap,
              ),
              _NavItem(
                icon:     Icons.explore_rounded,
                label:    'Explore',
                index:    1,
                current:  currentIndex,
                onTap:    onTap,
              ),
              _NavItem(
                icon:     Icons.receipt_long_rounded,
                label:    'My Bids',
                index:    2,
                current:  currentIndex,
                onTap:    onTap,
              ),
              _NavItem(
                icon:     Icons.person_rounded,
                label:    'Profile',
                index:    3,
                current:  currentIndex,
                onTap:    onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData      icon;
  final String        label;
  final int           index, current;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF3B82F6).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size:  22,
                color: active
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize:   10,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: active
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared utility widgets
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF334155)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                  color:    Color(0xFF64748B),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                  color:    Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}