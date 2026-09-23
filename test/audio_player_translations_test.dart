import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/data/translations/audio_player_de_translations.dart';
import 'package:neom_audio_player/data/translations/audio_player_en_translations.dart';
import 'package:neom_audio_player/data/translations/audio_player_es_translations.dart';
import 'package:neom_audio_player/data/translations/audio_player_fr_translations.dart';

void main() {
  final es = AudioPlayerEsTranslations.values;
  final others = {
    'en': AudioPlayerEnTranslations.values,
    'fr': AudioPlayerFrTranslations.values,
    'de': AudioPlayerDeTranslations.values,
  };

  test('every key is translated in all four languages', () {
    for (final MapEntry(key: name, value: locale) in others.entries) {
      expect(locale.keys.toSet().difference(es.keys.toSet()), isEmpty, reason: '$name has keys es lacks');
      expect(es.keys.toSet().difference(locale.keys.toSet()), isEmpty, reason: '$name is missing keys');
      expect(locale.values.where((v) => v.trim().isEmpty), isEmpty, reason: '$name has empty values');
    }
  });

  test('a placeholder is kept by every language', () {
    // trParams replaces "@name" tokens. A translation that drops or renames
    // one prints the raw token, or loses the value, in that language only.
    final placeholder = RegExp(r'@\w+');
    Set<String?> tokens(String s) => placeholder.allMatches(s).map((m) => m[0]).toSet();
    for (final MapEntry(key: name, value: locale) in others.entries) {
      for (final key in es.keys) {
        expect(tokens(locale[key]!), tokens(es[key]!), reason: '$name: $key');
      }
    }
  });
}
