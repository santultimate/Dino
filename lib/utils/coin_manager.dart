import 'package:flutter/foundation.dart'; // Ajout de cet import pour debugPrint
import 'package:shared_preferences/shared_preferences.dart';

class CoinManager {
  static const _coinKey = 'user_coins';
  static const _totalEarnedKey = 'total_coins_earned';
  static const _totalSpentKey = 'total_coins_spent';
  static const _lastUpdateKey = 'last_coin_update';

  // Singleton instance
  static final CoinManager _instance = CoinManager._internal();
  factory CoinManager() => _instance;
  CoinManager._internal();

  // Cache des valeurs pour performance
  int _cachedCoins = 0;
  int _cachedTotalEarned = 0;
  int _cachedTotalSpent = 0;
  DateTime? _lastUpdate;

  /// Initialisation - à appeler au démarrage de l'app
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCoins = prefs.getInt(_coinKey) ?? 0;
      _cachedTotalEarned = prefs.getInt(_totalEarnedKey) ?? 0;
      _cachedTotalSpent = prefs.getInt(_totalSpentKey) ?? 0;
      final lastUpdateMillis = prefs.getInt(_lastUpdateKey);
      _lastUpdate = lastUpdateMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis)
          : null;
    } catch (e) {
      debugPrint('Error initializing CoinManager: $e');
    }
  }

  /// Récupère le nombre actuel de coins (depuis le cache)
  int get currentCoins => _cachedCoins;

  /// Récupère le total historique des coins gagnés
  int get totalEarned => _cachedTotalEarned;

  /// Récupère le total historique des coins dépensés
  int get totalSpent => _cachedTotalSpent;

  /// Dernière mise à jour des coins
  DateTime? get lastUpdate => _lastUpdate;

  /// Ajoute des coins et met à jour les statistiques
  Future<void> addCoins(int amount, {String source = 'gameplay'}) async {
    if (amount <= 0) {
      debugPrint('Attempt to add invalid amount of coins: $amount');
      return;
    }

    try {
      _cachedCoins += amount;
      _cachedTotalEarned += amount;
      _lastUpdate = DateTime.now();

      await _saveToPrefs();
      _logCoinEvent('earn', amount, source);
    } catch (e) {
      debugPrint('Error adding coins: $e');
      rethrow;
    }
  }

  /// Dépense des coins si le solde est suffisant
  Future<bool> spendCoins(int amount, {String reason = 'purchase'}) async {
    if (amount <= 0) {
      debugPrint('Attempt to spend invalid amount of coins: $amount');
      return false;
    }

    if (_cachedCoins < amount) {
      debugPrint('Insufficient coins: ${_cachedCoins} < $amount');
      return false;
    }

    try {
      _cachedCoins -= amount;
      _cachedTotalSpent += amount;
      _lastUpdate = DateTime.now();

      await _saveToPrefs();
      _logCoinEvent('spend', amount, reason);
      return true;
    } catch (e) {
      debugPrint('Error spending coins: $e');
      rethrow;
    }
  }

  /// Réinitialise complètement les coins (pour debug/testing)
  Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_coinKey),
        prefs.remove(_totalEarnedKey),
        prefs.remove(_totalSpentKey),
        prefs.remove(_lastUpdateKey),
      ]);

      _cachedCoins = 0;
      _cachedTotalEarned = 0;
      _cachedTotalSpent = 0;
      _lastUpdate = null;
    } catch (e) {
      debugPrint('Error resetting CoinManager: $e');
      rethrow;
    }
  }

  /// Sauvegarde toutes les valeurs dans SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setInt(_coinKey, _cachedCoins),
        prefs.setInt(_totalEarnedKey, _cachedTotalEarned),
        prefs.setInt(_totalSpentKey, _cachedTotalSpent),
        if (_lastUpdate != null)
          prefs.setInt(_lastUpdateKey, _lastUpdate!.millisecondsSinceEpoch),
      ]);
    } catch (e) {
      debugPrint('Error saving coin data: $e');
      rethrow;
    }
  }

  /// Journalisation des événements
  void _logCoinEvent(String type, int amount, String context) {
    if (kDebugMode) {
      debugPrint('Coin event: $type $amount coins ($context) | '
          'New balance: $_cachedCoins | '
          'Total earned: $_cachedTotalEarned | '
          'Total spent: $_cachedTotalSpent');
    }
    
    // À implémenter: analytics.logEvent('coin_$type', {
    //   'amount': amount,
    //   'context': context,
    //   'new_balance': _cachedCoins,
    // });
  }

  /// Vérifie si l'utilisateur peut se permettre un achat
  bool canAfford(int price) {
    if (price < 0) {
      debugPrint('Invalid price: $price');
      return false;
    }
    return _cachedCoins >= price;
  }
}