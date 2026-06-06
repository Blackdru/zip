import 'package:flutter/material.dart';

/// Shared color mapping for dot colors used across all renderers.
/// Single source of truth — update here to add new colors.
class DotColors {
  DotColors._();

  static const Map<String, Color> colorMap = {
    'red': Color(0xFFFF5543),
    'blue': Color(0xFF43C6FF),
    'green': Color(0xFF7BFF43),
    'yellow': Color(0xFFFFC043),
    'orange': Color(0xFFFF8A43),
    'purple': Color(0xFFB843FF),
    'cyan': Color(0xFF43FFFF),
    'pink': Color(0xFFFF43B8),
  };

  static const Color fallback = Color(0xFFFFFFFF);

  /// Look up a color by name, returning [fallback] for unknown names.
  static Color resolve(String colorName) =>
      colorMap[colorName] ?? fallback;
}
