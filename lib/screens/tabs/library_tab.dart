import 'package:flutter/material.dart';
import 'package:flutter_music_app/library/artist_user_lib.dart';
import 'package:flutter_music_app/library/playlist_user_lib.dart';
import 'package:flutter_music_app/model/artist.dart';
import 'package:flutter_music_app/model/playlist_user.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
// import '../../model/song.dart';
// import '../../music/play_music/playing_music.dart';
// import '../../music/play_music/audio_player_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../user/create_playlist_screen.dart';
import '../../config/config.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int _selectedFilter = 0;
  // int _selectedIndex = 0;
  // final String _userName = "User";
  List<Object> _items = []; // chứa cả Playlist và Artist
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("LibraryTab: Initializing...");
    fetchUserLibrary();
  }

  // void _playSong(Song song) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => PlayingMusicInterface(
  //             song: song,
  //             audioPlayerManager: AudioPlayerManager(songUrl: song.linkSong),
  //             onNext: () {},
  //             onPrevious: () {},
  //             onShuffle: (isShuffled) {},
  //             onRepeat: (loopMode) {},
  //           ),
  //     ),
  //   );
  // }

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

  Future<void> fetchUserLibrary() async {
    final userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');
    final response = await http.get(Uri.parse('${ip}Users/$userId/lib'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final playlists =
          (data['playlists'] as List)
              .map((e) => PlaylistUser.fromJson(e))
              .toList();
      final artists =
          (data['favoriteArtists'] as List)
              .map((e) => Artist.fromJson(e))
              .toList();

      debugPrint('Playlists count: ${playlists.length}');
      debugPrint('Artists count: ${artists.length}');
      setState(() {
        _items = [...playlists, ...artists];
        _isLoading = false;
      });
    } else {
      // Handle error
    }
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
                              // Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatePlaylistScreen(),
                                ),
                              );
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
                  selectedColor: AppColors.primaryColor.withOpacity(0.15),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  side: BorderSide(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryColor
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
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
                  selectedColor: AppColors.primaryColor.withOpacity(0.15),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  side: BorderSide(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryColor
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
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
              final item = _items[index];

              Widget tile;
              if (item is PlaylistUser && _selectedFilter == 0) {
                tile = ListTile(
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.queue_music,
                      size: 28,
                      color: Colors.black54,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    // đi đến chi tiết playlist
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PlaylistUserLib(playlistID: item.id),
                      ),
                    );
                  },
                );
              } else if (item is Artist && _selectedFilter == 1) {
                tile = ListTile(
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(item.artistImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    item.artistName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    // đi đến chi tiết nghệ sĩ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ArtistUserLib(artistID: item.artistId),
                      ),
                    );
                  },
                );
              } else {
                tile = const SizedBox.shrink(); // fallback an toàn
              }

              // Trả về widget có padding
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                child: tile,
              );
            }, childCount: _items.length),
          ),
      ],
    );
  }
}
