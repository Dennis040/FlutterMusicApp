import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../model/song.dart';
import '../../model/lyrics.dart';
// import '../service/lyrics_service.dart';
import 'audio_player_manager.dart';
import 'dart:async';

class PlayingMusicInterface extends StatefulWidget {
  const PlayingMusicInterface({
    super.key,
    required this.song,
    required this.audioPlayerManager,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
  });

  final Song song;
  final AudioPlayerManager audioPlayerManager;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<bool> onShuffle;
  final ValueChanged<LoopMode> onRepeat;

  @override
  State<PlayingMusicInterface> createState() => _PlayingMusicInterfaceState();
}

class _PlayingMusicInterfaceState extends State<PlayingMusicInterface>
    with TickerProviderStateMixin {
  bool _isShuffled = false;
  // bool _isPlaying = false;
  LoopMode _loopMode = LoopMode.off;
  Lyrics? _lyrics;
  int _currentLyricIndex = 0;
  bool _showLyrics = false;
  late AnimationController _imageAnimationController;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.black;
  double _volume = 1.0;
  final ScrollController _lyricsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initPlayer();
    _generateColors();
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    if (_showLyrics) {
      _pageAnimationController.reverse();
    } else {
      _pageAnimationController.forward();
    }
    setState(() {
      _showLyrics = !_showLyrics;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! < 0 && !_showLyrics) {
      // Swipe left
      _pageAnimationController.forward();
      setState(() {
        _showLyrics = true;
      });
    } else if (details.primaryVelocity! > 0 && _showLyrics) {
      // Swipe right
      _pageAnimationController.reverse();
      setState(() {
        _showLyrics = false;
      });
    }
  }

  Future<void> _initPlayer() async {
    await widget.audioPlayerManager.init(); // Đợi nhạc load xong
    widget.audioPlayerManager.player.play(); // Bắt đầu phát nhạc
    _loadLyrics();
    widget.audioPlayerManager.player.positionStream.listen(_updateCurrentLyric);
  }

  Future<void> _loadLyrics() async {
    try {
      debugPrint("Loading lyrics for song: ${widget.song.songName}");
      debugPrint("LRC URL: ${widget.song.linkLrc}");

      if (widget.song.linkLrc == null || widget.song.linkLrc == "null") {
        debugPrint("No LRC URL provided for this song");
        setState(() {
          _lyrics = Lyrics(
            lines: [],
            error: "No lyrics available for this song",
          );
        });
        return;
      }

      final lyrics = await Lyrics.fromUrl(widget.song.linkLrc);

      if (lyrics.error != null) {
        debugPrint("Error loading lyrics: ${lyrics.error}");
      } else {
        debugPrint("Successfully loaded ${lyrics.lines.length} lyric lines");
        if (lyrics.lines.isEmpty) {
          debugPrint("Warning: No lyric lines found in the LRC file");
        }
      }

      setState(() {
        _lyrics = lyrics;
      });
    } catch (e) {
      debugPrint("Error in _loadLyrics: $e");
      setState(() {
        _lyrics = Lyrics(lines: [], error: "Failed to load lyrics: $e");
      });
    }
  }

  Future<void> _generateColors() async {
    try {
      final imageProvider = NetworkImage(widget.song.songImage);
      final Completer<Size> completer = Completer<Size>();

      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()),
        );
      });

      imageStream.addListener(listener);
      await completer.future;
      imageStream.removeListener(listener);

      paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200),
      );

      // print('Generated palette: ${paletteGenerator?.vibrantColor?.color}');

      setState(() {});
    } catch (e) {
      // print('Lỗi tạo palette: $e');
    }
  }

  Color getSafeBackgroundColor(PaletteGenerator? palette, Color fallback) {
    final List<Color?> candidates = [
      palette?.darkVibrantColor?.color,
      palette?.vibrantColor?.color,
      palette?.dominantColor?.color,
      palette?.lightMutedColor?.color,
    ];

    for (final color in candidates) {
      if (color != null && color.computeLuminance() < 0.8) {
        return color;
      }
    }

    return fallback; // fallback là màu đen hoặc màu mặc định bạn chọn
  }

  void _updateCurrentLyric(Duration position) {
    if (_lyrics == null || _lyrics!.lines.isEmpty) return;

    for (int i = 0; i < _lyrics!.lines.length; i++) {
      if (i == _lyrics!.lines.length - 1 ||
          (position >= _lyrics!.lines[i].timestamp &&
              position < _lyrics!.lines[i + 1].timestamp)) {
        if (_currentLyricIndex != i) {
          setState(() {
            _currentLyricIndex = i;
          });
          _scrollToCurrentLyric();
        }
        break;
      }
    }
  }

  void _scrollToCurrentLyric() {
    if (!_showLyrics || _lyrics == null || _lyrics!.lines.isEmpty) return;

    final itemHeight = 60.0; // Chiều cao của mỗi dòng lời bài hát
    final screenHeight = MediaQuery.of(context).size.height;
    final viewportHeight = screenHeight * 0.6; // Chiều cao vùng hiển thị lời bài hát

    // Tính toán vị trí cần cuộn đến
    final targetPosition = _currentLyricIndex * itemHeight - (viewportHeight / 2) + itemHeight;

    // Đảm bảo không cuộn quá giới hạn
    final maxScroll = _lyricsScrollController.position.maxScrollExtent;
    final minScroll = 0.0;
    final clampedPosition = targetPosition.clamp(minScroll, maxScroll);

    // Cuộn đến vị trí mới
    _lyricsScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = getSafeBackgroundColor(paletteGenerator, defaultColor);

    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.song.songName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: _showLyrics ? _buildLyricsView() : _buildAlbumArtView(),
            ),
            _buildSongInfo(),
            _buildPlaybackControls(),
            const SizedBox(height: 16),
            _buildAdditionalControls(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtView() {
    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: Center(
        child: Hero(
          tag: 'album_art_${widget.song.songId}',
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      paletteGenerator?.dominantColor?.color ??
                      paletteGenerator?.dominantColor?.color ??
                      defaultColor,
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: RotationTransition(
              turns: _imageAnimationController,
              child: ClipOval(
                child: Image.network(
                  widget.song.songImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.songName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.song.artistName,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Xử lý khi nhấn yêu thích
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsView() {
    if (_lyrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lyrics!.error != null) {
      return Center(
        child: Text(
          _lyrics!.error!,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_lyrics!.lines.isEmpty) {
      return const Center(
        child: Text(
          'No lyrics available for this song',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: ListView.builder(
        controller: _lyricsScrollController,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 0,
          bottom: 0,
        ),
        itemCount: _lyrics!.lines.length,
        itemBuilder: (context, index) {
          final line = _lyrics!.lines[index];
          final isCurrentLine = index == _currentLyricIndex;
          final isNextLine = index == _currentLyricIndex + 1;
          final isPreviousLine = index == _currentLyricIndex - 1;

          return Container(
            height: 60, // Chiều cao cố định cho mỗi dòng
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isCurrentLine ? 20 : (isNextLine || isPreviousLine ? 18 : 16),
                color: isCurrentLine 
                    ? Colors.white 
                    : (isNextLine || isPreviousLine ? Colors.white70 : Colors.grey),
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Roboto',
                height: 1.5,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        StreamBuilder<Duration?>(
          stream: widget.audioPlayerManager.player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration =
                widget.audioPlayerManager.player.duration ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(
                      0,
                      duration.inMilliseconds.toDouble(),
                    ),
                    max:
                        duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1,
                    onChanged: (value) {
                      widget.audioPlayerManager.player.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              iconSize: 36,
              onPressed: widget.onPrevious,
            ),
            StreamBuilder<PlayerState>(
              stream: widget.audioPlayerManager.player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 48.0,
                    height: 48.0,
                    child: const CircularProgressIndicator(color: Colors.white),
                  );
                } else if (playing != true) {
                  return IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    iconSize: 64,
                    onPressed: () {
                      widget.audioPlayerManager.player.play();
                      // MusicPlayerManager.resumeMusic();
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white),
                    iconSize: 64,
                    onPressed: () {
                      widget.audioPlayerManager.player.pause();
                      // MusicPlayerManager.pauseMusic();
                    },
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              iconSize: 36,
              onPressed: widget.onNext,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color:
                    _isShuffled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isShuffled = !_isShuffled;
                  widget.onShuffle(_isShuffled);
                });
              },
            ),
            IconButton(
              icon: Icon(
                _getRepeatIcon(),
                color:
                    _loopMode != LoopMode.off
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _loopMode = _getNextLoopMode();
                  widget.onRepeat(_loopMode);
                });
              },
            ),
            IconButton(
              icon: Icon(
                _showLyrics ? Icons.album : Icons.lyrics,
                color: Colors.white,
              ),
              onPressed: _toggleView,
            ),
            IconButton(
              icon: const Icon(Icons.playlist_play, color: Colors.white),
              onPressed: () {
                // TODO: Implement playlist view
              },
            ),
          ],
        ),
      ],
    );
  }

  IconData _getRepeatIcon() {
    switch (_loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat;
    }
  }

  LoopMode _getNextLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        return LoopMode.all;
      case LoopMode.all:
        return LoopMode.one;
      case LoopMode.one:
        return LoopMode.off;
    }
  }
}
