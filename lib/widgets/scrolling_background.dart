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
  final bool isNightMode;

  const ScrollingBackground({
    super.key,
    required this.scrollFactor,
    this.assetPaths = const [
      'assets/background/layer_1.png',
      'assets/background/layer_2.png',
      'assets/background/layer_3.png',
      'assets/background/layer_4.png',
    ],
    this.layerSpeeds = const [0.2, 0.4, 0.6, 0.8],
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.isHorizontal = true,
    this.filterQuality = FilterQuality.low,
    this.isNightMode = false,
  }) : assert(
         assetPaths.length == layerSpeeds.length,
         'Chaque calque doit avoir une vitesse définie',
       );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final devicePixelRatio = media.devicePixelRatio;

    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isNightMode
                  ? [Colors.indigo[900]!, Colors.black]
                  : [Colors.lightBlue[300]!, Colors.lightBlue[100]!],
        ),
      ),
      child: Stack(
        children: [
          for (int i = 0; i < assetPaths.length; i++)
            _buildScrollingLayer(
              assetPath: assetPaths[i],
              speed: layerSpeeds[i],
              screenSize: screenSize,
              devicePixelRatio: devicePixelRatio,
            ),
        ],
      ),
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
      color: isNightMode ? Colors.indigo[800] : null,
      colorBlendMode: isNightMode ? BlendMode.multiply : null,
    );
  }
}
