import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/song.dart';
import '../../music/play_music/playing_music.dart';
import '../../music/play_music/audio_player_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int _selectedFilter = 0;
  // int _selectedIndex = 0;
  // final String _userName = "User";
  List<Song>? _songs = [];
  // Song? _currentlyPlayingSong;
  // AudioPlayerManager? _audioPlayerManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("LibraryTab: Initializing...");
    fetchSongs()
        .then((data) {
          debugPrint("LibraryTab: Fetch successful");
          setState(() {
            _songs = data;
            _isLoading = false;
            debugPrint(
              "LibraryTab: Songs loaded successfully: ${data.length} songs",
            );
            if (data.isNotEmpty) {
              debugPrint(
                "LibraryTab: First song: ${data[0].songName} by ${data[0].artistName}",
              );
            }
          });
        })
        .catchError((e) {
          debugPrint("LibraryTab: Error occurred while fetching songs");
          setState(() {
            _isLoading = false;
            debugPrint("LibraryTab: Error details: $e");
          });
        });
  }

  void _playSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlayingMusicInterface(
              song: song,
              audioPlayerManager: AudioPlayerManager(
                songUrl: song.linkSong,
              ), // Dummy nếu chưa cần phát nhạc
              onNext: () {},
              onPrevious: () {},
              onShuffle: (isShuffled) {},
              onRepeat: (loopMode) {},
            ),
      ),
    );
  }

  // Future<void> _loadSongs() async {
  //   final songs = await SongService.loadData();
  //   setState(() {
  //     _songs = songs;
  //     _isLoading = false;
  //   });
  // }

  Future<List<Song>> fetchSongs() async {
    debugPrint("LibraryTab: Starting API call...");
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5207/api/Songs'),
        //Uri.parse('http://192.168.29.101:5207/api/Songs'),
      );

      debugPrint("LibraryTab: API Response Status: ${response.statusCode}");
      debugPrint(
        "LibraryTab: API Response Body length: ${response.body.length}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("LibraryTab: Parsed ${data.length} songs from API");

        final songs =
            data.map((json) {
              try {
                final song = Song.fromJson(json);
                debugPrint(
                  "LibraryTab: Successfully parsed song: ${song.songName}",
                );
                return song;
              } catch (e) {
                debugPrint("LibraryTab: Error parsing song: $e");
                debugPrint("LibraryTab: Problematic JSON: $json");
                rethrow;
              }
            }).toList();

        debugPrint("LibraryTab: Total songs parsed: ${songs.length}");
        return songs;
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("LibraryTab: Error in fetchSongs: $e");
      throw Exception('Failed to load songs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "LibraryTab: Building widget, isLoading: $_isLoading, songs count: ${_songs?.length ?? 0}",
    );
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://picsum.photos/32/32'),
              ),
              SizedBox(width: 16),
              Text(
                'Your Library',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Danh sách phát',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Tạo danh sách phát gồm bài hát hoặc tập',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              // Xử lý khi chọn mục này
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.group,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Danh sách phát cộng tác',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Mời bạn bè cùng sáng tạo',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              // Xử lý khi chọn mục này
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.link,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Giai điệu chung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Kết hợp các gu nghe nhạc trong một danh sách phát chia...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              // Xử lý khi chọn mục này
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Playlists'),
                  selected: _selectedFilter == 0,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 0;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Artists'),
                  selected: _selectedFilter == 1,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 1;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Albums'),
                  selected: _selectedFilter == 2,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 2;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 2
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 700,
              child: Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = _songs![index];
              return ListTile(
                onTap: () {
                  _playSong(song);
                },
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(song.songImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  song.songName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  song.artistName,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }, childCount: _songs?.length ?? 0),
          ),
      ],
    );
  }
}
