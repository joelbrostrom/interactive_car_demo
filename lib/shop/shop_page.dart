import 'package:flutter/material.dart';

import '../supabase_config.dart';
import 'cart_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Map<String, dynamic>> _items = [];
  int _cartCount = 0;
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'wheels',
    'tires',
    'wipers',
    'lights',
    'brakes',
    'maintenance',
    'accessories',
    'electronics',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCartCount();
  }

  Future<void> _loadItems() async {
    try {
      final data = await supabase.from('shop_items').select();
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId);

      if (mounted) {
        int total = 0;
        for (var item in data) {
          total += (item['quantity'] as int?) ?? 0;
        }
        setState(() => _cartCount = total);
      }
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existing =
          await supabase
              .from('cart_items')
              .select()
              .eq('user_id', userId)
              .eq('item_id', item['id'])
              .maybeSingle();

      if (existing != null) {
        await supabase
            .from('cart_items')
            .update({'quantity': (existing['quantity'] as int) + 1})
            .eq('id', existing['id']);
      } else {
        await supabase.from('cart_items').insert({
          'user_id': userId,
          'item_id': item['id'],
          'quantity': 1,
        });
      }

      _loadCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name']} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => _openCart(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
      }
    }
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartPage(onCartUpdated: _loadCartCount),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _items;
    }
    return _items
        .where((item) => item['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 20,
                color: Color(0xFFFF4081),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Parts Shop'),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, size: 22),
                    color: const Color(0xFFF0F6FC),
                    onPressed: _openCart,
                  ),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4081), Color(0xFFFF1744)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF4081,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _cartCount > 99 ? '99+' : _cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              )
              : Column(
                children: [
                  _buildCategoryFilter(),
                  Expanded(
                    child:
                        _filteredItems.isEmpty
                            ? _buildEmptyState()
                            : _buildItemsList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = (_selectedCategory ?? 'All') == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                          )
                          : null,
                  color: isSelected ? null : const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.transparent
                            : const Color(0xFF30363D),
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFF00E5FF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  category == 'All' ? 'All' : _capitalizeFirst(category),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? const Color(0xFF003544)
                            : const Color(0xFF8B949E),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.inventory_2_outlined,
                size: 48,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No items found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF0F6FC),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try selecting a different category',
              style: TextStyle(fontSize: 14, color: Color(0xFF8B949E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Unknown';
    final description = item['description'] ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final category = item['category'] ?? '';
    final imageUrl = item['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 140,
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, _, _) => _buildPlaceholderImage(category),
                      )
                      : _buildPlaceholderImage(category),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _capitalizeFirst(category),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF0F6FC),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8B949E),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                              ).createShader(bounds),
                          child: Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00E5FF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _addToCart(item),
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 18,
                                      color: Color(0xFF003544),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF003544),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A365D), const Color(0xFF0D1117)],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 40,
          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wheels':
        return Icons.circle_outlined;
      case 'tires':
        return Icons.trip_origin;
      case 'wipers':
        return Icons.water_drop;
      case 'lights':
        return Icons.lightbulb;
      case 'brakes':
        return Icons.pause_circle;
      case 'maintenance':
        return Icons.build;
      case 'accessories':
        return Icons.auto_awesome;
      case 'electronics':
        return Icons.electrical_services;
      default:
        return Icons.inventory_2;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
