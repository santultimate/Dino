import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop_item.dart';
import '../models/purchase_status.dart';
import '../services/shop_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopService = Provider.of<ShopService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '💰 ${shopService.currentCoins}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: shopService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildCategorySection(context, shopService, ShopItemType.characterSkin, 'Personnages'),
                _buildCategorySection(context, shopService, ShopItemType.decoration, 'Fonds'),
                _buildCategorySection(context, shopService, ShopItemType.powerUp, 'Power-ups'),
              ],
            ),
    );
  }

  Widget _buildCategorySection(BuildContext context, ShopService shopService, ShopItemType type, String categoryName) {
    final items = shopService.getItemsByType(type);

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            categoryName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return _ShopItemCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;

  const _ShopItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final shopService = Provider.of<ShopService>(context);
    final isOwned = shopService.isItemOwned(item.id);

    return GestureDetector(
      onTap: () async {
        if (isOwned) {
          await shopService.selectItem(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item sélectionné !')),
          );
        } else {
          final result = await shopService.attemptPurchase(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_purchaseMessage(result))),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOwned ? Colors.green : Colors.white,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(item.iconAsset, height: 60),
            const SizedBox(height: 8),
            Text(item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                item.description,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOwned ? 'Déjà acheté' : '${item.price} 💰',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOwned ? Colors.green : Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _purchaseMessage(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.success:
        return 'Achat réussi !';
      case PurchaseStatus.alreadyOwned:
        return 'Déjà possédé.';
      case PurchaseStatus.notEnoughCoins:
        return 'Pas assez de coins.';
      case PurchaseStatus.failed:
      default:
        return 'Erreur lors de l\'achat.';
    }
  }
}
