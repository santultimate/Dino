import 'package:flutter/material.dart';

class DinoWidget extends StatefulWidget {
  final double dinoY; // Position verticale (pour le saut)
  final double runVelocity; // Vitesse de course (pour l'animation)
  final bool isJumping;
  final bool isDucking;
  final bool isHit;
  final VoidCallback? onTap;
  final String runningAsset;
  final String jumpingAsset;
  final String duckingAsset;
  final String hitAsset;

  const DinoWidget({
    super.key,
    required this.dinoY,
    this.runVelocity = 0,
    this.isJumping = false,
    this.isDucking = false,
    this.isHit = false,
    this.onTap,
    this.runningAsset = 'assets/images/dino_run.png',
    this.jumpingAsset = 'assets/images/dino_jump.png',
    this.duckingAsset = 'assets/images/dino_duck.png',
    this.hitAsset = 'assets/images/dino_hit.png',
  });

  @override
  State<DinoWidget> createState() => _DinoWidgetState();
}

class _DinoWidgetState extends State<DinoWidget> with SingleTickerProviderStateMixin {
  late AnimationController _runController;
  late Animation<double> _runAnimation;
  int _currentFrame = 0;
  final int _runFrames = 4; // Nombre de frames d'animation

  @override
  void initState() {
    super.initState();
    _setupRunAnimation();
  }

  void _setupRunAnimation() {
    _runController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 ~/ (1 + widget.runVelocity * 2)),
    )..addListener(() {
        setState(() {
          _currentFrame = ((_runController.value * _runFrames) % _runFrames).floor();
        });
      });

    _runController.repeat();
  }

  @override
  void didUpdateWidget(DinoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runVelocity != widget.runVelocity) {
      _runController.duration = Duration(milliseconds: 600 ~/ (1 + widget.runVelocity * 2));
    }
  }

  @override
  void dispose() {
    _runController.dispose();
    super.dispose();
  }

  String _getCurrentAsset() {
    if (widget.isHit) return widget.hitAsset;
    if (widget.isJumping) return widget.jumpingAsset;
    if (widget.isDucking) return widget.duckingAsset;
    return widget.runningAsset.replaceFirst('.png', '_${_currentFrame + 1}.png');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const groundLevel = 0.2; // Niveau du sol (20% de la hauteur)

    return Positioned(
      left: 50,
      bottom: screenHeight * groundLevel + widget.dinoY,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 80,
          height: widget.isDucking ? 50 : 80,
          child: Stack(
            children: [
              // Ombre du dino
              if (!widget.isJumping)
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              
              // Dino principal
              Center(
                child: Image.asset(
                  _getCurrentAsset(),
                  width: widget.isDucking ? 90 : 80,
                  height: widget.isDucking ? 50 : 80,
                  filterQuality: FilterQuality.low,
                  isAntiAlias: true,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      return Container(
                        color: Colors.transparent,
                        width: 80,
                        height: 80,
                      );
                    }
                    return child;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}