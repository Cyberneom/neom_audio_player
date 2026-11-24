import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/ui/widgets/audio_player_bottom_app_bar.dart';
import 'package:neom_audio_player/ui/widgets/empty_screen.dart';

void main() {
  testWidgets('emptyScreen scales down cleanly without right overflow on 320px phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => emptyScreen(
              context,
              3,
              'Nada que',
              15.0,
              'Mostrar aquí',
              50.0,
              'Comenzar búsqueda',
              23.0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mostrar aquí'), findsOneWidget);
  });

  testWidgets('AudioPlayerBottomAppBar does not overflow with long labels on 320px phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: AudioPlayerBottomAppBar(
            color: Colors.white54,
            selectedColor: Colors.white,
            notchedShape: const CircularNotchedRectangle(),
            onTabSelected: (_) {},
            items: [
              MusicPlayerBottomAppBarItem(
                iconData: Icons.play_circle_fill,
                text: 'Audioteca',
              ),
              MusicPlayerBottomAppBarItem(
                iconData: Icons.library_music,
                text: 'Listas de reproducción',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Listas de reproducción'), findsOneWidget);
  });
}
