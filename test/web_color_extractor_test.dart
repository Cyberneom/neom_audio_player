import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/ui/web/utils/web_color_extractor.dart';

void main() {
  group('WebColorExtractor contrast & safety', () {
    test('ensureReadableOnDark lifts pitch-dark accents above minLightness', () {
      final veryDark = HSLColor.fromAHSL(1.0, 210, 0.4, 0.12).toColor();
      final readable = WebColorExtractor.ensureReadableOnDark(veryDark);
      final hsl = HSLColor.fromColor(readable);
      expect(hsl.lightness, greaterThanOrEqualTo(0.55));
      expect(hsl.saturation, greaterThanOrEqualTo(0.25));
    });

    test('ensureReadableOnDark preserves already readable accents', () {
      final bright = HSLColor.fromAHSL(1.0, 180, 0.7, 0.65).toColor();
      final result = WebColorExtractor.ensureReadableOnDark(bright);
      expect(result, equals(bright));
    });

    test('rejects unsafe/private artwork URLs and malformed cache keys', () {
      expect(WebColorExtractor.isSafeWebArtworkUrl('http://localhost/a.png'), isFalse);
      expect(WebColorExtractor.isSafeWebArtworkUrl('javascript:alert(1)'), isFalse);
      expect(WebColorExtractor.isSafeWebArtworkUrl('https://cdn.gigmeout.com/cover.jpg'), isTrue);
      expect(WebColorExtractor.isSafeCacheKey('__proto__'), isFalse);
      expect(WebColorExtractor.isSafeCacheKey('track_123'), isTrue);
    });
  });
}
