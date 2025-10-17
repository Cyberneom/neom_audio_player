import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_core/domain/use_cases/audio_lite_player_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';

class AudioLitePlayerController extends GetxController implements AudioLitePlayerService {

  final userServiceImpl = Get.find<UserService>();
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  int get durationInSeconds => audioPlayer.duration?.inSeconds ?? 0;

  @override
  Future<void> play() async {
    await audioPlayer.play();
  }

  @override
  Future<void> setFilePath(String path) async {
    await audioPlayer.setFilePath(path);
  }

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
  }

  @override
  void clear() {
    audioPlayer.dispose();
  }

  @override
  Future<void> pause() async {
    await audioPlayer.pause();
  }

}
