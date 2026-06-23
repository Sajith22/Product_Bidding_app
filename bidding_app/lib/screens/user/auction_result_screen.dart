// screens/user/auction_result_screen.dart
// Fixed — no AppColors, no AppTextStyles, no AuctionItem, no shared_widgets
// Uses new dark theme matching rest of app

import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'auctions_screen.dart';

class AuctionResultScreen extends StatefulWidget {
  final Product product;

  const AuctionResultScreen({super.key, required this.product});

  @override
  State<AuctionResultScreen> createState() => _AuctionResultScreenState();
}

class _AuctionResultScreenState extends State<AuctionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset>  _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Auction Result',
            style: TextStyle(
              color:      Colors.white,
              fontWeight: FontWeight.w700,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── YOU WON banner ───────────────────────────────────────
                  Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:      const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 24,
                          offset:     const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width:  80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(Icons.emoji_events_rounded,
                                color: Colors.white, size: 44),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('YOU WON!',
                              style: TextStyle(
                                color:       Colors.white,
                                fontWeight:  FontWeight.w900,
                                fontSize:    16,
                                letterSpacing: 2,
                              )),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '\$${product.winningBid?.toStringAsFixed(2) ?? product.currentHighestBid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color:       Colors.white,
                            fontSize:    40,
                            fontWeight:  FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text('Final Winning Bid',
                            style: TextStyle(
                              color:    Colors.white70,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Notification card ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width:  44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:        const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.gavel_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('BidForge',
                                      style: TextStyle(
                                        color:      Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize:   14,
                                      )),
                                  const Text('Just now',
                                      style: TextStyle(
                                        color:    Color(0xFF64748B),
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Hammer down! You won "${product.title}" with your bid.',
                                style: const TextStyle(
                                  color:    Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Item + price breakdown ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item row
                        Row(
                          children: [
                            Container(
                              width:  60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:        const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                          product.imageUrl!,
                                          fit: BoxFit.cover),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF475569),
                                      size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item #${product.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      color:    Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(product.title,
                                      style: const TextStyle(
                                        color:      Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize:   15,
                                      )),
                                  Text(
                                    'Auction ended · ${_formatDate(product.endTime)}',
                                    style: const TextStyle(
                                      color:    Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                              color: Color(0xFF334155), height: 1),
                        ),

                        // Price breakdown
                        final winBid = product.winningBid ??
                            product.currentHighestBid;
                        final premium  = winBid * 0.05;
                        final shipping = 15.0;
                        final total    = winBid + premium + shipping;

                        _PriceRow(
                            label: 'Hammer Price',
                            value: '\$${winBid.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _PriceRow(
                            label: "Buyer's Premium (5%)",
                            value: '\$${premium.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _PriceRow(
                            label: 'Shipping Estimate',
                            value: '\$${shipping.toStringAsFixed(2)}'),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                              color: Color(0xFF334155),
                              height:    1,
                              thickness: 1.5),
                        ),

                        _PriceRow(
                          label:       'Total Amount',
                          value:       '\$${total.toStringAsFixed(2)}',
                          isBold:      true,
                          valueColor:  const Color(0xFF3B82F6),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF22C55E)
                                    .withOpacity(0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E), size: 16),
                              SizedBox(width: 8),
                              Text('Ready for Checkout',
                                  style: TextStyle(
                                    color:      Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                    fontSize:   13,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Info notice ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF3B82F6)
                              .withOpacity(0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please complete your payment within 48 hours to ensure priority shipping.',
                            style: TextStyle(
                              color:    Color(0xFF94A3B8),
                              fontSize: 13,
                              height:   1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Checkout button ──────────────────────────────────────
                  SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon:  const Icon(
                          Icons.shopping_cart_checkout_rounded),
                      label: const Text('Proceed to Checkout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:   15,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Share + Seller row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon:  const Icon(Icons.share_outlined,
                              size: 18, color: Color(0xFF3B82F6)),
                          label: const Text('Share',
                              style: TextStyle(
                                color:      Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              )),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF3B82F6)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: Color(0xFF64748B)),
                          label: const Text('Seller',
                              style: TextStyle(
                                color:      Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              )),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const AuctionsScreen()),
                      (_) => false,
                    ),
                    icon:  const Icon(Icons.local_shipping_outlined,
                        size: 18),
                    label: const Text('Back to Auctions'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6)),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Price row widget ──────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool   isBold;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold     = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color:      isBold ? Colors.white : const Color(0xFF94A3B8),
              fontSize:   isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              color:      valueColor ??
                  (isBold ? Colors.white : const Color(0xFF94A3B8)),
              fontSize:   isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            )),
      ],
    );
  }
}