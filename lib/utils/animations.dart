// lib/utils/animations.dart

// Placeholder animation utility
import 'package:flutter/animation.dart';

class AnimationUtils {
  static Animation<double> exampleCurve(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
  }
}
