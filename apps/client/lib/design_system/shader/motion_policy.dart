class ShaderMotionPolicy {
  static bool allows({
    required bool enabled,
    required bool reduceMotion,
    required bool visible,
    required bool foreground,
    required bool tickerEnabled,
  }) => enabled && !reduceMotion && visible && foreground && tickerEnabled;
}
