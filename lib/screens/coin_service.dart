import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinService with ChangeNotifier {
  int _currentCoins = 0;
  static const String _coinsKey = 'user_coins';

  int get currentCoins => _currentCoins;

  CoinService() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCoins = prefs.getInt(_coinsKey) ?? 0;
    notifyListeners();
  }

  Future<void> addCoins(int amount, {String source = 'gameplay'}) async {
    if (amount <= 0) return;

    _currentCoins += amount;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _currentCoins);
  }

  Future<bool> spendCoins(int amount, {String reason = 'purchase'}) async {
    if (amount <= 0 || _currentCoins < amount) return false;

    _currentCoins -= amount;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _currentCoins);
    return true;
  }

  Future<void> resetCoins() async {
    _currentCoins = 0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coinsKey);
  }
}
