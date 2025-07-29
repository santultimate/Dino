// models/power_up_type.dart

enum PowerUpType {
  healthBoost('Boost de Santé', 'health_boost', 'assets/images/power_up.png'),
  speedBoost('Boost de Vitesse', 'speed_boost', 'assets/images/power_up.png'),
  damageBoost('Boost de Dégâts', 'damage_boost', 'assets/images/power_up.png'),
  shield('Bouclier', 'shield', 'assets/images/power_up.png'),
  doubleCoins('Double Pièces', 'double_coins', 'assets/images/power_up.png');

  final String displayName;
  final String id;
  final String iconPath;

  const PowerUpType(this.displayName, this.id, this.iconPath);

  static PowerUpType fromId(String id) {
    return values.firstWhere(
      (type) => type.id == id,
      orElse: () => throw ArgumentError('Unknown PowerUpType id: $id'),
    );
  }

  static List<Map<String, dynamic>> get allAsMap => values.map((type) => type.toMap()).toList();

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'id': id,
        'iconPath': iconPath,
      };

  @override
  String toString() => displayName;
}