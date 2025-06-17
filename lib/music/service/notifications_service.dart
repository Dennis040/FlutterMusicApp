import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showMusicNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'music_channel_id',
    'Music Playback',
    channelDescription: 'Thông báo khi phát nhạc',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    showWhen: false,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // ID thông báo
    title,
    body,
    notificationDetails,
  );
}
