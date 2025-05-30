// models/power_up_type.dart

enum PowerUpType {
  healthBoost('Boost de Santé', 'health_boost', 'assets/powerups/health.png'),
  speedBoost('Boost de Vitesse', 'speed_boost', 'assets/powerups/speed.png'),
  damageBoost('Boost de Dégâts', 'damage_boost', 'assets/powerups/damage.png'),
  shield('Bouclier', 'shield', 'assets/powerups/shield.png'),
  doubleCoins('Double Pièces', 'double_coins', 'assets/powerups/coins.png');

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