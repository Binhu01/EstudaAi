import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/design_system/shader/motion_policy.dart';

void main() {
  test('shader stops for each independent reason and resumes only with every condition satisfied', () {
    expect(
      ShaderMotionPolicy.allows(
        enabled: true,
        reduceMotion: false,
        visible: true,
        foreground: true,
        tickerEnabled: true,
      ),
      true,
    );
    expect(
      ShaderMotionPolicy.allows(
        enabled: false,
        reduceMotion: false,
        visible: true,
        foreground: true,
        tickerEnabled: true,
      ),
      false,
    );
    expect(
      ShaderMotionPolicy.allows(
        enabled: true,
        reduceMotion: true,
        visible: true,
        foreground: true,
        tickerEnabled: true,
      ),
      false,
    );
    expect(
      ShaderMotionPolicy.allows(
        enabled: true,
        reduceMotion: false,
        visible: false,
        foreground: true,
        tickerEnabled: true,
      ),
      false,
    );
    expect(
      ShaderMotionPolicy.allows(
        enabled: true,
        reduceMotion: false,
        visible: true,
        foreground: false,
        tickerEnabled: true,
      ),
      false,
    );
    expect(
      ShaderMotionPolicy.allows(
        enabled: true,
        reduceMotion: false,
        visible: true,
        foreground: true,
        tickerEnabled: false,
      ),
      false,
    );
  });
}
