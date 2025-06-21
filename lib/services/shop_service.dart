import 'package:flutter/material.dart';
import '../models/shop_item.dart';
import '../models/purchase_status.dart';

class ShopService extends ChangeNotifier {
  int currentCoins = 500;
  bool isLoading = false;
  final List<ShopItem> _items = []; // Remplis avec tes objets

  List<ShopItem> getItemsByType(ShopItemType type) {
    return _items.where((item) => item.type == type).toList();
  }

  bool isItemOwned(String id) {
    // Ta logique ici
    return false;
  }

  Future<void> selectItem(String id) async {
    // Logique de sélection
  }

  Future<PurchaseStatus> attemptPurchase(String id) async {
    // Logique d'achat
    return PurchaseStatus.success;
  }
}
