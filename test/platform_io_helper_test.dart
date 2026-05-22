// Tests for `platform_io_helper` (web stub vs IO implementation).
// En tests Flutter standard, dart:io está disponible (host es VM/desktop),
// así que verificamos la implementación IO.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/platform_io_helper.dart';

void main() {
  group('platform_io_helper — IO implementation (no web stub)', () {
    test('supportsLocalFiles: true en plataforma con dart:io', () {
      // Tests corren en VM/desktop, por lo que dart:io está disponible.
      expect(supportsLocalFiles, isTrue);
    });

    test('createFileImage retorna ImageProvider con path', () {
      final image = createFileImage('/some/fake/path.png');
      expect(image, isNotNull); // FileImage en VM
    });

    test('fileUri retorna Uri parseable', () {
      final uri = fileUri('/path/to/file.mp3');
      expect(uri, isA<Uri>());
    });

    test('getTempDirPath retorna null sin path_provider configurado', () async {
      // En tests sin TestWidgetsFlutterBinding + plugin path_provider
      // mockeado, getApplicationDocumentsDirectory falla y retorna null.
      // Verifica que el helper sea defensivo y no crashee.
      final tempPath = await getTempDirPath();
      expect(tempPath, isNull);
    });

    test('fileExists con path inexistente → false', () async {
      final exists = await fileExists('/this/path/does/not/exist/at/all.xyz');
      expect(exists, isFalse);
    });

    test('getFileLength con path inexistente → null', () async {
      final size = await getFileLength('/non/existing/file.txt');
      // FileSystemException → return null
      expect(size, isNull);
    });
  });
}
