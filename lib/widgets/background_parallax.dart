import 'package:flutter/material.dart';

class BackgroundParallax extends StatefulWidget {
  final double speed;
  final bool isDarkMode;
  
  const BackgroundParallax({
    super.key,
    required this.speed,
    this.isDarkMode = false,
  });

  @override
  State<BackgroundParallax> createState() => _BackgroundParallaxState();
}

class _BackgroundParallaxState extends State<BackgroundParallax> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ParallaxLayer> _layers;

  @override
  void initState() {
    super.initState();
    _initializeLayers();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Infinite animation
    )..repeat();
  }

  void _initializeLayers() {
    _layers = [
      // Far mountains (moves slowest)
      ParallaxLayer(
        assetPath: 'assets/background/layer_1.png',
        speedFactor: 0.2,
        tint: widget.isDarkMode ? Colors.blueGrey[800] : null,
      ),
      // Mid-ground hills
      ParallaxLayer(
        assetPath: 'assets/background/layer_2.png',
        speedFactor: 0.4,
        tint: widget.isDarkMode ? Colors.blueGrey[700] : null,
      ),
      // Close hills
      ParallaxLayer(
        assetPath: 'assets/background/layer_3.png',
        speedFactor: 0.6,
        tint: widget.isDarkMode ? Colors.blueGrey[600] : null,
      ),
      // Ground (moves fastest)
      ParallaxLayer(
        assetPath: 'assets/background/layer_4.png',
        speedFactor: 1.0,
        tint: widget.isDarkMode ? Colors.blueGrey[900] : null,
      ),
    ];
  }

  @override
  void didUpdateWidget(BackgroundParallax oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _initializeLayers();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Sky background (non-moving)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.isDarkMode
                      ? [
                          Colors.blueGrey[900]!,
                          Colors.blueGrey[800]!,
                        ]
                      : [
                          const Color(0xFF87CEEB),
                          const Color(0xFFE0F7FA),
                        ],
                ),
              ),
            ),
            // Parallax layers
            ..._layers.map((layer) => _buildParallaxLayer(layer)),
          ],
        );
      },
    );
  }

  Widget _buildParallaxLayer(ParallaxLayer layer) {
    final adjustedSpeed = widget.speed * layer.speedFactor;
    final xOffset = (_controller.value * adjustedSpeed) % 1.0;

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(-xOffset * layer.width, 0),
        child: Row(
          children: [
            _buildLayerImage(layer),
            _buildLayerImage(layer), // Seamless repeating
          ],
        ),
      ),
    );
  }

  Widget _buildLayerImage(ParallaxLayer layer) {
    return Image.asset(
      layer.assetPath,
      width: layer.width,
      height: double.infinity,
      fit: BoxFit.fitHeight,
      color: layer.tint,
      colorBlendMode: layer.tint != null ? BlendMode.modulate : null,
    );
  }
}

class ParallaxLayer {
  final String assetPath;
  final double speedFactor;
  final Color? tint;
  late final double width;

  ParallaxLayer({
    required this.assetPath,
    required this.speedFactor,
    this.tint,
  }) {
    // Assume all background layers are 1920px wide (standard HD width)
    // This will be scaled appropriately by Flutter
    width = 1920;
  }
}