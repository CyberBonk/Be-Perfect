import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

/// Firebase-backed epoch clock for consistent timer calculations across devices.
class ServerClock {
  static final ServerClock _instance = ServerClock._internal();
  factory ServerClock() => _instance;
  ServerClock._internal();

  final DatabaseReference _offsetRef =
      FirebaseDatabase.instance.ref('.info/serverTimeOffset');
  StreamSubscription<DatabaseEvent>? _subscription;
  int _offsetMs = 0;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _subscription = _offsetRef.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is num) _offsetMs = value.toInt();
    });
  }

  int nowMs() {
    start();
    return DateTime.now().millisecondsSinceEpoch + _offsetMs;
  }

  Future<int> syncedNowMs() async {
    start();
    try {
      final snapshot =
          await _offsetRef.get().timeout(const Duration(seconds: 2));
      final value = snapshot.value;
      if (value is num) _offsetMs = value.toInt();
    } catch (_) {
      // Offline fallback uses the last known offset, initially zero.
    }
    return nowMs();
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
