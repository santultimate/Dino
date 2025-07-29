import 'package:flutter/material.dart';
import '../models/power_up_type.dart';

class PowerUpWidget extends StatefulWidget {
  final double xPosition; // Position horizontale normalisée (-1.0 à 1.0)
  final double yPosition; // Position verticale normalisée (0.0 à 1.0)
  final bool visible;
  final String assetPath;
  final PowerUpType? powerUpType;
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
    this.powerUpType,
    this.size = 40.0,
    this.appearDuration = const Duration(milliseconds: 300),
    this.onCollected,
    this.isAnimated = true,
  }) : assert(xPosition >= -1.0 && xPosition <= 1.0),
       assert(yPosition >= 0.0 && yPosition <= 1.0);

  @override
  State<PowerUpWidget> createState() => _PowerUpWidgetState();
}

class _PowerUpWidgetState extends State<PowerUpWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onCollected,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: widget.appearDuration,
        curve: Curves.easeInOut,
        child: AnimatedAlign(
          duration:
              widget.isAnimated
                  ? const Duration(milliseconds: 100)
                  : Duration.zero,
          alignment: Alignment(widget.xPosition, widget.yPosition),
          child: _buildPowerUpContent(),
        ),
      ),
    );
  }

  Widget _buildPowerUpContent() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                widget.isAnimated
                    ? RotationTransition(
                      turns: const AlwaysStoppedAnimation(15 / 360),
                      child: _buildPowerUpImage(),
                    )
                    : _buildPowerUpImage(),
          ),
        );
      },
    );
  }

  Widget _buildPowerUpImage() {
    final imagePath = widget.powerUpType?.iconPath ?? widget.assetPath;

    return Image.asset(
      imagePath,
      width: widget.size,
      height: widget.size,
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
      errorBuilder: (context, error, stackTrace) {
        // Fallback si l'image ne charge pas
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.yellow,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: const Icon(Icons.star, color: Colors.orange, size: 20),
        );
      },
    );
  }
}
