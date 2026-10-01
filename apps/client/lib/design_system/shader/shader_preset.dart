import '../tokens.dart';

class ShaderPreset {
  const ShaderPreset();
  static const reference = ShaderPreset();
  final color1 = AppColors.shaderYellow;
  final color2 = AppColors.shaderBlue;
  final color3 = AppColors.shaderViolet;
  final brightness = 1.5, density = 0.8, frequency = 5.5, amplitude = 7.0;
  final speed = 0.3, strength = 0.4, rotation = 140.0;
}
