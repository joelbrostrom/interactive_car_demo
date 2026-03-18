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
        title: const Text('Parts Shop'),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _openCart,
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
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
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = (_selectedCategory ?? 'All') == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category == 'All' ? 'All' : _capitalizeFirst(category),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _capitalizeFirst(category),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _addToCart(item),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add'),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 48,
          color: Colors.grey.shade400,
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
