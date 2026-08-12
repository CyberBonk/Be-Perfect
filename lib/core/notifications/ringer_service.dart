import 'package:real_volume/real_volume.dart';

class RingerService {
  static final RingerService _instance = RingerService._internal();
  factory RingerService() => _instance;
  RingerService._internal();

  static const _streams = [
    StreamType.ALARM,
    StreamType.RING,
    StreamType.NOTIFICATION,
    StreamType.MUSIC,
  ];

  RingerMode? _savedRingerMode;
  final Map<StreamType, double> _savedVolumes = {};

  Future<bool> isSoundModeEnabled() async {
    try {
      return await RealVolume.getRingerMode() == RingerMode.NORMAL;
    } catch (_) {
      return true;
    }
  }

  Future<void> forceSoundMode() async {
    try {
      if (_savedRingerMode == null) {
        _savedRingerMode = await RealVolume.getRingerMode();
        _savedVolumes.clear();
        for (final stream in _streams) {
          _savedVolumes[stream] = await RealVolume.getCurrentVol(stream) ?? 0.0;
        }
      }

      await RealVolume.setRingerMode(
        RingerMode.NORMAL,
        redirectIfNeeded: false,
      );
      for (final stream in _streams) {
        await RealVolume.setVolume(1.0, streamType: stream);
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
          await RealVolume.setVolume(volume, streamType: stream);
        }
      }
      await RealVolume.setRingerMode(savedMode, redirectIfNeeded: false);
    } catch (_) {
      // Best effort restore on restricted devices.
    } finally {
      _savedRingerMode = null;
      _savedVolumes.clear();
    }
  }
}
