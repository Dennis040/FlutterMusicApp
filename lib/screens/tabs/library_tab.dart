import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/song.dart';
import '../../music/service/song_service.dart';
import '../../music/play_music/playing_music.dart';
import '../../music/play_music/audio_player_manager.dart';

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
    _loadSongs();
  }

  void _playSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlayingMusicInterface(
              song: song,
              audioPlayerManager: AudioPlayerManager(
                songUrl: song.source,
              ), // Dummy nếu chưa cần phát nhạc
              onNext: () {},
              onPrevious: () {},
              onShuffle: (isShuffled) {},
              onRepeat: (loopMode) {},
            ),
      ),
    );
  }

  Future<void> _loadSongs() async {
    final songs = await SongService.loadData();
    setState(() {
      _songs = songs;
      // if (songs.isNotEmpty) {
      //   _currentlyPlayingSong = songs.first;
      //   _audioPlayerManager = AudioPlayerManager(songUrl: songs.first.source);
      //   _audioPlayerManager?.init();
      // }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        // SliverList(
        //   delegate: SliverChildBuilderDelegate((context, index) {
        //     return ListTile(
        //       leading: Container(
        //         width: 56,
        //         height: 56,
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.circular(4),
        //           image: DecorationImage(
        //             image: NetworkImage(
        //               'https://picsum.photos/56/56?random=$index',
        //             ),
        //             fit: BoxFit.cover,
        //           ),
        //         ),
        //       ),
        //       title: Text(
        //         'Playlist ${index + 1}',
        //         style: const TextStyle(
        //           color: AppColors.textPrimary,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //       subtitle: const Text(
        //         'Playlist • User Name',
        //         style: TextStyle(color: AppColors.textSecondary),
        //       ),
        //     );
        //   }, childCount: 20),
        // ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = _songs![index]; // danh sách bài hát của anh
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
                    image: NetworkImage(song.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                song.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                song.artist,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }, childCount: _songs?.length),
        ),
      ],
    );
  }
}
