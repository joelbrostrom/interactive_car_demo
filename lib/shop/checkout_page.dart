import 'package:flutter/material.dart';

import '../supabase_config.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;
  final VoidCallback? onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
    this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  bool _orderPlaced = false;
  String? _orderId;

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final itemsSnapshot =
          widget.cartItems.map((item) {
            final shopItem = item['shop_items'] as Map<String, dynamic>?;
            return {
              'name': shopItem?['name'],
              'price': shopItem?['price'],
              'quantity': item['quantity'],
            };
          }).toList();

      final orderResponse =
          await supabase
              .from('orders')
              .insert({
                'user_id': userId,
                'items': itemsSnapshot,
                'total': widget.total,
              })
              .select()
              .single();

      _orderId = orderResponse['id'];

      await supabase.from('cart_items').delete().eq('user_id', userId);

      widget.onOrderPlaced?.call();

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _orderPlaced = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderPlaced) {
      return _buildOrderConfirmation();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment_rounded,
                size: 20,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Checkout'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 16),
            _buildShippingInfo(),
            const SizedBox(height: 16),
            _buildPaymentInfo(),
            const SizedBox(height: 20),
            _buildTotalSection(),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessing ? null : _placeOrder,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child:
                        _isProcessing
                            ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF003544),
                              ),
                            )
                            : const Text(
                                'Place Order',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF003544),
                                ),
                              ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is a demo app. No real payment will be processed.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8B949E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF30363D)),
          const SizedBox(height: 12),
          ...widget.cartItems.map((item) {
            final shopItem = item['shop_items'] as Map<String, dynamic>?;
            final name = shopItem?['name'] ?? 'Unknown';
            final price = (shopItem?['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as int?) ?? 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name x$quantity',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B949E),
                      ),
                    ),
                  ),
                  Text(
                    '\$${(price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF0F6FC),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF00E5FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Shipping Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF30363D)),
          const SizedBox(height: 12),
          _buildInfoRow('Name', 'John Doe'),
          _buildInfoRow('Address', '123 Toyota Lane'),
          _buildInfoRow('City', 'Tokyo, Japan 100-0001'),
          _buildInfoRow('Phone', '+81 3-1234-5678'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: Color(0xFF00E5FF)),
                      SizedBox(width: 6),
                      Text(
                        'Edit Address',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFFFF4081),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF30363D)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                      const Color(0xFFFF4081).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Credit Card',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF0F6FC),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '**** **** **** 4242',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF238636).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Unlimited',
                  style: TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFF0F6FC),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.1),
            const Color(0xFF7C4DFF).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: Color(0xFF8B949E)),
              ),
              Text(
                '\$${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFFF0F6FC)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping',
                style: TextStyle(color: Color(0xFF8B949E)),
              ),
              const Text(
                'FREE',
                style: TextStyle(
                  color: Color(0xFF3FB950),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax', style: TextStyle(color: Color(0xFF8B949E))),
              Text('\$0.00', style: TextStyle(color: Color(0xFFF0F6FC))),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF30363D)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F6FC),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                ).createShader(bounds),
                child: Text(
                  '\$${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderConfirmation() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF3FB950).withValues(alpha: 0.1),
              const Color(0xFF0D1117),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3FB950).withValues(alpha: 0.2),
                          const Color(0xFF3FB950).withValues(alpha: 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3FB950).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3FB950).withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: Color(0xFF3FB950),
                    ),
                  ),
                  const SizedBox(height: 36),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF3FB950), Color(0xFF00E5FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'Order Placed!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thank you for your purchase',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Column(
                      children: [
                        _buildConfirmationRow(
                          'Order ID',
                          _orderId?.substring(0, 8).toUpperCase() ?? 'N/A',
                        ),
                        _buildConfirmationRow(
                          'Items',
                          '${widget.cartItems.length}',
                        ),
                        _buildConfirmationRow(
                          'Total',
                          '\$${widget.total.toStringAsFixed(2)}',
                        ),
                        _buildConfirmationRow('Status', 'Processing'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This is a demo order. No actual order has been placed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B949E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: Text(
                            'Continue Shopping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF003544),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFF0F6FC),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
