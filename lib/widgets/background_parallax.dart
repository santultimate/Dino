import 'package:flutter/material.dart';

class BackgroundParallax extends StatelessWidget {
  final bool isNightMode;
  final String? customBackground;

  const BackgroundParallax({
    super.key,
    this.isNightMode = false,
    this.customBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child:
          customBackground != null
              ? Image.asset(
                customBackground!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                color: isNightMode ? Colors.indigo[800] : null,
                colorBlendMode: isNightMode ? BlendMode.multiply : null,
              )
              : null,
    );
  }
}
