import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neom_audio_player/data/implementations/player_hive_controller.dart';
import 'package:neom_audio_player/utils/audio_player_stats.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.instance.isGuestMode = true;
  });

  test(
    'guest player state uses safe defaults without opening personal Hive',
    () async {
      final controller = PlayerHiveController()
        ..lastQueueList = [
          {'id': 'previous-user-track'},
        ]
        ..lastIndex = 4
        ..lastPos = 120
        ..showHistory = true
        ..loadStart = true;

      await controller.fetchCachedData();
      await controller.fetchSettingsData();

      expect(controller.lastQueueList, isEmpty);
      expect(controller.lastIndex, 0);
      expect(controller.lastPos, 0);
      expect(controller.showHistory, isFalse);
      expect(controller.searchHistory, isEmpty);
      expect(controller.loadStart, isFalse);
      expect(controller.useDownload, isFalse);
      expect(controller.cacheSong, isFalse);
      expect(Hive.isBoxOpen(AppHiveBox.player.name), isFalse);
      expect(Hive.isBoxOpen(AppHiveBox.settings.name), isFalse);
    },
  );

  test('guest playback does not persist recently played data', () async {
    await expectLater(
      AudioPlayerStats.addRecentlyPlayed(
        const MediaItem(id: 'public-track', title: 'Public track'),
      ),
      completes,
    );

    expect(Hive.isBoxOpen(AppHiveBox.player.name), isFalse);
    expect(Hive.isBoxOpen(AppHiveBox.stats.name), isFalse);
  });

  test('guest queue, position and search writes do not open Hive', () async {
    final controller = PlayerHiveController();

    await controller.setLastQueue([
      {'id': 'guest-track'},
    ]);
    await controller.setLastIndexAndPos(3, 90);
    await controller.updateItemLastPos('guest-track', 45);
    await controller.setSearchQueries(['guest query']);
    await controller.addQuery('guest query');

    expect(Hive.isBoxOpen(AppHiveBox.player.name), isFalse);
    expect(Hive.isBoxOpen(AppHiveBox.settings.name), isFalse);
  });
}
