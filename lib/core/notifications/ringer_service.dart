import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:real_volume/real_volume.dart';

class RingerService {
  static final RingerService _instance = RingerService._internal();
  factory RingerService() => _instance;
  RingerService._internal();

  static const _streams = [
    StreamType.ALARM,
    StreamType.NOTIFICATION,
    StreamType.MUSIC,
    StreamType.RING,
  ];

  RingerMode? _savedRingerMode;
  final Map<StreamType, double> _savedVolumes = {};

  Future<bool> isSoundModeEnabled() async {
    try {
      final mode = await RealVolume.getRingerMode();
      return mode == RingerMode.NORMAL;
    } catch (_) {
      return true;
    }
  }

  /// Returns true only if both the ringer mode is NORMAL and notification/alarm volumes are audible (> 15%).
  Future<bool> isSoundModeAudible() async {
    try {
      final mode = await RealVolume.getRingerMode();
      if (mode != null && mode != RingerMode.NORMAL) {
        return false;
      }
      final notifVol =
          await RealVolume.getCurrentVol(StreamType.NOTIFICATION) ?? 1.0;
      final alarmVol =
          await RealVolume.getCurrentVol(StreamType.ALARM) ?? 1.0;
      if (notifVol < 0.15 && alarmVol < 0.15) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> isDndAccessGranted() async {
    try {
      return await RealVolume.isPermissionGranted() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openDndSettings() async {
    if (!Platform.isAndroid) return;
    try {
      const intent = AndroidIntent(
        action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
      );
      await intent.launch();
    } catch (_) {
      try {
        await RealVolume.openDoNotDisturbSettings();
      } catch (_) {}
    }
  }

  Future<void> forceSoundMode() async {
    try {
      if (_savedRingerMode == null) {
        _savedRingerMode = await RealVolume.getRingerMode();
        _savedVolumes.clear();
        for (final stream in _streams) {
          try {
            _savedVolumes[stream] =
                await RealVolume.getCurrentVol(stream) ?? 0.0;
          } catch (_) {}
        }
      }

      // 1. Boost volumes first before altering ringer mode to prevent EMUI auto-vibrate downgrade
      for (final stream in _streams) {
        try {
          await RealVolume.setVolume(1.0, streamType: stream);
        } catch (_) {}
      }

      // 2. Switch ringer mode only if not already NORMAL
      final currentMode = await RealVolume.getRingerMode();
      if (currentMode != RingerMode.NORMAL) {
        try {
          await RealVolume.setRingerMode(
            RingerMode.NORMAL,
            redirectIfNeeded: false,
          );
        } catch (_) {}
      }

      // 3. Re-enforce maximum stream volume after mode switch
      for (final stream in _streams) {
        try {
          await RealVolume.setVolume(1.0, streamType: stream);
        } catch (_) {}
      }
    } catch (_) {
      // Best effort; Android may restrict ringer/DND changes.
    }
  }

  Future<void> restoreVolumes() async {
    final savedMode = _savedRingerMode;
    if (savedMode == null) return;

    try {
      for (final stream in _streams) {
        final volume = _savedVolumes[stream];
        if (volume != null) {
          try {
            await RealVolume.setVolume(volume, streamType: stream);
          } catch (_) {}
        }
      }
      try {
        await RealVolume.setRingerMode(savedMode, redirectIfNeeded: false);
      } catch (_) {}
    } catch (_) {
      // Best effort restore on restricted devices.
    } finally {
      _savedRingerMode = null;
      _savedVolumes.clear();
    }
  }
}
