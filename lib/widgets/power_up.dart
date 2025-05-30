import 'package:flutter/material.dart';

class PowerUpWidget extends StatelessWidget {
  final double xPosition; // Position horizontale normalisée (-1.0 à 1.0)
  final double yPosition; // Position verticale normalisée (0.0 à 1.0)
  final bool visible;
  final String assetPath;
  final double size;
  final Duration appearDuration;
  final VoidCallback? onCollected;
  final bool isAnimated;

  const PowerUpWidget({
    super.key,
    required this.xPosition,
    this.yPosition = 1.0,
    this.visible = true,
    this.assetPath = 'assets/images/power_up.png',
    this.size = 40.0,
    this.appearDuration = const Duration(milliseconds: 300),
    this.onCollected,
    this.isAnimated = true,
  }) : assert(xPosition >= -1.0 && xPosition <= 1.0),
       assert(yPosition >= 0.0 && yPosition <= 1.0);

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onCollected,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: appearDuration,
        curve: Curves.easeInOut,
        child: AnimatedAlign(
          duration: isAnimated ? const Duration(milliseconds: 100) : Duration.zero,
          alignment: Alignment(xPosition, yPosition),
          child: _buildPowerUpContent(),
        ),
      ),
    );
  }

  Widget _buildPowerUpContent() {
    return SizedBox(
      width: size,
      height: size,
      child: isAnimated 
          ? RotationTransition(
              turns: const AlwaysStoppedAnimation(15 / 360),
              child: _buildPowerUpImage(),
            )
          : _buildPowerUpImage(),
    );
  }

  Widget _buildPowerUpImage() {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.low,
      isAntiAlias: true,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
    );
  }
}