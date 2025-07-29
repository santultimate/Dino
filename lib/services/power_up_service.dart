// services/power_up_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/power_up_type.dart';

class PowerUpService with ChangeNotifier {
  final Map<PowerUpType, int> _ownedPowerUps = {};
  final Map<PowerUpType, bool> _activePowerUps = {};
  final Map<PowerUpType, DateTime?> _expirationTimes = {};
  bool _isLoading = false;
  bool _isSaving = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Map<PowerUpType, int> get ownedPowerUps => Map.unmodifiable(_ownedPowerUps);
  Map<PowerUpType, bool> get activePowerUps => Map.unmodifiable(_activePowerUps);

  // Initialization
  Future<void> initialize() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadPowerUpStates();
    } catch (e) {
      debugPrint('PowerUpService initialization failed: $e');
      await _resetToDefaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPowerUpStates() async {
    final prefs = await SharedPreferences.getInstance();

    for (final type in PowerUpType.values) {
      _ownedPowerUps[type] = prefs.getInt('power_up_${type.id}_count') ?? 0;
      _activePowerUps[type] = prefs.getBool('power_up_${type.id}_active') ?? false;

      final expirationString = prefs.getString('power_up_${type.id}_expires');
      _expirationTimes[type] = expirationString != null
          ? DateTime.tryParse(expirationString)
          : null;
    }

    await _validateExpirations();
  }

  Future<void> _validateExpirations() async {
    bool needsSave = false;
    final now = DateTime.now();

    for (final entry in _expirationTimes.entries) {
      if (entry.value != null && entry.value!.isBefore(now)) {
        _activePowerUps[entry.key] = false;
        _expirationTimes[entry.key] = null;
        needsSave = true;
      }
    }

    if (needsSave) {
      await _saveAllPowerUpStates();
    }
  }

  // Core Operations
  Future<bool> purchasePowerUp(PowerUpType type, int quantity) async {
    if (_isSaving) return false;

    _isSaving = true;
    notifyListeners();

    try {
      _ownedPowerUps.update(
        type,
        (count) => count + quantity,
        ifAbsent: () => quantity,
      );

      await _savePowerUpState(type);
      return true;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      _ownedPowerUps[type] = (_ownedPowerUps[type] ?? 0) - quantity;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> activatePowerUp(PowerUpType type, [Duration? duration]) async {
    if (_isSaving || (_ownedPowerUps[type] ?? 0) <= 0) return false;

    _isSaving = true;
    notifyListeners();

    try {
      _ownedPowerUps[type] = (_ownedPowerUps[type] ?? 1) - 1;
      _activePowerUps[type] = true;
      _expirationTimes[type] = duration != null
          ? DateTime.now().add(duration)
          : null;

      await _savePowerUpState(type);
      return true;
    } catch (e) {
      debugPrint('Activation failed: $e');
      _revertActivation(type);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _revertActivation(PowerUpType type) {
    _ownedPowerUps[type] = (_ownedPowerUps[type] ?? 0) + 1;
    _activePowerUps[type] = false;
    _expirationTimes[type] = null;
  }

  // Storage Operations
  Future<void> _savePowerUpState(PowerUpType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('power_up_${type.id}_count', _ownedPowerUps[type] ?? 0);
      await prefs.setBool('power_up_${type.id}_active', _activePowerUps[type] ?? false);

      if (_expirationTimes[type] != null) {
        await prefs.setString(
          'power_up_${type.id}_expires',
          _expirationTimes[type]!.toIso8601String(),
        );
      } else {
        await prefs.remove('power_up_${type.id}_expires');
      }
    } catch (e) {
      debugPrint('Save failed for ${type.id}: $e');
      rethrow;
    }
  }

  Future<void> _saveAllPowerUpStates() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      for (final type in PowerUpType.values) {
        await prefs.setInt('power_up_${type.id}_count', _ownedPowerUps[type] ?? 0);
        await prefs.setBool('power_up_${type.id}_active', _activePowerUps[type] ?? false);

        if (_expirationTimes[type] != null) {
          await prefs.setString(
            'power_up_${type.id}_expires',
            _expirationTimes[type]!.toIso8601String(),
          );
        } else {
          await prefs.remove('power_up_${type.id}_expires');
        }
      }
    } catch (e) {
      debugPrint('Batch save failed: $e');
      await _emergencyBackup();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _emergencyBackup() async {
    debugPrint('Attempting emergency backup...');
    // Placeholder for backup strategy
  }

  // Maintenance
  Future<void> _resetToDefaults() async {
    _ownedPowerUps.clear();
    _activePowerUps.clear();
    _expirationTimes.clear();

    for (final type in PowerUpType.values) {
      _ownedPowerUps[type] = 0;
      _activePowerUps[type] = false;
    }

    await _saveAllPowerUpStates();
  }

  // Utilities
  Duration? getRemainingDuration(PowerUpType type) {
    final expiration = _expirationTimes[type];
    if (expiration == null) return null;

    final remaining = expiration.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool isActive(PowerUpType type) => _activePowerUps[type] ?? false;

  Future<void> checkAndUpdateStates() async {
    await _validateExpirations();
  }

  // Debug
  Future<void> addTestData() async {
    for (final type in PowerUpType.values) {
      _ownedPowerUps[type] = 5;
    }
    await _saveAllPowerUpStates();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final type in PowerUpType.values) {
      await prefs.remove('power_up_${type.id}_count');
      await prefs.remove('power_up_${type.id}_active');
      await prefs.remove('power_up_${type.id}_expires');
    }

    await initialize();
  }
}
