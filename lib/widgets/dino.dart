import 'package:flutter/material.dart';
import 'dart:math';
import '../models/power_up_type.dart';

class DinoWidget extends StatefulWidget {
  final double dinoY; // Position verticale (pour le saut)
  final double runVelocity; // Vitesse de course (pour l'animation)
  final bool isJumping;
  final bool isDucking;
  final bool isHit;
  final bool hasShield;
  final bool hasInvincibility;
  final bool hasSpeedBoost;
  final bool hasDoubleCoins;
  final bool hasDamageBoost;
  final PowerUpType? activePowerUp; // Power-up actuellement actif
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
    this.hasShield = false,
    this.hasInvincibility = false,
    this.hasSpeedBoost = false,
    this.hasDoubleCoins = false,
    this.hasDamageBoost = false,
    this.activePowerUp,
    this.onTap,
    this.runningAsset = 'assets/images/dino_run.png',
    this.jumpingAsset = 'assets/images/dino_jump.png',
    this.duckingAsset = 'assets/images/dino_duck.png',
    this.hitAsset = 'assets/images/dino_hit.png',
  });

  @override
  State<DinoWidget> createState() => _DinoWidgetState();
}

class _DinoWidgetState extends State<DinoWidget> with TickerProviderStateMixin {
  late AnimationController _runController;
  late AnimationController _jumpController;
  late AnimationController _particleController;
  int _currentFrame = 0;
  final int _runFrames = 4; // Nombre de frames d'animation

  // Ajout pour la traînée
  final List<_TrailParticle> _trail = [];
  static const int _maxTrail = 8;

  @override
  void initState() {
    super.initState();
    _setupRunAnimation();
    _setupJumpAnimation();
    _setupParticleAnimation();
  }

  void _setupRunAnimation() {
    _runController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200 ~/ (1 + widget.runVelocity * 0.5)),
    )..addListener(() {
      if (widget.isHit) {
        _runController.stop();
        return;
      }
      setState(() {
        _currentFrame =
            ((_runController.value * _runFrames) % _runFrames).floor();
      });
    });

    _runController.repeat();
  }

  void _setupJumpAnimation() {
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _setupParticleAnimation() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void didUpdateWidget(DinoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runVelocity != widget.runVelocity) {
      _runController.duration = Duration(
        milliseconds: 1200 ~/ (1 + widget.runVelocity * 0.5),
      );
    }

    // Gérer les changements d'état isHit
    if (widget.isHit && !oldWidget.isHit) {
      // Le dino vient d'être touché, arrêter l'animation
      _runController.stop();
    } else if (!widget.isHit && oldWidget.isHit) {
      // Le dino n'est plus touché, redémarrer l'animation
      _runController.repeat();
    }
  }

  @override
  void dispose() {
    _runController.dispose();
    _jumpController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  String _getCurrentAsset() {
    if (widget.isHit) return widget.hitAsset;
    if (widget.isJumping) return _getJumpingAsset();
    if (widget.isDucking) return _getDuckingAsset();
    return _getRunningAsset();
  }

  String _getRunningAsset() {
    final baseAsset = _getPowerUpBaseAsset();
    return baseAsset.replaceFirst('.png', '_${_currentFrame + 1}.png');
  }

  String _getJumpingAsset() {
    return _getPowerUpBaseAsset().replaceFirst('.png', '_jump.png');
  }

  String _getDuckingAsset() {
    return _getPowerUpBaseAsset().replaceFirst('.png', '_duck.png');
  }

  String _getPowerUpBaseAsset() {
    // Retourne le nom de base de l'image selon le power-up actif
    if (widget.activePowerUp != null) {
      switch (widget.activePowerUp!) {
        case PowerUpType.speedBoost:
          return 'assets/images/dino_speed';
        case PowerUpType.shield:
          return 'assets/images/dino_shield';
        case PowerUpType.healthBoost:
          return 'assets/images/dino_health';
        case PowerUpType.doubleCoins:
          return 'assets/images/dino_coins';
        case PowerUpType.damageBoost:
          return 'assets/images/dino_damage';
      }
    }
    // Image par défaut si aucun power-up
    return 'assets/images/dino';
  }

  String _getFallbackAsset() {
    // Retourne toujours les images par défaut
    if (widget.isHit) return widget.hitAsset;
    if (widget.isJumping) return widget.jumpingAsset;
    if (widget.isDucking) return widget.duckingAsset;
    return widget.runningAsset.replaceFirst(
      '.png',
      '_${_currentFrame + 1}.png',
    );
  }

  String _getDinoImage() {
    return _getCurrentAsset();
  }

  void _updateTrail() {
    if (widget.activePowerUp != null) {
      _trail.add(
        _TrailParticle(
          x: 0,
          y: 0,
          color: _getPowerUpColor(widget.activePowerUp!),
          opacity: 0.4,
          scale: 1.0,
        ),
      );
      if (_trail.length > _maxTrail) {
        _trail.removeAt(0);
      }
    } else {
      _trail.clear();
    }
  }

  Color _getPowerUpColor(PowerUpType type) {
    switch (type) {
      case PowerUpType.speedBoost:
        return Colors.greenAccent;
      case PowerUpType.shield:
        return Colors.blueAccent;
      case PowerUpType.healthBoost:
        return Colors.purpleAccent;
      case PowerUpType.doubleCoins:
        return Colors.amberAccent;
      case PowerUpType.damageBoost:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateTrail();
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_jumpController, _particleController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_jumpController.value * 15),
            child: Transform.scale(
              scale: 1.0 + (_jumpController.value * 0.05),
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

                    // Traînée colorée
                    ..._trail.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      return Positioned(
                        left: 0.0,
                        top: 0.0,
                        child: Opacity(
                          opacity: t.opacity * (i + 1) / _trail.length,
                          child: Transform.scale(
                            scale: 0.9 - (0.07 * (_trail.length - i)),
                            child: Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                color: t.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Particules de power-up
                    if (widget.activePowerUp != null) _buildPowerUpParticles(),
                    // Étincelles dynamiques
                    if (widget.activePowerUp == PowerUpType.speedBoost ||
                        widget.activePowerUp == PowerUpType.damageBoost)
                      _buildSparks(),

                    // Dino principal
                    Center(
                      child: Stack(
                        children: [
                          // Speed Boost effect (vert avec éclairs)
                          if (widget.hasSpeedBoost)
                            Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                          // Double Coins effect (doré avec pièces)
                          if (widget.hasDoubleCoins)
                            Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                          // Damage Boost effect (rouge avec flammes)
                          if (widget.hasDamageBoost)
                            Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),

                          // Shield effect (bleu)
                          if (widget.hasShield)
                            Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.8),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                          // Invincibility effect (violet)
                          if (widget.hasInvincibility)
                            Container(
                              width: widget.isDucking ? 90 : 80,
                              height: widget.isDucking ? 50 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),

                          // Dino image
                          Image.asset(
                            _getCurrentAsset(),
                            width: widget.isDucking ? 90 : 80,
                            height: widget.isDucking ? 50 : 80,
                            filterQuality: FilterQuality.low,
                            isAntiAlias: true,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (frame == null) {
                                return Container(
                                  color: Colors.transparent,
                                  width: 80,
                                  height: 80,
                                );
                              }
                              return child;
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback vers les images par défaut si les images de power-up n'existent pas
                              return Image.asset(
                                _getFallbackAsset(),
                                width: widget.isDucking ? 90 : 80,
                                height: widget.isDucking ? 50 : 80,
                                filterQuality: FilterQuality.low,
                                isAntiAlias: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPowerUpParticles() {
    final powerUp = widget.activePowerUp;
    if (powerUp == null) return const SizedBox.shrink();

    Color particleColor;
    IconData particleIcon;

    switch (powerUp) {
      case PowerUpType.speedBoost:
        particleColor = Colors.green;
        particleIcon = Icons.flash_on;
        break;
      case PowerUpType.shield:
        particleColor = Colors.blue;
        particleIcon = Icons.shield;
        break;
      case PowerUpType.healthBoost:
        particleColor = Colors.purple;
        particleIcon = Icons.favorite;
        break;
      case PowerUpType.doubleCoins:
        particleColor = Colors.amber;
        particleIcon = Icons.monetization_on;
        break;
      case PowerUpType.damageBoost:
        particleColor = Colors.red;
        particleIcon = Icons.local_fire_department;
        break;
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Stack(
            children: List.generate(6, (index) {
              final angle =
                  (index * 60 + _particleController.value * 360) *
                  3.14159 /
                  180;
              final radius = 30.0 + (_particleController.value * 10);
              final x = 40 + radius * cos(angle);
              final y = 40 + radius * sin(angle);

              return Positioned(
                left: x - 5,
                top: y - 5,
                child: Opacity(
                  opacity: 0.7,
                  child: Icon(particleIcon, color: particleColor, size: 10),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSparks() {
    final color =
        widget.activePowerUp == PowerUpType.speedBoost
            ? Colors.greenAccent
            : Colors.redAccent;
    final icon =
        widget.activePowerUp == PowerUpType.speedBoost
            ? Icons.flash_on
            : Icons.local_fire_department;
    final sparks = List.generate(8, (i) {
      final angle = (i * 45 + _particleController.value * 360) * 3.14159 / 180;
      final radius = 40.0 + 10 * sin(_particleController.value * 6.28 + i);
      final x = 40 + radius * cos(angle);
      final y = 40 + radius * sin(angle);
      return Positioned(
        left: x - 6,
        top: y - 6,
        child: Opacity(
          opacity: 0.8 - (i * 0.08),
          child: Icon(icon, color: color.withOpacity(0.7), size: 12),
        ),
      );
    });
    return Positioned.fill(child: Stack(children: sparks));
  }
}

class _TrailParticle {
  final double x;
  final double y;
  final Color color;
  final double opacity;
  final double scale;
  _TrailParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.opacity,
    required this.scale,
  });
}
