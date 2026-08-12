enum SoundMode {
  bePerfectSound('Be Perfect sound', 'Bundled sound plus vibration'),
  deviceDefault(
      'Device default', 'Default notification/alarm sound plus vibration'),
  vibrationOnly('Vibration only', 'Vibration without audio');

  final String label;
  final String description;

  const SoundMode(this.label, this.description);

  static SoundMode fromString(String? value) {
    switch (value) {
      case 'device_default':
      case 'be_perfect_round_system_v3':
      case 'be_perfect_round_system_v1':
        return SoundMode.deviceDefault;
      case 'vibration_only':
      case 'be_perfect_round_vibration_v3':
      case 'be_perfect_round_vibration_v1':
        return SoundMode.vibrationOnly;
      case 'be_perfect_sound':
      case 'be_perfect_round_custom_v3':
      case 'be_perfect_round_custom_v1':
      default:
        return SoundMode.bePerfectSound;
    }
  }

  String toStorageString() {
    switch (this) {
      case SoundMode.deviceDefault:
        return 'device_default';
      case SoundMode.vibrationOnly:
        return 'vibration_only';
      case SoundMode.bePerfectSound:
        return 'be_perfect_sound';
    }
  }
}
