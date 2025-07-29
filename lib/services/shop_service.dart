import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_item.dart';
import '../models/purchase_status.dart';

class ShopService extends ChangeNotifier {
  List<ShopItem> _items = [];
  List<String> _ownedItems = [];
  String? _selectedSkin;
  bool _isLoading = false;
  int _currentCoins = 0;

  // Getters
  List<ShopItem> get items => _items;
  List<String> get ownedItems => _ownedItems;
  String? get selectedSkin => _selectedSkin;
  bool get isLoading => _isLoading;
  int get currentCoins => _currentCoins;

  ShopService() {
    _initializeShop();
    _loadUserData();
  }

  void _initializeShop() {
    _items = [
      // SKINS DE DINOSAURE
      const ShopItem(
        id: 'dino_classic',
        name: 'Dino Classique',
        description: 'Le dinosaure original',
        iconAsset: 'assets/images/dino.png',
        price: 0,
        type: ShopItemType.characterSkin,
        status: ShopItemStatus.equipped,
        isNew: false,
      ),
      const ShopItem(
        id: 'dino_golden',
        name: 'Dino Doré',
        description: 'Un dinosaure brillant et précieux',
        iconAsset: 'assets/images/dino.png',
        price: 500,
        type: ShopItemType.characterSkin,
        status: ShopItemStatus.locked,
        isNew: true,
      ),
      const ShopItem(
        id: 'dino_neon',
        name: 'Dino Néon',
        description: 'Un dinosaure aux couleurs vives',
        iconAsset: 'assets/images/dino.png',
        price: 300,
        type: ShopItemType.characterSkin,
        status: ShopItemStatus.locked,
        isNew: false,
      ),
      const ShopItem(
        id: 'dino_robot',
        name: 'Dino Robot',
        description: 'Un dinosaure mécanique futuriste',
        iconAsset: 'assets/images/dino.png',
        price: 800,
        type: ShopItemType.characterSkin,
        status: ShopItemStatus.locked,
        isNew: true,
      ),
      const ShopItem(
        id: 'dino_ghost',
        name: 'Dino Fantôme',
        description: 'Un dinosaure spectral mystérieux',
        iconAsset: 'assets/images/dino.png',
        price: 1200,
        type: ShopItemType.characterSkin,
        status: ShopItemStatus.locked,
        isNew: false,
      ),

      // POWER-UPS
      const ShopItem(
        id: 'double_jump',
        name: 'Double Saut',
        description: 'Permet de sauter deux fois de suite',
        iconAsset: 'assets/images/power_up.png',
        price: 200,
        type: ShopItemType.powerUp,
        status: ShopItemStatus.locked,
        isNew: false,
        effectParameters: {'type': 'double_jump', 'duration': 10},
      ),
      const ShopItem(
        id: 'shield',
        name: 'Bouclier',
        description: 'Protection contre une collision',
        iconAsset: 'assets/images/power_up.png',
        price: 150,
        type: ShopItemType.powerUp,
        status: ShopItemStatus.locked,
        isNew: false,
        effectParameters: {'type': 'shield', 'duration': 8},
      ),
      const ShopItem(
        id: 'slow_motion',
        name: 'Ralenti',
        description: 'Ralentit le temps pendant 5 secondes',
        iconAsset: 'assets/images/power_up.png',
        price: 250,
        type: ShopItemType.powerUp,
        status: ShopItemStatus.locked,
        isNew: true,
        effectParameters: {'type': 'slow_motion', 'duration': 5},
      ),
      const ShopItem(
        id: 'magnet',
        name: 'Aimant',
        description: 'Attire les pièces automatiquement',
        iconAsset: 'assets/images/power_up.png',
        price: 180,
        type: ShopItemType.powerUp,
        status: ShopItemStatus.locked,
        isNew: false,
        effectParameters: {'type': 'magnet', 'duration': 12},
      ),
      const ShopItem(
        id: 'invincibility',
        name: 'Invincibilité',
        description: 'Immunité totale pendant 3 secondes',
        iconAsset: 'assets/images/power_up.png',
        price: 400,
        type: ShopItemType.powerUp,
        status: ShopItemStatus.locked,
        isNew: true,
        effectParameters: {'type': 'invincibility', 'duration': 3},
      ),

      // FONDS DÉCORATIFS
      const ShopItem(
        id: 'bg_classic',
        name: 'Fond Classique',
        description: 'Le fond original du jeu',
        iconAsset: 'assets/images/background.png',
        price: 0,
        type: ShopItemType.decoration,
        status: ShopItemStatus.equipped,
        isNew: false,
      ),
      const ShopItem(
        id: 'bg_night',
        name: 'Fond Nocturne',
        description: 'Un fond sombre et mystérieux',
        iconAsset: 'assets/images/background.png',
        price: 100,
        type: ShopItemType.decoration,
        status: ShopItemStatus.locked,
        isNew: false,
      ),
      const ShopItem(
        id: 'bg_sunset',
        name: 'Fond Coucher de Soleil',
        description: 'Un fond aux couleurs chaudes',
        iconAsset: 'assets/images/background.png',
        price: 150,
        type: ShopItemType.decoration,
        status: ShopItemStatus.locked,
        isNew: true,
      ),
      const ShopItem(
        id: 'bg_cyber',
        name: 'Fond Cyberpunk',
        description: 'Un fond futuriste et coloré',
        iconAsset: 'assets/images/background.png',
        price: 300,
        type: ShopItemType.decoration,
        status: ShopItemStatus.locked,
        isNew: true,
      ),

      // PACKS DE PIÈCES
      const ShopItem(
        id: 'coin_pack_small',
        name: 'Pack 100 Pièces',
        description: '100 pièces pour vos achats',
        iconAsset: 'assets/images/power_up.png',
        price: 0,
        currencyValue: 100,
        type: ShopItemType.currencyPack,
        status: ShopItemStatus.locked,
        isNew: false,
      ),
      const ShopItem(
        id: 'coin_pack_medium',
        name: 'Pack 500 Pièces',
        description: '500 pièces pour vos achats',
        iconAsset: 'assets/images/power_up.png',
        price: 0,
        currencyValue: 500,
        type: ShopItemType.currencyPack,
        status: ShopItemStatus.locked,
        isNew: false,
      ),
      const ShopItem(
        id: 'coin_pack_large',
        name: 'Pack 1000 Pièces',
        description: '1000 pièces pour vos achats',
        iconAsset: 'assets/images/power_up.png',
        price: 0,
        currencyValue: 1000,
        type: ShopItemType.currencyPack,
        status: ShopItemStatus.locked,
        isNew: true,
      ),
    ];

    // Ajouter le skin classique aux items possédés
    _ownedItems.add('dino_classic');
    _ownedItems.add('bg_classic');
    _selectedSkin = 'dino_classic';
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentCoins = prefs.getInt('coins') ?? 1000;
      _ownedItems =
          prefs.getStringList('ownedItems') ?? ['dino_classic', 'bg_classic'];
      _selectedSkin = prefs.getString('selectedSkin') ?? 'dino_classic';
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des données: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', _currentCoins);
      await prefs.setStringList('ownedItems', _ownedItems);
      await prefs.setString('selectedSkin', _selectedSkin ?? 'dino_classic');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde: $e');
    }
  }

  List<ShopItem> getItemsByType(ShopItemType type) {
    return _items.where((item) => item.type == type).toList();
  }

  bool isItemOwned(String itemId) {
    return _ownedItems.contains(itemId);
  }

  Future<PurchaseStatus> attemptPurchase(String itemId) async {
    final item = _items.firstWhere((item) => item.id == itemId);

    if (_ownedItems.contains(itemId)) {
      return PurchaseStatus.alreadyOwned;
    }

    if (_currentCoins < item.price) {
      return PurchaseStatus.notEnoughCoins;
    }

    // Effectuer l'achat
    _currentCoins -= item.price;
    _ownedItems.add(itemId);

    await _saveUserData();
    notifyListeners();

    return PurchaseStatus.success;
  }

  Future<void> selectItem(String itemId) async {
    final item = _items.firstWhere((item) => item.id == itemId);

    if (item.type == ShopItemType.characterSkin) {
      _selectedSkin = itemId;
    }

    await _saveUserData();
    notifyListeners();
  }

  void addCoins(int amount) {
    _currentCoins += amount;
    _saveUserData();
    notifyListeners();
  }

  void spendCoins(int amount) {
    if (_currentCoins >= amount) {
      _currentCoins -= amount;
      _saveUserData();
      notifyListeners();
    }
  }

  ShopItem? getItemById(String itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  List<ShopItem> getOwnedItems() {
    return _items.where((item) => _ownedItems.contains(item.id)).toList();
  }

  List<ShopItem> getAvailableItems() {
    return _items
        .where(
          (item) =>
              _ownedItems.contains(item.id) || _currentCoins >= item.price,
        )
        .toList();
  }
}
