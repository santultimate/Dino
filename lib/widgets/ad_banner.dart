import 'package:flutter/material.dart';
import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  final AdService adService;
  final double? height;
  final EdgeInsets? margin;

  const AdBanner({
    super.key,
    required this.adService,
    this.height,
    this.margin,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (!widget.adService.isInitialized) return;

    // Simulation du chargement
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.adService.isInitialized || !_isLoaded) {
      return Container(
        height: widget.height ?? 50,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Publicité',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height ?? 50,
      margin: widget.margin,
      child: widget.adService.createBannerAd(),
    );
  }
} 