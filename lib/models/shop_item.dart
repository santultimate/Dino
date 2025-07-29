// models/shop_item.dart

import 'package:flutter/foundation.dart';

/// Type d'items disponibles dans la boutique
enum ShopItemType {
  characterSkin,    // Skin de personnage
  powerUp,         // Amélioration de puissance
  consumable,      // Objet consommable (ex: vies supplémentaires)
  decoration,      // Décoration pour le jeu
  currencyPack,    // Pack de monnaie
  other,           // Autres types
}

/// Statut de disponibilité d'un item
enum ShopItemStatus {
  locked,          // Non acheté
  purchased,       // Acheté mais non équipé
  equipped,        // Actuellement équipé
}

/// Modèle complet pour un item de boutique
@immutable
class ShopItem {
  final String id;                // Identifiant unique
  final String name;              // Nom affiché
  final String description;       // Description
  final String iconAsset;         // Icône dans la boutique
  final String? previewAsset;     // Asset de prévisualisation
  final int price;                // Prix en devise du jeu
  final int? currencyValue;       // Valeur si c'est un pack de devise
  final ShopItemType type;        // Type d'item
  final ShopItemStatus status;    // Statut actuel
  final int unlockLevel;          // Niveau requis pour débloquer
  final bool isNew;               // Nouveauté dans la boutique
  final DateTime? expirationDate; // Pour items temporaires
  final Map<String, dynamic>? effectParameters; // Effets spéciaux

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.previewAsset,
    required this.price,
    this.currencyValue,
    required this.type,
    this.status = ShopItemStatus.locked,
    this.unlockLevel = 1,
    this.isNew = false,
    this.expirationDate,
    this.effectParameters,
  });

  /// Copie avec modification (pattern builder)
  ShopItem copyWith({
    String? id,
    String? name,
    String? description,
    String? iconAsset,
    String? previewAsset,
    int? price,
    int? currencyValue,
    ShopItemType? type,
    ShopItemStatus? status,
    int? unlockLevel,
    bool? isNew,
    DateTime? expirationDate,
    Map<String, dynamic>? effectParameters,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      previewAsset: previewAsset ?? this.previewAsset,
      price: price ?? this.price,
      currencyValue: currencyValue ?? this.currencyValue,
      type: type ?? this.type,
      status: status ?? this.status,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      isNew: isNew ?? this.isNew,
      expirationDate: expirationDate ?? this.expirationDate,
      effectParameters: effectParameters ?? this.effectParameters,
    );
  }

  /// Convertit l'item en Map pour la sérialisation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconAsset': iconAsset,
      'previewAsset': previewAsset,
      'price': price,
      'currencyValue': currencyValue,
      'type': type.index,
      'status': status.index,
      'unlockLevel': unlockLevel,
      'isNew': isNew,
      'expirationDate': expirationDate?.toIso8601String(),
      'effectParameters': effectParameters,
    };
  }

  /// Crée un ShopItem à partir d'une Map
  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      iconAsset: map['iconAsset'] as String,
      previewAsset: map['previewAsset'] as String?,
      price: map['price'] as int,
      currencyValue: map['currencyValue'] as int?,
      type: ShopItemType.values[map['type'] as int],
      status: ShopItemStatus.values[map['status'] as int],
      unlockLevel: map['unlockLevel'] as int,
      isNew: map['isNew'] as bool,
      expirationDate: map['expirationDate'] != null 
          ? DateTime.parse(map['expirationDate'] as String) 
          : null,
      effectParameters: map['effectParameters'] != null 
          ? Map<String, dynamic>.from(map['effectParameters'] as Map) 
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ShopItem(id: $id, name: $name, status: $status)';
  }
}

/// Extension pour des fonctionnalités supplémentaires
extension ShopItemExtensions on ShopItem {
  /// Vérifie si l'item est débloqué (niveau suffisant)
  bool get isUnlocked => unlockLevel <= 1; // Remplacez par la logique de niveau

  /// Vérifie si l'item est expiré
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Vérifie si l'item peut être acheté
  bool get canBePurchased {
    return status == ShopItemStatus.locked && 
           !isExpired && 
           isUnlocked;
  }

  /// Vérifie si l'item peut être équipé
  bool get canBeEquipped {
    return type == ShopItemType.characterSkin && 
           status == ShopItemStatus.purchased;
  }
}