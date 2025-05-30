import 'package:flutter/material.dart';

/// Un widget de fond défilant continu avec des fonctionnalités étendues :
/// - Défilement fluide infinie
/// - Support multi-calques (parallaxe)
/// - Configuration flexible
/// - Optimisé pour les performances
class ScrollingBackground extends StatelessWidget {
  final double scrollFactor; // 0.0 à 1.0
  final List<String> assetPaths;
  final List<double> layerSpeeds;
  final BoxFit fit;
  final Alignment alignment;
  final bool isHorizontal;
  final FilterQuality filterQuality;

  const ScrollingBackground({
    super.key,
    required this.scrollFactor,
    this.assetPaths = const ['assets/images/background.png'],
    this.layerSpeeds = const [1.0],
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.isHorizontal = true,
    this.filterQuality = FilterQuality.low,
  }) : assert(assetPaths.length == layerSpeeds.length, 
           'Chaque calque doit avoir une vitesse définie');

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final devicePixelRatio = media.devicePixelRatio;

    return Stack(
      children: [
        for (int i = 0; i < assetPaths.length; i++)
          _buildScrollingLayer(
            assetPath: assetPaths[i],
            speed: layerSpeeds[i],
            screenSize: screenSize,
            devicePixelRatio: devicePixelRatio,
          ),
      ],
    );
  }

  Widget _buildScrollingLayer({
    required String assetPath,
    required double speed,
    required Size screenSize,
    required double devicePixelRatio,
  }) {
    final offset = scrollFactor * speed;
    final unit = isHorizontal ? screenSize.width : screenSize.height;

    return Stack(
      children: [
        Positioned(
          left: isHorizontal ? offset % unit : 0,
          top: isHorizontal ? 0 : offset % unit,
          child: _buildImageTile(assetPath, screenSize),
        ),
        Positioned(
          left: isHorizontal ? (offset % unit) - unit : 0,
          top: isHorizontal ? 0 : (offset % unit) - unit,
          child: _buildImageTile(assetPath, screenSize),
        ),
      ],
    );
  }

  Widget _buildImageTile(String assetPath, Size screenSize) {
    return Image.asset(
      assetPath,
      width: isHorizontal ? screenSize.width : null,
      height: isHorizontal ? null : screenSize.height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      isAntiAlias: true,
      repeat: ImageRepeat.noRepeat,
      cacheWidth: (screenSize.width * (isHorizontal ? 2 : 1)).toInt(),
      cacheHeight: (screenSize.height * (isHorizontal ? 1 : 2)).toInt(),
    );
  }
}