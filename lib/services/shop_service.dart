// lib/services/shop_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_item.dart';
import 'coin_service.dart';

class ShopService extends CoinService with ChangeNotifier {
  List<ShopItem> _availableItems = [];
  List<String> _ownedItems = [];
  bool _isLoading = false;
  bool _isProcessing = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  List<ShopItem> get availableItems => List.unmodifiable(_availableItems);

  Future<void> loadShopItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      
      _availableItems = [
        ShopItem(
          id: 'skin1',
          name: 'Dragon Skin',
          price: 500,
          type: ShopItemType.characterSkin,
          imagePath: 'assets/images/skins/dragon.png',
        ),
        ShopItem(
          id: 'bg1', 
          name: 'Mountain BG',
          price: 300,
          type: ShopItemType.background,
          imagePath: 'assets/images/backgrounds/mountain.png',
        ),
      ];

      await _loadPersistentData();
    } catch (e) {
      debugPrint('Error loading shop: $e');
      coins = 1000; // Using inherited coins property
      _ownedItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPersistentData() async {
    final prefs = await SharedPreferences.getInstance();
    _ownedItems = prefs.getStringList('owned_items') ?? [];
    coins = prefs.getInt('user_coins') ?? 1000; // Using inherited coins property
  }

  Future<bool> _savePersistentData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', coins); // Using inherited coins property
    await prefs.setStringList('owned_items', _ownedItems);
    return true;
  }

  // ... [rest of your existing methods]
}

  List<ShopItem> getItemsByCategory(String category) {
    return _availableItems.where((item) {
      switch(item.type) {
        case ShopItemType.characterSkin: return category == 'Personnages';
        case ShopItemType.background: return category == 'Fonds';
        case ShopItemType.powerUp: return category == 'Power-ups';
        default: return false;
      }
    }).toList();
  }

  bool isItemOwned(String id) => _ownedItems.contains(id);

  Future<bool> purchaseItem(String id) async {
    if (_isProcessing) return false;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      final item = _availableItems.firstWhere((item) => item.id == id);
      
      if (_coins >= item.price && !_ownedItems.contains(id)) {
        _coins -= item.price;
        _ownedItems.add(id);
        
        final success = await _savePersistentData();
        if (!success) {
          // Rollback if save fails
          _coins += item.price;
          _ownedItems.remove(id);
          return false;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error purchasing item: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> selectItem(String id) async {
    if (!_ownedItems.contains(id)) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.selectedItem, id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error selecting item: $e');
      return false;
    }
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    notifyListeners();
    await _savePersistentData();
  }
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de chargement des données')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<ShopService>(context, listen: false).loadShopItems();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopService = Provider.of<ShopService>(context);
    final isLoading = _isInitialLoad || shopService.isLoading;

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('Boutique'),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((cat) => Tab(text: cat)).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: CoinDisplay(coins: shopService.currentCoins),
            ),
            if (shopService.isProcessing)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabContent(shopService),
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
      return const Center(
        child: Text('Aucun objet disponible',
            style: TextStyle(color: Colors.black)),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
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
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Achat réussi: ${item.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Fonds insuffisants ou déjà acheté'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'achat'),
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
            content: Text('${item.name} sélectionné'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erreur de sélection'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}