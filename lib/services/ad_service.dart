import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdService with ChangeNotifier {
  bool _isInitialized = false;
  bool _isInterstitialAdReady = false;

  bool get isInitialized => _isInitialized;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  /// Initialise le service de publicité
  Future<void> initialize() async {
    try {
      // Simulation de l'initialisation
      await Future.delayed(const Duration(milliseconds: 100));
      _isInitialized = true;
      if (kDebugMode) {
        print('📱 AdService initialized successfully (mock mode)');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing AdService: $e');
      }
    }
  }

  /// Crée une bannière publicitaire (mock)
  Widget createBannerAd() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: const Center(
        child: Text(
          '📱 Publicité (Mode Test)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Charge une publicité interstitielle (mock)
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      // Simulation du chargement
      await Future.delayed(const Duration(milliseconds: 500));
      _isInterstitialAdReady = true;
      if (kDebugMode) {
        print('📱 Interstitial ad loaded successfully (mock mode)');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading interstitial ad: $e');
      }
    }
  }

  /// Affiche une publicité interstitielle (mock)
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady) {
      if (kDebugMode) {
        print('📱 Showing interstitial ad (mock mode)');
      }
      _isInterstitialAdReady = false;
      notifyListeners();
      
      // Recharger une nouvelle publicité
      loadInterstitialAd();
    }
  }

  /// Affiche une publicité interstitielle après un délai
  Future<void> showInterstitialAdAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    await showInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 