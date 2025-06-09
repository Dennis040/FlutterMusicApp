import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerManager {
  AudioPlayerManager({
    required this.songUrl,
  });

  final player = AudioPlayer();
  Stream<DurationState>? durationState;
  String songUrl;

  // void init() {
  //   durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
  //       player.positionStream,
  //       player.playbackEventStream,
  //       (position, playbackEvent) => DurationState(
  //           progess: position,
  //           buffered: playbackEvent.bufferedPosition,
  //           total: playbackEvent.duration));
  //   player.setUrl(songUrl);
  // }
  Future<void> init() async {
  durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
    player.positionStream,
    player.playbackEventStream,
    (position, playbackEvent) => DurationState(
      progess: position,
      buffered: playbackEvent.bufferedPosition,
      total: playbackEvent.duration,
    ),
  );

  try {
    print('Loading song: $songUrl');
    await player.setUrl(songUrl); // ⚠️ Quan trọng: thêm await
    print('Song loaded successfully!');
  } catch (e) {
    print('Error loading song: $e');
  }
}

}

class DurationState {
  const DurationState({
    required this.progess,
    required this.buffered,
    this.total,
  });

  final Duration progess;
  final Duration buffered;
  final Duration? total;
}
