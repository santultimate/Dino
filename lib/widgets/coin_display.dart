import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coin_service.dart';

class CoinDisplay extends StatefulWidget {
  final bool showAnimation;
  final double size;
  final Color? color;
  final bool showIcon;
  final TextStyle? textStyle;

  const CoinDisplay({
    super.key,
    this.showAnimation = true,
    this.size = 1.0,
    this.color,
    this.showIcon = true,
    this.textStyle,
  });

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  int _currentDisplayCoins = 0;
  int? _previousCoins;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 50),
    ]).animate(_animationController);

    _colorAnimation = ColorTween(
      begin: Colors.amber[700],
      end: Colors.lightGreenAccent[400],
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    )
    );
  

    // Initialisation avec la valeur actuelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coinService = Provider.of<CoinService>(context, listen: false);
      _currentDisplayCoins = coinService.currentCoins;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coinService = Provider.of<CoinService>(context);
    
    if (_previousCoins != null && 
        coinService.currentCoins != _previousCoins) {
      _handleCoinChange(coinService.currentCoins);
    }
    
    _previousCoins = coinService.currentCoins;
  }

  void _handleCoinChange(int newCoins) {
    setState(() {
      _currentDisplayCoins = newCoins;
    });

    if (widget.showAnimation) {
      _animationController.forward(from: 0).then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = Colors.amber[700];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation, 
        _rotateAnimation, 
        _colorAnimation
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * widget.size,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.color ?? defaultColor,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _colorAnimation.value ?? defaultColor!,
              widget.color ?? defaultColor!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showIcon) ...[
              const Icon(Icons.monetization_on, 
                color: Colors.white, 
                size: 20),
              const SizedBox(width: 6),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                _currentDisplayCoins.toString(),
                key: ValueKey<int>(_currentDisplayCoins),
                style: widget.textStyle ?? theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}