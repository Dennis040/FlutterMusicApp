class Lyrics {
  final List<LyricLine> lines;

  Lyrics({required this.lines});

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    final List<dynamic> linesJson = json['lines'] as List<dynamic>;
    return Lyrics(
      lines: linesJson.map((line) => LyricLine.fromJson(line)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      timestamp: Duration(milliseconds: json['timestamp'] as int),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.inMilliseconds,
      'text': text,
    };
  }
} 