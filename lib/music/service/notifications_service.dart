import 'dart:typed_data';
import 'package:flutter_music_app/music/play_music/audio_player_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_music_app/model/song.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late AudioPlayerManager audioPlayerManager;

// Future<void> showMusicNotification(String title, String body) async {
//   const AndroidNotificationDetails androidDetails =
//       AndroidNotificationDetails(
//     'music_channel_id',
//     'Music Playback',
//     channelDescription: 'Thông báo khi phát nhạc',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     showWhen: false,
//   );

//   const NotificationDetails notificationDetails =
//       NotificationDetails(android: androidDetails);

//   await flutterLocalNotificationsPlugin.show(
//     0, // ID thông báo
//     title,
//     body,
//     notificationDetails,
//   );
// }
Future<void> showMusicNotification(Song song) async {
  final ByteArrayAndroidBitmap largeIcon = ByteArrayAndroidBitmap(
    await _getByteArrayFromUrl(song.songImage),
  );

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'music_channel_id',
    'Music Playback',
    channelDescription: 'Thông báo khi phát nhạc',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
    largeIcon: largeIcon,
    styleInformation: MediaStyleInformation(
      htmlFormatContent: true,
      htmlFormatTitle: true,
    ),
    actions: const [
      AndroidNotificationAction('previous', 'Prev'),
      AndroidNotificationAction('pause', 'Pause'),
      AndroidNotificationAction('next', 'Next'),
    ],
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    song.songName,
    song.artistName,
    notificationDetails,
  );
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Không tải được ảnh: $url');
  }
}
void initializeNotifications(List<Song> songList, int currentSongIndex) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      switch (response.actionId) {
        case 'pause':
          if (audioPlayerManager.player.playing) {
            await audioPlayerManager.player.pause();
          } else {
            await audioPlayerManager.player.play();
          }
          break;
        case 'next':
          _playNext(songList, currentSongIndex);
          break;
        case 'previous':
          _playPrevious(songList, currentSongIndex);
          break;
      }

      // Cập nhật lại thông báo sau khi thực hiện
      await showMusicNotification(songList[currentSongIndex]);
    },
  );
}

void _playNext(List<Song> songList, int currentSongIndex) {
  if (currentSongIndex < songList.length - 1) {
    currentSongIndex++;
  }
  audioPlayerManager.playNewSong(songList[currentSongIndex].linkSong!);
}

void _playPrevious(List<Song> songList, int currentSongIndex) {
  if (currentSongIndex > 0) {
    currentSongIndex--;
  }
  audioPlayerManager.playNewSong(songList[currentSongIndex].linkSong!);
}