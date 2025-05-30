import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/shop_service.dart'; // Import corrigé
import '../models/shop_item.dart';
import '../widgets/coin_display.dart';
import '../widgets/shop_item_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _categories = ['Personnages', 'Fonds', 'Power-ups'];
  bool _isInitialLoad = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Provider.of<ShopService>(context, listen: false).loadShopItems();
    } finally {
      if (mounted) setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<ShopService>(context, listen: false).loadShopItems();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopService = Provider.of<ShopService>(context);
    final isLoading = _isInitialLoad || shopService.isLoading;

    return Scaffold(
      backgroundColor: Colors.red[400],
      appBar: AppBar(
        title: const Text('Boutique', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2,
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((cat) => Tab(text: cat)).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CoinDisplay(
                coins: shopService.currentCoins,
                color: Colors.amber[800],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red[300],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabContent(shopService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ShopService shopService) {
    final category = _categories[_tabController.index];
    final items = shopService.getItemsByCategory(category);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 50, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'Pas d\'articles disponibles',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
            Text(
              'Dans la catégorie "$category"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: Colors.red[400],
      color: Colors.white,
      onRefresh: _refreshData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ShopItemCard(
            item: item,
            isOwned: shopService.isItemOwned(item.id),
            onPurchase: () => _handlePurchase(item),
            onSelect: () => _handleSelect(item),
            backgroundColor: Colors.red[200],
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(ShopItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final shopService = Provider.of<ShopService>(context, listen: false);

    try {
      final success = await shopService.purchaseItem(item.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ ${item.name} acheté!' : '❌ Pas assez de pièces',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Erreur lors de l\'achat'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleSelect(ShopItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final shopService = Provider.of<ShopService>(context, listen: false);

    try {
      final success = await shopService.selectItem(item.id);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('🎮 ${item.name} équipé'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue[700],
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Erreur de sélection'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}