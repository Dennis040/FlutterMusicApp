import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    player.playbackEventStream.listen((event) {
      final playing = player.playing;
      final state = player.processingState;
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: {
            // MediaAction.seek,
            // MediaAction.seekForward,
            // MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState:
              const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[state]!,
          playing: playing,
          // updatePosition: player.position,
          // bufferedPosition: player.bufferedPosition,
          speed: player.speed,
          queueIndex: player.currentIndex,
          // updateTime: DateTime.now(),
        ),
      );
    });
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      await player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));

      //  Lấy duration thật từ just_audio sau khi load xong
      // final duration = player.duration;

      //  Tạo MediaItem mới có duration
      // final updatedMediaItem = mediaItem.copyWith(duration: duration);

      // ⚠️ Loại bỏ duration để ẩn seekbar trên notification
      final noDurationMediaItem = mediaItem.copyWith(duration: null);
      //  Cập nhật queue & mediaItem để notification nhận biết đúng thông tin
      queue.value = [noDurationMediaItem];
      this.mediaItem.add(noDurationMediaItem);

      await player.play();
    } catch (e) {
      debugPrint("Lỗi khi phát bài hát: $e");
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> skipToNext() async => player.seekToNext();

  @override
  Future<void> skipToPrevious() async => player.seekToPrevious();
}
