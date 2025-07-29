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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🏪 Boutique',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade300, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${shopService.currentCoins}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          shopService.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCategorySection(
                    context,
                    shopService,
                    ShopItemType.characterSkin,
                    '🦖 Skins de Dinosaure',
                  ),
                  _buildCategorySection(
                    context,
                    shopService,
                    ShopItemType.powerUp,
                    '⚡ Power-ups',
                  ),
                  _buildCategorySection(
                    context,
                    shopService,
                    ShopItemType.decoration,
                    '🎨 Fonds Décoratifs',
                  ),
                  _buildCategorySection(
                    context,
                    shopService,
                    ShopItemType.currencyPack,
                    '💰 Packs de Pièces',
                  ),
                ],
              ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ShopService shopService,
    ShopItemType type,
    String categoryName,
  ) {
    final items = shopService.getItemsByType(type);

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent, width: 2),
          ),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
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
    final isSelected = shopService.selectedSkin == item.id;

    return GestureDetector(
      onTap: () async {
        if (isOwned) {
          await shopService.selectItem(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} sélectionné !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final result = await shopService.attemptPurchase(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_purchaseMessage(result)),
                backgroundColor:
                    result == PurchaseStatus.success
                        ? Colors.green
                        : Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? Colors.greenAccent
                    : isOwned
                    ? Colors.green
                    : Colors.grey.shade600,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image de l'item
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade700,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.iconAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Nom de l'item
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8),

                // Prix ou statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOwned ? Colors.green.shade700 : Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOwned
                        ? (isSelected ? 'ÉQUIPÉ' : 'POSSÉDÉ')
                        : '${item.price} 💰',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            // Badge "Nouveau" en haut à droite
            if (item.isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
        return 'Achat réussi ! ${item.name} ajouté à votre collection.';
      case PurchaseStatus.alreadyOwned:
        return 'Vous possédez déjà ${item.name}.';
      case PurchaseStatus.notEnoughCoins:
        return 'Pièces insuffisantes. Il vous faut ${item.price} pièces.';
      case PurchaseStatus.failed:
      default:
        return 'Erreur lors de l\'achat. Veuillez réessayer.';
    }
  }
}
