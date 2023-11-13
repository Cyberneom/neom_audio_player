import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/use_cases/neom_audio_handler.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../../utils/music_player_utilities.dart';

class SeekBar extends StatefulWidget {
  final NeomAudioHandler audioHandler;
  final Duration duration;
  final Duration position;
  ///DEPRECATED final Duration bufferedPosition;
  final bool offline;
  ///DEPRECATED final double width;
  ///DEPRECATED final double height;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({super.key,
    required this.duration,
    required this.position,
    required this.offline,
    required this.audioHandler,
    ///DEPRECATED required this.width,
    ///DEPRECATED required this.height,
    ///DEPRECATED this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = min(
      _dragValue ?? widget.position.inMilliseconds.toDouble(),
      widget.duration.inMilliseconds.toDouble(),
    );
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //TODO Verify
                // if (widget.offline)
                //   Text(
                //     'Offline',
                //     style: TextStyle(
                //       fontWeight: FontWeight.w500,
                //       color: Theme.of(context).disabledColor,
                //       fontSize: 14.0,
                //     ),
                //   )
                // else
                const SizedBox(),
                StreamBuilder<double>(
                  stream: widget.audioHandler.speed,
                  builder: (context, snapshot) {
                    final String speedValue =
                        '${snapshot.data?.toStringAsFixed(1) ?? 1.0}x';
                    return GestureDetector(
                      child: Text(
                        speedValue,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: speedValue == '1.0x'
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
                      onTap: () {
                        MusicPlayerUtilities.showSpeedSliderDialog(
                          context: context,
                          title: PlayerTranslationConstants.adjustSpeed.tr,
                          divisions: 25,
                          min: 0.5,
                          max: 3.0,
                          audioHandler: widget.audioHandler,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 2.0,
            ),
            child: Stack(
              children: [
                SliderTheme(
                  data: _sliderThemeData.copyWith(
                    inactiveTrackColor: Theme.of(context).iconTheme.color!.withOpacity(0.3),
                    activeTrackColor: Theme.of(context).iconTheme.color,
                    thumbColor: Theme.of(context).iconTheme.color,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0,),
                    overlayShape: SliderComponentShape.noThumb,
                  ),
                  child: Slider(
                    max: widget.duration.inMilliseconds.toDouble(),
                    value: value,
                    onChanged: (value) {
                      if (!_dragging) _dragging = true;
                      setState(() {
                        _dragValue = value;
                      });
                      widget.onChanged?.call(Duration(milliseconds: value.round()));
                    },
                    onChangeEnd: (value) {
                      widget.onChangeEnd?.call(Duration(milliseconds: value.round()));
                      _dragging = false;
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch('$_position')?.group(1) ?? '$_position',
                ),
                Text(RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                    .firstMatch('$_duration')?.group(1) ?? '$_duration',
                  ///DEPRECATED
                  // style: Theme.of(context).textTheme.caption!.copyWith(
                  //       color: Theme.of(context).iconTheme.color,
                  //     ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration get _duration => widget.duration;
  Duration get _position => widget.position;

}
