import 'dart:convert';
import 'package:flutter_music_app/music/play_music/audio_player_manager.dart';
import 'package:flutter_music_app/music/play_music/playing_music.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_app/model/song.dart';

class PlaylistUserLib extends StatefulWidget {
  final int playlistID;
  const PlaylistUserLib({super.key, required this.playlistID});
  @override
  State<PlaylistUserLib> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistUserLib> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showStickyHeader = false;
  List<Song>? _songs = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchSongs()
        .then((data) {
          debugPrint("Fetch successful");
          setState(() {
            _songs = data;
            debugPrint("Songs loaded successfully: ${data.length} songs");
          });
        })
        .catchError((e) {
          debugPrint("Error occurred while fetching songs");
        });
  }

  void _scrollListener() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _showStickyHeader = _scrollOffset > 300;
    });
  }

  void _playSong(Song song, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlayingMusicInterface(
              songs: _songs!,
              currentIndex: index,
            ),
      ),
    );
  }

  Future<List<Song>> fetchSongs() async {
    debugPrint("Starting API call...");
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5207/api/PlaylistUsers/playlists/${widget.playlistID}/songs',
        ),
        //Uri.parse('http://192.168.29.101:5207/api/Songs'),
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Body length: ${response.body.length}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("Parsed ${data.length} songs from API");

        final songs =
            data.map((json) {
              try {
                final song = Song.fromJson(json);
                debugPrint("Successfully parsed song: ${song.songName}");
                return song;
              } catch (e) {
                debugPrint("Error parsing song: $e");
                debugPrint("Problematic JSON: $json");
                rethrow;
              }
            }).toList();

        debugPrint("Total songs parsed: ${songs.length}");
        return songs;
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4C1D95), Color(0xFF1A1A2E), Color(0xFF0F0F23)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return _buildActionButtons();
                    }
                    return _buildTrackItem(_songs![index - 1], index-1);
                  }, childCount: _songs!.length + 1),
                ),
              ],
            ),
            _buildStickyHeader(),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double opacity = (1.0 - (_scrollOffset / 400)).clamp(0.0, 1.0);
    double scale = (1.0 - (_scrollOffset / 800)).clamp(0.8, 1.0);

    return AnimatedOpacity(
      opacity: opacity,
      duration: Duration(milliseconds: 100),
      child: Transform.scale(
        scale: scale,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              _buildPlaylistCover(),
              SizedBox(height: 30),
              _buildPlaylistInfo(),
              SizedBox(height: 30),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCover() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [Colors.white, Color(0xFFE0E7FF)],
              ).createShader(bounds),
          child: Text(
            "Danh sách phát thứ 1 của tôi",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                ),
              ),
              child: Center(
                child: Text(
                  "K",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Text(
              "khang",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "1 giờ 40 phút",
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(Icons.shuffle, 40),
        SizedBox(width: 20),
        _buildPlayButton(),
        SizedBox(width: 20),
        _buildControlButton(Icons.more_horiz, 40),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF1DB954),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1DB954).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.play_arrow, color: Colors.white, size: 30),
        onPressed: () {
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildControlButton(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size * 0.5),
        onPressed: () {
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildActionButton("+ Thêm", Icons.add),
          SizedBox(width: 15),
          _buildActionButton("Chỉnh sửa", Icons.edit),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Song song, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _playSong(song,index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(
                      image: NetworkImage(song.songImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        song.artistName ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      transform: Matrix4.translationValues(0, _showStickyHeader ? 0 : -100, 0),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E).withOpacity(0.95),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFF1A1A2E)],
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Danh sách phát thứ 1 của tôi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "khang",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildControlButton(Icons.shuffle, 36),
                SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFF1DB954),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SafeArea(
      child: Positioned(
        top: 20,
        left: 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
