import 'package:flutter/material.dart';
import '../models/power_up_type.dart';

class PowerUpService with ChangeNotifier {
  final List<PowerUp> _activePowerUps = [];

  List<PowerUp> get activePowerUps => List.unmodifiable(_activePowerUps);

  void spawnPowerUp() {
    final randomType = PowerUpType.values[DateTime.now().millisecond % PowerUpType.values.length];
    _activePowerUps.add(PowerUp(
      type: randomType,
      position: 1.0,
    ));
    notifyListeners();
  }

  void updatePowerUps(double speed) {
    for (var powerUp in _activePowerUps) {
      powerUp.position -= speed;
    }
    _activePowerUps.removeWhere((pu) => pu.position < -1.2);
    notifyListeners();
  }

  void clearPowerUps() {
    _activePowerUps.clear();
    notifyListeners();
  }
}

class PowerUp {
  final PowerUpType type;
  double position;

  PowerUp({
    required this.type,
    required this.position,
  });
}