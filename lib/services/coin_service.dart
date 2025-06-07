import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinService with ChangeNotifier {
  static const String _coinsKey = 'user_coins';
  static const String _lastDailyRewardKey = 'last_daily_reward';

  int _coins = 0;
  DateTime? _lastDailyRewardDate;
  bool _isLoading = false;

  int get currentCoins => _coins;
  bool get isLoading => _isLoading;
  bool get canClaimDaily => _checkDailyRewardEligibility();

  CoinService() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt(_coinsKey) ?? 0;

      final lastRewardString = prefs.getString(_lastDailyRewardKey);
      _lastDailyRewardDate = lastRewardString != null
          ? DateTime.parse(lastRewardString)
          : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading coins: $e');
      }
      _coins = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCoins(int amount) async {
    if (amount <= 0) return false;

    _coins += amount;
    notifyListeners();

    return await _saveCoins();
  }

  Future<bool> deductCoins(int amount) async {
    if (amount <= 0 || _coins < amount) return false;

    _coins -= amount;
    notifyListeners();

    return await _saveCoins();
  }

  Future<bool> claimDailyReward() async {
    if (!canClaimDaily) return false;

    _lastDailyRewardDate = DateTime.now();
    _coins += 100; // Récompense quotidienne
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDailyRewardKey, _lastDailyRewardDate!.toIso8601String());

    return await _saveCoins();
  }

  Future<bool> _saveCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_coinsKey, _coins);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving coins: $e');
      }
      return false;
    }
  }

  bool _checkDailyRewardEligibility() {
    if (_lastDailyRewardDate == null) return true;

    final now = DateTime.now();
    final lastClaim = _lastDailyRewardDate!;

    return now.day != lastClaim.day ||
        now.month != lastClaim.month ||
        now.year != lastClaim.year;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coinsKey);
    await prefs.remove(_lastDailyRewardKey);

    _coins = 0;
    _lastDailyRewardDate = null;
    notifyListeners();
  }
}
