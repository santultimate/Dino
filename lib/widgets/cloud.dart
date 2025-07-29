import 'package:flutter/material.dart';

class CloudWidget extends StatefulWidget {
  final double speed;
  final double initialX;
  final double y;
  final double size;

  const CloudWidget({
    super.key,
    required this.speed,
    required this.initialX,
    required this.y,
    this.size = 60.0,
  });

  @override
  State<CloudWidget> createState() => _CloudWidgetState();
}

class _CloudWidgetState extends State<CloudWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _currentX;

  @override
  void initState() {
    super.initState();
    _currentX = widget.initialX;

    _controller = AnimationController(
      duration: Duration(milliseconds: (10000 / widget.speed).round()),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.initialX,
      end: -widget.size,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _animation.addListener(() {
      setState(() {
        _currentX = _animation.value;
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentX,
      top: widget.y,
      child: Container(
        width: widget.size,
        height: widget.size * 0.6,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(widget.size * 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Partie principale du nuage
            Positioned(
              left: widget.size * 0.1,
              top: widget.size * 0.2,
              child: Container(
                width: widget.size * 0.8,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(widget.size * 0.2),
                ),
              ),
            ),
            // Partie supérieure du nuage
            Positioned(
              left: widget.size * 0.2,
              top: widget.size * 0.1,
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(widget.size * 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScrollingClouds extends StatefulWidget {
  final double speed;
  final bool isPaused;
  final int cloudCount;

  const ScrollingClouds({
    super.key,
    this.speed = 1.0,
    this.isPaused = false,
    this.cloudCount = 5,
  });

  @override
  State<ScrollingClouds> createState() => _ScrollingCloudsState();
}

class _ScrollingCloudsState extends State<ScrollingClouds> {
  List<double> cloudPositions = [];
  List<double> cloudSpeeds = [];

  @override
  void initState() {
    super.initState();
    _initializeClouds();
  }

  void _initializeClouds() {
    cloudPositions = List.generate(widget.cloudCount, (index) {
      return 1.0 + (index * 0.8) + (index * 0.2);
    });
    cloudSpeeds = List.generate(widget.cloudCount, (index) {
      return 0.5 + (index * 0.1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.cloudCount, (index) {
        return Positioned(
          left: cloudPositions[index] * MediaQuery.of(context).size.width,
          top: 50 + (index * 30),
          child: CloudWidget(
            speed: cloudSpeeds[index] * widget.speed,
            initialX: cloudPositions[index] * MediaQuery.of(context).size.width,
            y: 50 + (index * 30),
            size: 60.0,
          ),
        );
      }),
    );
  }

  void updateClouds() {
    if (widget.isPaused) return;

    setState(() {
      for (int i = 0; i < cloudPositions.length; i++) {
        cloudPositions[i] -= cloudSpeeds[i] * widget.speed * 0.01;
        if (cloudPositions[i] < -0.2) {
          cloudPositions[i] = 1.2;
        }
      }
    });
  }
}
