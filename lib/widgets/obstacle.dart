import 'package:flutter/material.dart';

class ObstacleWidget extends StatelessWidget {
  final double positionX; // Position horizontale sur l'écran
  final double obstacleY; // Décalage vertical supplémentaire
  final String assetPath;
  final double width;
  final double height;
  final bool isAnimated;
  final double animationValue;
  final VoidCallback? onCollide;
  final Hitbox hitbox;

  const ObstacleWidget({
    super.key,
    required this.positionX,
    this.obstacleY = 0,
    this.assetPath = 'assets/images/cactus.png',
    this.width = 40,
    this.height = 60,
    this.isAnimated = false,
    this.animationValue = 0,
    this.onCollide,
    this.hitbox = const Hitbox(0.8, 0.9),
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseY = screenHeight * 0.2;

    return Positioned(
      left: positionX,
      bottom: baseY + obstacleY,
      child: GestureDetector(
        onTap: onCollide,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              _buildObstacleVisual(),
              // Activez ceci pour debuguer les zones de collision
              // _buildHitboxDebug(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObstacleVisual() {
    return Transform(
      transform: isAnimated
          ? Matrix4.rotationZ(animationValue * 0.1)
          : Matrix4.identity(),
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        isAntiAlias: true,
        frameBuilder: (context, child, frame, _) {
          return AnimatedOpacity(
            opacity: frame != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildHitboxDebug() {
    return Positioned(
      left: width * (1 - hitbox.widthRatio) / 2,
      top: height * (1 - hitbox.heightRatio),
      child: Container(
        width: width * hitbox.widthRatio,
        height: height * hitbox.heightRatio,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          border: Border.all(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}

class Hitbox {
  final double widthRatio;
  final double heightRatio;

  const Hitbox(this.widthRatio, this.heightRatio)
      : assert(widthRatio > 0 && widthRatio <= 1),
        assert(heightRatio > 0 && heightRatio <= 1);
}
