import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_music_app/config/config.dart';

class ChatService {
  static Future<ChatResponse> sendMessage(String message, {int? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('${ip}chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message, 'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class ChatResponse {
  final String reply;
  final bool success;
  final String? error;
  final bool hasMusicContext;

  ChatResponse({
    required this.reply,
    required this.success,
    this.error,
    required this.hasMusicContext,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? '',
      success: json['success'] ?? false,
      error: json['error'],
      hasMusicContext: json['hasMusicContext'] ?? false,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasContext;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasContext = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'hasContext': hasContext,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      hasContext: json['hasContext'] ?? false,
    );
  }
}
