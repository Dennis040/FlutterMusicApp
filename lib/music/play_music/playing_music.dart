import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_app/config/config.dart';
import 'package:flutter_music_app/main.dart';
import 'package:flutter_music_app/music/handle/audio_handler.dart';
import 'package:flutter_music_app/music/service/admanager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/song.dart';
import '../../model/lyrics.dart';
import 'package:http/http.dart' as http;
// import '../service/lyrics_service.dart';
import 'dart:async';

class PlayingMusicInterface extends StatefulWidget {
  const PlayingMusicInterface({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  final List<Song> songs;
  final int currentIndex;
  // final VoidCallback onNext;
  // final VoidCallback onPrevious;
  // final ValueChanged<bool> onShuffle;
  // final ValueChanged<LoopMode> onRepeat;

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
  late Animation<double> pageAnimation;
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.black;
  double volume = 1.0;
  final ScrollController _lyricsScrollController = ScrollController();
  late List<Song> songs;
  late List<Song> shuffledList;
  late int currentIndex;
  late Song currentSong;
  // late AudioPlayerManager audioPlayerManager;
  bool _isNexting = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  bool isPremium = false;
  // int _songPlayCount = 0;
  // bool _isShowingAd = false;
  // Timer? _adTimer;
  final adManager = AdManager()..loadAd();

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

    pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    songs = widget.songs;
    currentIndex = widget.currentIndex;
    currentSong = songs[currentIndex];
    // audioPlayerManager = AudioPlayerManager(songUrl: currentSong.linkSong!);
    _initPlayer();
    _generateColors();
    // final mediaItem = MediaItem(
    //   id: currentSong.linkSong!, // hoặc link bài nhạc
    //   title: currentSong.songName,
    //   artist: currentSong.artistName,
    //   artUri: Uri.parse(currentSong.songImage),
    // );
    // globalAudioHandler.addQueueItem(mediaItem);
    _setupNotificationCallbacks();
    fetchUserProfile();
    _checkAndShowAd();
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // Dựa theo cách bạn tạo token bằng ClaimTypes.NameIdentifier:
    // => nó sẽ lưu trong key "nameid"
    final userId = decodedToken['nameid']; // hoặc 'sub' nếu bạn đổi claim

    return int.tryParse(userId.toString());
  }

  Future<void> fetchUserProfile() async {
    final userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');

    final response = await http.get(Uri.parse('${ip}Users/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String role = data['role'];

      debugPrint('Role: $role');

      // Gán vào biến state nếu muốn hiển thị ra giao diện
      if (mounted) {
        setState(() {
          isPremium = (role == 'premium');
          debugPrint('isPremium: $isPremium');
        });
      }
    } else {
      debugPrint('Error fetching profile: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _pageAnimationController.dispose();
    _imageAnimationController.dispose();
    _playerStateSub?.cancel();
    _mediaItemSub?.cancel();
    // _adTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationCallbacks() {
    // Setup callbacks for notification controls
    (globalAudioHandler as MyAudioHandler).setCallbacks(
      onNext: _playNextSong,
      onPrevious: _playPreviousSong,
      onShuffle: _toggleShuffle,
      onRepeat: _toggleRepeat,
    );
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

  // Hàm kiểm tra và hiển thị quảng cáo
  Future<void> _checkAndShowAd() async {
    if (isPremium == false) {
      await adManager.showAdIfNeeded(() async {
        debugPrint("📢 QUẢNG CÁO XONG → PHÁT NHẠC");
        (globalAudioHandler as MyAudioHandler).player.play();
      });
    } else {
       debugPrint("⭐ PREMIUM → PHÁT LUÔN");
      (globalAudioHandler as MyAudioHandler).player.play();
    }
  }

  // void _showInterstitialAd() {
  //   setState(() {
  //     _isShowingAd = true;
  //   });

  //   // Tạm dừng nhạc khi hiển thị quảng cáo
  //   (globalAudioHandler as MyAudioHandler).player.pause();

  //   // Tự động đóng quảng cáo sau 5 giây (hoặc có thể để user tự đóng)
  //   _adTimer = Timer(const Duration(seconds: 5), () {
  //     _hideAd();
  //   });
  // }

  // void _hideAd() {
  //   setState(() {
  //     _isShowingAd = false;
  //   });
  //   _adTimer?.cancel();

  //   // Tiếp tục phát nhạc sau khi đóng quảng cáo
  //   (globalAudioHandler as MyAudioHandler).player.play();
  // }

  Future<void> _initPlayer() async {
    // await audioPlayerManager.init(); // Đợi nhạc load xong
    // audioPlayerManager.player.play(); // Bắt đầu phát nhạc
    await _loadLyrics();
    await _generateColors();
    // Create media item
    final mediaItem = MediaItem(
      id: currentSong.linkSong!,
      title: currentSong.songName,
      artist: currentSong.artistName,
      artUri: Uri.parse(currentSong.songImage),
      duration: null, // Will be updated when loaded
    );
    // Add to queue and play
    await globalAudioHandler.addQueueItem(mediaItem);
    (globalAudioHandler as MyAudioHandler).player.positionStream.listen(
      _updateCurrentLyric,
    );
    _playerStateSub?.cancel(); // hủy lắng nghe cũ

    _playerStateSub = (globalAudioHandler as MyAudioHandler)
        .player
        .playerStateStream
        .listen((state) {
          if (state.processingState == ProcessingState.completed &&
              !_isNexting) {
            _isNexting = true;
            _playNextSong().then((_) => _isNexting = false);
          }
        });

    // Listen to media item changes (for notification updates)
    _mediaItemSub?.cancel();
    _mediaItemSub = globalAudioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        // Update current song if changed from notification
        final newSong = songs.firstWhere(
          (song) => song.linkSong == mediaItem.id,
          orElse: () => currentSong,
        );
        if (newSong != currentSong) {
          setState(() {
            currentSong = newSong;
            currentIndex = songs.indexOf(newSong);
          });
          _loadLyrics();
          _generateColors();
        }
      }
    });
  }

  Future<void> _playNextSong() async {
    if (currentIndex < songs.length - 1) {
      setState(() {
        currentIndex++;
        currentSong =
            _isShuffled ? shuffledList[currentIndex] : songs[currentIndex];
      });
      await _playSong(currentSong);
      // _checkAndShowAd();
    } else if (_loopMode == LoopMode.all) {
      setState(() {
        currentIndex = 0;
        currentSong =
            _isShuffled ? shuffledList[currentIndex] : songs[currentIndex];
      });
      await _playSong(currentSong);
      // _checkAndShowAd();
    }
  }

  Future<void> _playPreviousSong() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        currentSong =
            _isShuffled ? shuffledList[currentIndex] : songs[currentIndex];
      });
      await _playSong(currentSong);
      // _checkAndShowAd();
    } else {
      // Seek to beginning
      await (globalAudioHandler as MyAudioHandler).player.seek(Duration.zero);
    }
  }

  Future<void> _playSong(Song song) async {
    final mediaItem = MediaItem(
      id: song.linkSong!,
      title: song.songName,
      artist: song.artistName,
      artUri: Uri.parse(song.songImage),
    );

    await globalAudioHandler.addQueueItem(mediaItem);
    await _loadLyrics();
    await _generateColors();
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        shuffledList = List.from(songs);
        shuffledList.shuffle();
        currentIndex = shuffledList.indexOf(currentSong);
      } else {
        currentIndex = songs.indexOf(currentSong);
      }
    });

    // Update handler state
    (globalAudioHandler as MyAudioHandler).updateShuffleState(_isShuffled);
  }

  void _toggleRepeat() {
    setState(() {
      _loopMode = _getNextLoopMode();
    });

    // Update handler state
    (globalAudioHandler as MyAudioHandler).updateRepeatState(_loopMode);
  }

  Future<void> _loadLyrics() async {
    try {
      debugPrint("Loading lyrics for song: ${currentSong.songName}");
      debugPrint("LRC URL: ${currentSong.linkLrc}");

      if (currentSong.linkLrc == null || currentSong.linkLrc == "null") {
        debugPrint("No LRC URL provided for this song");
        setState(() {
          _lyrics = Lyrics(
            lines: [],
            error: "No lyrics available for this song",
          );
        });
        return;
      }

      final lyrics = await Lyrics.fromUrl(currentSong.linkLrc);

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
      final imageProvider = NetworkImage(currentSong.songImage);
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
    // debugPrint("current position: $position");
    if (_lyrics == null || _lyrics!.lines.isEmpty) return;

    for (int i = 0; i < _lyrics!.lines.length; i++) {
      if (i == _lyrics!.lines.length - 1 ||
          (position >= _lyrics!.lines[i].timestamp &&
              position < _lyrics!.lines[i + 1].timestamp)) {
        if (_currentLyricIndex != i) {
          if (!mounted) return;
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
    final viewportHeight =
        screenHeight * 0.6; // Chiều cao vùng hiển thị lời bài hát

    // Tính toán vị trí cần cuộn đến
    final targetPosition =
        _currentLyricIndex * itemHeight - (viewportHeight / 2) + itemHeight;

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

  // Widget _buildAdOverlay() {
  //   return Container(
  //     color: Colors.black.withOpacity(0.9),
  //     child: Center(
  //       child: Container(
  //         margin: const EdgeInsets.all(20),
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Icon(Icons.ads_click, size: 64, color: Colors.blue),
  //             const SizedBox(height: 16),
  //             const Text(
  //               'Quảng cáo',
  //               style: TextStyle(
  //                 fontSize: 24,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             const Text(
  //               'Nâng cấp lên Premium để loại bỏ quảng cáo!',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(fontSize: 16, color: Colors.grey),
  //             ),
  //             const SizedBox(height: 20),
  //             // Có thể thêm banner quảng cáo thật ở đây
  //             Container(
  //               height: 100,
  //               width: double.infinity,
  //               decoration: BoxDecoration(
  //                 gradient: const LinearGradient(
  //                   colors: [Colors.blue, Colors.purple],
  //                 ),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Center(
  //                 child: Text(
  //                   'Quảng cáo của bạn ở đây',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 ElevatedButton(onPressed: _hideAd, child: const Text('Đóng')),
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     // TODO: Implement upgrade to premium
  //                     _hideAd();
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.blue,
  //                     foregroundColor: Colors.white,
  //                   ),
  //                   child: const Text('Nâng cấp Premium'),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
            currentSong.songName,
            style: const TextStyle(
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
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _showLyrics ? _buildLyricsView() : _buildAlbumArtView(),
                ),
                _buildSongInfo(),
                _buildPlaybackControls(),
                const SizedBox(height: 16),
                _buildAdditionalControls(),
                const SizedBox(height: 32),
              ],
            ),
            // Overlay quảng cáo
            // if (_isShowingAd) _buildAdOverlay(),
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
          tag: 'album_art_${currentSong.songId}',
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
                  currentSong.songImage,
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
                  currentSong.songName,
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
                  currentSong.artistName!,
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
        padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 0),
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
                fontSize:
                    isCurrentLine
                        ? 20
                        : (isNextLine || isPreviousLine ? 18 : 16),
                color:
                    isCurrentLine
                        ? Colors.white
                        : (isNextLine || isPreviousLine
                            ? Colors.white70
                            : Colors.grey),
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
          stream: (globalAudioHandler as MyAudioHandler).player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration =
                (globalAudioHandler as MyAudioHandler).player.duration ??
                Duration.zero;
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
                      (globalAudioHandler as MyAudioHandler).player.seek(
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
              onPressed: () async {
                if (currentIndex > 0) {
                  setState(() {
                    currentIndex--;
                    if (_isShuffled) {
                      currentSong = shuffledList[currentIndex];
                    } else {
                      currentSong = songs[currentIndex];
                    }
                  });
                  await _loadLyrics();
                  // await audioPlayerManager.playNewSong(currentSong.linkSong!);
                  final mediaItem = MediaItem(
                    id: currentSong.linkSong!, // hoặc link bài nhạc
                    title: currentSong.songName,
                    artist: currentSong.artistName,
                    artUri: Uri.parse(currentSong.songImage),
                  );
                  globalAudioHandler.addQueueItem(mediaItem);
                  // await showMusicNotification(currentSong, audioPlayerManager);
                  // _checkAndShowAd();
                } else {
                  // ✅ Nếu đang ở bài đầu → phát lại bài hiện tại
                  (globalAudioHandler as MyAudioHandler).player.seek(
                    Duration.zero,
                  );
                  (globalAudioHandler as MyAudioHandler).player.play();
                }
              },
            ),
            StreamBuilder<PlayerState>(
              stream:
                  (globalAudioHandler as MyAudioHandler)
                      .player
                      .playerStateStream,
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
                      (globalAudioHandler as MyAudioHandler).player.play();
                      // MusicPlayerManager.resumeMusic();
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white),
                    iconSize: 64,
                    onPressed: () {
                      (globalAudioHandler as MyAudioHandler).player.pause();
                      // MusicPlayerManager.pauseMusic();
                    },
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              iconSize: 36,
              onPressed: () async {
                if (currentIndex < songs.length - 1) {
                  setState(() {
                    currentIndex++;
                    if (_isShuffled) {
                      currentSong = shuffledList[currentIndex];
                    } else {
                      currentSong = songs[currentIndex];
                    }
                  });
                  await _loadLyrics();
                  final mediaItem = MediaItem(
                    id: currentSong.linkSong!, // hoặc link bài nhạc
                    title: currentSong.songName,
                    artist: currentSong.artistName,
                    artUri: Uri.parse(currentSong.songImage),
                  );
                  globalAudioHandler.addQueueItem(mediaItem);
                  // _checkAndShowAd();
                  // await showMusicNotification(currentSong, audioPlayerManager);
                } else {
                  // ✅ Nếu đang ở bài đầu → phát lại bài hiện tại
                  (globalAudioHandler as MyAudioHandler).player.seek(
                    Duration.zero,
                  );
                  (globalAudioHandler as MyAudioHandler).player.play();
                }
              },
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
                color: _isShuffled ? Colors.green : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isShuffled = !_isShuffled;
                  if (_isShuffled) {
                    shuffledList = List.from(songs);
                    shuffledList.shuffle();
                    currentIndex = shuffledList.indexOf(currentSong);
                  } else {
                    currentIndex = songs.indexOf(currentSong);
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(
                _getRepeatIcon(),
                color: _loopMode == LoopMode.one ? Colors.green : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _loopMode = _getNextLoopMode();
                  (globalAudioHandler as MyAudioHandler).player.setLoopMode(
                    _loopMode,
                  );
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
    return _loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat;
  }

  LoopMode _getNextLoopMode() {
    return _loopMode == LoopMode.off ? LoopMode.one : LoopMode.off;
  }
}
