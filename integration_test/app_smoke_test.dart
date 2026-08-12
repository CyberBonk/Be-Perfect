import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_perfect/core/firebase/firebase_providers.dart';
import 'package:be_perfect/core/models/phase_model.dart';
import 'package:be_perfect/core/models/run_model.dart';
import 'package:be_perfect/core/models/sound_mode.dart';
import 'package:be_perfect/core/notifications/notification_service.dart';
import 'package:be_perfect/core/timer/schedule_engine.dart';
import 'package:be_perfect/firebase_options.dart';
import 'package:be_perfect/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and supports primary navigation', (tester) async {
    // Physical-device integration runs reuse the installed app's data.
    // Clear the room session so this smoke test always starts at Home.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthStateProvider
              .overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: const BePerfectApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Timer Be Perfect'), findsWidgets);
    expect(find.text('Create Room'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('CyberBonk'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('minus-five alarm rings at the round boundary', (tester) async {
    await Alarm.init();
    final now = DateTime.now().millisecondsSinceEpoch;
    final roomId = 'integration-alarm-${now % 1000000}';
    final run = RoomRun(
      runId: 'integration-alarm-run',
      status: RunStatus.running,
      revision: 1,
      roundCount: 1,
      standardRoundDurationMs: 60000,
      cooldownMs: 0,
      startsAt: now - 60000,
      schedule: [
        Phase(
          phaseId: 'round-1',
          type: PhaseType.round,
          roundIndex: 1,
          startsAt: now - 60000,
          endsAt: now + 5000,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final service = NotificationService();
    await service.initialize();
    await service.scheduleBoundaryAlarms(
      roomId: roomId,
      run: run,
      soundMode: SoundMode.bePerfectSound,
      nowMs: now,
    );

    final alarmId = service.getRoundAlarmNotificationId(roomId, 1);
    final scheduled = await Alarm.getAlarms();
    expect(scheduled.any((alarm) => alarm.id == alarmId), isTrue);

    for (var secondsLeft = 5; secondsLeft >= 1; secondsLeft--) {
      final derived = ScheduleEngine.deriveState(
        run,
        run.schedule.single.endsAt - (secondsLeft * 1000),
      );
      expect(derived.formattedTime, '00:0$secondsLeft');
    }

    await Future<void>.delayed(const Duration(seconds: 6));
    expect(await Alarm.isRinging(alarmId), isTrue);
    await Alarm.stop(alarmId);
  });
}
