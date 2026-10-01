import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/external_links.dart';

void main() {
  test('external links are constrained to HTTPS educational sources', () {
    expect(
      isStudyLink(Uri.parse('https://www.youtube.com/watch?v=TEhv11SkDUs')),
      isTrue,
    );
    for (final bad in [
      'javascript:alert(1)',
      'http://www.youtube.com/',
      'https://youtube.com.attacker.test/',
      'https://name@www.youtube.com/',
    ]) {
      expect(isStudyLink(Uri.parse(bad)), isFalse);
    }
  });
}
