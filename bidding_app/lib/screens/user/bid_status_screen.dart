// screens/user/bid_status_screen.dart
// Fixed — no AppColors, no AppTextStyles, no AuctionItem, no shared_widgets

import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'auctions_screen.dart';

enum BidState { success, outbid, error }

class BidStatusScreen extends StatefulWidget {
  final Product product;
  final double  bidAmount;
  final BidState initialState;

  const BidStatusScreen({
    super.key,
    required this.product,
    required this.bidAmount,
    this.initialState = BidState.success,
  });

  @override
  State<BidStatusScreen> createState() => _BidStatusScreenState();
}

class _BidStatusScreenState extends State<BidStatusScreen>
    with SingleTickerProviderStateMixin {
  late BidState          _state;
  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _state    = widget.initialState;
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _switchState(BidState s) {
    setState(() => _state = s);
    _animCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Bid Status',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // State toggle tabs (for demo purposes)
              Container(
                decoration: BoxDecoration(
                  color:        const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _StateTab(
                        label:    'SUCCESS',
                        isActive: _state == BidState.success,
                        color:    const Color(0xFF22C55E),
                        onTap: () => _switchState(BidState.success)),
                    _StateTab(
                        label:    'OUTBID',
                        isActive: _state == BidState.outbid,
                        color:    const Color(0xFFF59E0B),
                        onTap: () => _switchState(BidState.outbid)),
                    _StateTab(
                        label:    'ERROR',
                        isActive: _state == BidState.error,
                        color:    const Color(0xFFEF4444),
                        onTap: () => _switchState(BidState.error)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ScaleTransition(
                scale: _scaleAnim,
                child: _buildCard(context),
              ),

              const SizedBox(height: 16),

              // Active bids notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      width:  40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:        const Color(0xFF3B82F6)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: Color(0xFF3B82F6), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Live bidding is active',
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize:   14,
                          )),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(
                              builder: (_) => const AuctionsScreen())),
                      child: const Text('View All',
                          style: TextStyle(
                            color:      Color(0xFF3B82F6),
                            fontWeight: FontWeight.w700,
                            fontSize:   13,
                          )),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    switch (_state) {
      case BidState.success:
        return _SuccessCard(
            product:   widget.product,
            bidAmount: widget.bidAmount);
      case BidState.outbid:
        return _OutbidCard(
            product:   widget.product,
            bidAmount: widget.bidAmount);
      case BidState.error:
        return const _ErrorCard();
    }
  }
}

// ── Success card ──────────────────────────────────────────────────────────────
class _SuccessCard extends StatelessWidget {
  final Product product;
  final double  bidAmount;
  const _SuccessCard(
      {required this.product, required this.bidAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFF22C55E).withOpacity(0.1),
            blurRadius: 20,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:  const Color(0xFF22C55E).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 36),
          ),
          const SizedBox(height: 12),
          const Text('Bid Placed!',
              style: TextStyle(
                color:      Colors.white,
                fontSize:   22,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          const Text('Your bid is currently the highest',
              style: TextStyle(
                color:    Color(0xFF64748B),
                fontSize: 14,
              )),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 16),

          _Row(label: 'Your Bid',
              value: '\$${bidAmount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF22C55E)),
          const SizedBox(height: 10),
          _Row(label: 'Item', value: product.title),
          const SizedBox(height: 10),
          _Row(
            label:      'Time Remaining',
            value:      _fmt(product.remaining),
            valueColor: const Color(0xFFEF4444),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width:  double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon:  const Icon(Icons.arrow_back_rounded),
              label: const Text('Continue Bidding',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Outbid card ───────────────────────────────────────────────────────────────
class _OutbidCard extends StatelessWidget {
  final Product product;
  final double  bidAmount;
  const _OutbidCard(
      {required this.product, required this.bidAmount});

  @override
  Widget build(BuildContext context) {
    final increment  = product.minIncrement ?? 50;
    final currentBid = product.currentHighestBid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 20,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  color:  const Color(0xFFF59E0B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Someone just outbid you!",
                        style: TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                        )),
                    SizedBox(height: 3),
                    Text(
                      "Another bidder placed a higher bid.",
                      style: TextStyle(
                        color:    Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 14),

          // Bid comparison
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFEF4444)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFEF4444)
                            .withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      const Text('Your Bid',
                          style: TextStyle(
                            color:    Color(0xFF94A3B8),
                            fontSize: 11,
                          )),
                      const SizedBox(height: 4),
                      Text('\$${bidAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color:      Color(0xFFEF4444),
                            fontWeight: FontWeight.w800,
                            fontSize:   20,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF59E0B)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Current Leader',
                          style: TextStyle(
                            color:    Color(0xFF94A3B8),
                            fontSize: 11,
                          )),
                      const SizedBox(height: 4),
                      Text('\$${currentBid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color:      Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize:   20,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text('Quick Counter-Bid',
              style: TextStyle(
                color:       Color(0xFF94A3B8),
                fontSize:    11,
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 10),

          Row(
            children: [1, 2, 5].map((m) {
              final amt = currentBid + (increment * m);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                    ),
                    child: Text('\$${amt.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color:      Color(0xFF3B82F6),
                          fontWeight: FontWeight.w700,
                          fontSize:   12,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 13, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(
                  'Suggested: \$${(currentBid + increment * 1.5).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color:    Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width:  double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:  const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: Color(0xFFEF4444), size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Network Error',
              style: TextStyle(
                color:      Colors.white,
                fontSize:   22,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 6),
          const Text(
            'Your connection seems unstable. Please check your internet and try again.',
            style: TextStyle(
              color:    Color(0xFF64748B),
              fontSize: 14,
              height:   1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width:  double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Go Back',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared row widget ─────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Row(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              color:    Color(0xFF64748B),
              fontSize: 13,
            )),
        Text(value,
            style: TextStyle(
              color:      valueColor ?? Colors.white,
              fontWeight: FontWeight.w700,
              fontSize:   13,
            )),
      ],
    );
  }
}

// ── State tab ─────────────────────────────────────────────────────────────────
class _StateTab extends StatelessWidget {
  final String       label;
  final bool         isActive;
  final Color        color;
  final VoidCallback onTap;

  const _StateTab({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:        isActive
                ? color.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: isActive
                ? Border.all(color: color.withOpacity(0.4))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   11,
              fontWeight: isActive
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isActive ? color : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}