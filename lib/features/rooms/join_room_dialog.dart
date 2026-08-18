import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/localization/app_locale.dart';
import '../../core/models/sound_mode.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/ringer_service.dart';
import 'qr_scanner_page.dart';

class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _pinController = TextEditingController();
  final _sectorNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _sectorNameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final pin = _pinController.text.trim();
    final sectorName = _sectorNameController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = context.tr(
          'Join code must be exactly 6 numeric digits.',
          'يجب أن يتكوّن رمز الانضمام من 6 أرقام بالضبط.',
        );
      });
      return;
    }

    if (sectorName.isEmpty || sectorName.length > 30) {
      setState(() {
        _errorMessage = context.tr(
          'Participant name must be between 1 and 30 characters.',
          'يجب أن يكون اسم المشارك بين حرف واحد و30 حرفًا.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(roomRepositoryProvider);
      final soundMode = ref.read(soundModeProvider);
      final notificationReadiness =
          await NotificationService().areNotificationsEnabled();
      final exactAlarmReadiness =
          await NotificationService().canScheduleExactNotifications();

      final res = await repo.joinRoom(
        code: pin,
        sectorName: sectorName,
        notificationReadiness: notificationReadiness,
        exactAlarmReadiness: exactAlarmReadiness,
        selectedSoundMode: soundMode,
      );

      await ref.read(activeRoomPinProvider.notifier).update(null);
      await ref.read(userSectorNameProvider.notifier).update(res['sectorName']);
      await ref.read(activeRoomIdProvider.notifier).update(res['roomId']);
      if (soundMode != SoundMode.vibrationOnly) {
        unawaited(RingerService().forceSoundMode());
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      });
    }
  }

  void _openQrScanner() async {
    final scannedPin = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );

    if (scannedPin != null && scannedPin.isNotEmpty) {
      _pinController.text = scannedPin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(context.tr('Join as Participant', 'الانضمام كمشارك')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('room-pin-field'),
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: context.tr(
                  '6-Digit Room PIN',
                  'رمز الغرفة المكوّن من 6 أرقام',
                ),
                hintText: '123456',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: context.tr('Scan QR Code', 'مسح رمز QR'),
                  onPressed: _openQrScanner,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('participant-name-field'),
              controller: _sectorNameController,
              decoration: InputDecoration(
                labelText: context.tr('Participant Name', 'اسم المشارك'),
                hintText:
                    context.tr('e.g. Participant Alpha', 'مثال: المشارك ألفا'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel', 'إلغاء')),
        ),
        FilledButton(
          key: const ValueKey('join-submit-button'),
          // The action is available while idle and disabled only during the
          // asynchronous join request. The previous condition inverted this
          // state, leaving Join greyed out until a request was already running.
          onPressed: _isLoading ? null : _joinRoom,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('Join', 'انضمام')),
        ),
      ],
    );
  }
}
