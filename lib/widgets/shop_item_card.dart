import 'package:flutter/material.dart';
import '../models/shop_item.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isOwned;
  final VoidCallback onPurchase;
  final VoidCallback onSelect;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.onPurchase,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Partie image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[200],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  item.iconAsset,  // Changé de imagePath à iconAsset
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 50),
                ),
              ),
            ),
          ),
          // Partie informations
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16),
                    const SizedBox(width: 4),
                    Text('${item.price}'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isOwned) {
      return ElevatedButton(
        onPressed: onSelect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 40),
        ),
        child: const Text('SÉLECTIONNER'),
      );
    } else {
      return ElevatedButton(
        onPressed: onPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black87,
          minimumSize: const Size(double.infinity, 40),
        ),
        child: const Text('ACHETER'),
      );
    }
  }
}