import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/lyrics.dart';

class LyricsService {
  static Future<Lyrics?> fetchLyrics(String? lyricsUrl) async {
    if (lyricsUrl == null) return null;
    
    try {
      final response = await http.get(Uri.parse(lyricsUrl));
      if (response.statusCode == 200) {
        return Lyrics.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching lyrics: $e');
    }
    return null;
  }

  // Mock lyrics for testing
  static Lyrics getMockLyrics() {
    return Lyrics(
      lines: [
        LyricLine(timestamp: Duration(seconds: 0), text: "Verse 1"),
        LyricLine(timestamp: Duration(seconds: 5), text: "This is a test lyric line"),
        LyricLine(timestamp: Duration(seconds: 10), text: "Another test lyric line"),
        LyricLine(timestamp: Duration(seconds: 15), text: "Chorus"),
        LyricLine(timestamp: Duration(seconds: 20), text: "This is the chorus"),
        LyricLine(timestamp: Duration(seconds: 25), text: "End of chorus"),
      ],
    );
  }
} 