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
        builder: (context) => PlayingMusicInterface(
          song: song,
          audioPlayerManager: AudioPlayerManager(songUrl: song.source), // Dummy nếu chưa cần phát nhạc
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
            IconButton(icon: const Icon(Icons.add), onPressed: () {}),
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
       SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // 👈 thu 2 bên
            child: SafeArea(
              child: _isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                  )
                : _buildSongsList(),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSongsList() {
    return ListView.builder(
      shrinkWrap: true,
      key: const ValueKey('songs_list'),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _songs?.length,
      itemBuilder: (context, index) {
        final song = _songs![index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(Song song) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          song.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white),
            );
          },
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.grey),
      onTap: () => _playSong(song),
    );
  }
}
