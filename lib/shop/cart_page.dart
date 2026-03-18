import 'package:flutter/material.dart';

import '../supabase_config.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  final VoidCallback? onCartUpdated;

  const CartPage({super.key, this.onCartUpdated});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('cart_items')
          .select('*, shop_items(*)')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await supabase.from('cart_items').delete().eq('id', cartItemId);
      } else {
        await supabase
            .from('cart_items')
            .update({'quantity': newQuantity})
            .eq('id', cartItemId);
      }
      _loadCart();
      widget.onCartUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating cart: $e')));
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      await supabase.from('cart_items').delete().eq('id', cartItemId);
      _loadCart();
      widget.onCartUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing item: $e')));
      }
    }
  }

  double get _totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      final shopItem = item['shop_items'] as Map<String, dynamic>?;
      if (shopItem != null) {
        final price = (shopItem['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as int?) ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CheckoutPage(
              cartItems: _cartItems,
              total: _totalPrice,
              onOrderPlaced: () {
                _loadCart();
                widget.onCartUpdated?.call();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Icons.shopping_cart_rounded,
                size: 20,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Shopping Cart'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              )
              : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildCheckoutBar() : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B949E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF0F6FC),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items from the shop to get started',
              style: TextStyle(fontSize: 14, color: Color(0xFF8B949E)),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem) {
    final shopItem = cartItem['shop_items'] as Map<String, dynamic>?;
    if (shopItem == null) return const SizedBox.shrink();

    final cartItemId = cartItem['id'] as String;
    final name = shopItem['name'] ?? 'Unknown';
    final price = (shopItem['price'] as num?)?.toDouble() ?? 0.0;
    final category = shopItem['category'] ?? '';
    final imageUrl = shopItem['image_url'] as String?;
    final quantity = (cartItem['quantity'] as int?) ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(category),
                      )
                      : _buildPlaceholder(category),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF0F6FC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed:
                          () => _updateQuantity(cartItemId, quantity - 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF0F6FC),
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed:
                          () => _updateQuantity(cartItemId, quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _removeItem(cartItemId),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                    ).createShader(bounds),
                child: Text(
                  '\$${(price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF30363D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: const Color(0xFFF0F6FC)),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String category) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A365D), Color(0xFF0D1117)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_rounded,
          color: Color(0xFF8B949E),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: const Border(top: BorderSide(color: Color(0xFF30363D))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8B949E)),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                      ).createShader(bounds),
                  child: Text(
                    '\$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _proceedToCheckout,
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Text(
                        'Proceed to Checkout',
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
            ),
          ],
        ),
      ),
    );
  }
}
