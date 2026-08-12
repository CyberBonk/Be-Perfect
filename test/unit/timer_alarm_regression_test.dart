import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/core/models/phase_model.dart';
import 'package:be_perfect/core/models/run_model.dart';
import 'package:be_perfect/core/notifications/notification_service.dart';
import 'package:be_perfect/core/timer/schedule_engine.dart';

void main() {
  test('minus-five boundary counts down 5 to 1 and keeps the alarm boundary',
      () {
    const now = 1000000;
    const roundEnd = now + 5000;
    const run = RoomRun(
      runId: 'minus-five-run',
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
          endsAt: roundEnd,
        ),
      ],
      createdAt: now - 60000,
      updatedAt: now,
    );

    final service = NotificationService();
    final plan = service.buildBoundaryAlarmPlan(
      roomId: 'minus-five-room',
      run: run,
      nowMs: now,
    );

    expect(plan, hasLength(1));
    expect(plan.single.roundIndex, 1);
    expect(plan.single.phase.endsAt, roundEnd);

    for (var secondsLeft = 5; secondsLeft >= 1; secondsLeft--) {
      final derived = ScheduleEngine.deriveState(
        run,
        roundEnd - (secondsLeft * 1000),
      );
      expect(derived.state, DerivedPhaseState.runningRound);
      expect(derived.remainingMs, secondsLeft * 1000);
      expect(derived.formattedTime, '00:0$secondsLeft');
    }

    final atBoundary = ScheduleEngine.deriveState(run, roundEnd);
    expect(atBoundary.state, DerivedPhaseState.completed);
    expect(atBoundary.formattedTime, '00:00');
  });

  test('completed runs do not create a new boundary alarm plan', () {
    const run = RoomRun(
      runId: 'completed-run',
      status: RunStatus.completed,
      revision: 1,
      roundCount: 1,
      standardRoundDurationMs: 60000,
      cooldownMs: 0,
      startsAt: 0,
      schedule: [
        Phase(
          phaseId: 'round-1',
          type: PhaseType.round,
          roundIndex: 1,
          startsAt: 0,
          endsAt: 60000,
        ),
      ],
      createdAt: 0,
      updatedAt: 0,
    );

    expect(
      NotificationService().buildBoundaryAlarmPlan(
        roomId: 'completed-room',
        run: run,
        nowMs: 0,
      ),
      isEmpty,
    );
  });
}
