import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

// 🔑 QUAN TRỌNG: Bỏ SeekHandler để tắt hoàn toàn seek functionality
class MyAudioHandler extends BaseAudioHandler with QueueHandler {
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
          // 🔑 QUAN TRỌNG: Để trống systemActions
          systemActions: const <MediaAction>{},
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
          // 🔑 QUAN TRỌNG: KHÔNG SET bất kỳ position nào
          speed: player.speed,
          queueIndex: player.currentIndex,
        ),
      );
    });
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      await player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));

      // 🔑 QUAN TRỌNG: Tạo MediaItem KHÔNG có duration
      final noDurationMediaItem = MediaItem(
        id: mediaItem.id,
        title: mediaItem.title,
        artist: mediaItem.artist,
        artUri: mediaItem.artUri,
        // 🔑 KHÔNG SET duration
        // duration: null, // Thậm chí không cần set null
      );
      
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

  // 🔑 QUAN TRỌNG: KHÔNG implement seek methods
  // Nếu bạn extends SeekHandler, hãy bỏ nó đi
}