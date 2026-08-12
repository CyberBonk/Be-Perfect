import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  static const String timerChannelId = 'be_perfect_active_timer_v2';
  static const String timerChannelName = 'Active event timer';
  static const String timerChannelDesc =
      'Ongoing silent event timer notification';

  // v3 resets old OEM channel choices that were saved as vibration-only.
  static const String announcementsChannelId = 'be_perfect_announcements_v3';
  static const String announcementsChannelName = 'Room announcements';
  static const String standardChannelId = 'be_perfect_standard_v1';
  static const String standardChannelName = 'Room updates';

  static Future<void> setupNotificationChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // 1. Silent Ongoing Timer Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        timerChannelId,
        timerChannelName,
        description: timerChannelDesc,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    // 2. Announcements Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        announcementsChannelId,
        announcementsChannelName,
        description: 'Text announcements from the room controller',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('be_perfect_round_alarm'),
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        standardChannelId,
        standardChannelName,
        description: 'Normal room updates and time adjustments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }
}
