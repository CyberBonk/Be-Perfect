import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/core/models/phase_model.dart';
import 'package:be_perfect/core/models/run_model.dart';
import 'package:be_perfect/core/timer/schedule_engine.dart';

void main() {
  group('ScheduleEngine Unit Tests', () {
    const int baseTime = 1000000;
    const int leadTime = 5000;
    const int roundDurationMs = 20 * 60 * 1000; // 20 mins
    const int cooldownMs = 10 * 1000; // 10 secs

    const Phase round1 = Phase(
      phaseId: 'p1_r1',
      type: PhaseType.round,
      roundIndex: 1,
      startsAt: baseTime + leadTime,
      endsAt: baseTime + leadTime + roundDurationMs,
    );

    const Phase cooldown1 = Phase(
      phaseId: 'p2_c1',
      type: PhaseType.cooldown,
      roundIndex: 1,
      startsAt: baseTime + leadTime + roundDurationMs,
      endsAt: baseTime + leadTime + roundDurationMs + cooldownMs,
    );

    const Phase round2 = Phase(
      phaseId: 'p3_r2',
      type: PhaseType.round,
      roundIndex: 2,
      startsAt: baseTime + leadTime + roundDurationMs + cooldownMs,
      endsAt: baseTime + leadTime + (2 * roundDurationMs) + cooldownMs,
    );

    final testRun = RoomRun(
      runId: 'test_run_1',
      status: RunStatus.running,
      revision: 1,
      roundCount: 2,
      standardRoundDurationMs: roundDurationMs,
      cooldownMs: cooldownMs,
      startsAt: baseTime + leadTime,
      schedule: const [round1, cooldown1, round2],
      createdAt: baseTime,
      updatedAt: baseTime,
    );

    test('Starting lead time and 3-2-1 countdown', () {
      final stateBeforeStart =
          ScheduleEngine.deriveState(testRun, baseTime + 2000);
      expect(stateBeforeStart.state, DerivedPhaseState.starting);
      expect(stateBeforeStart.isStartingCountdown, isTrue);
      expect(stateBeforeStart.startingCountdownSeconds, 3);

      final state2sBefore =
          ScheduleEngine.deriveState(testRun, baseTime + 3000);
      expect(state2sBefore.startingCountdownSeconds, 2);
    });

    test('Derives active Round 1 phase during round execution', () {
      final now = baseTime + leadTime + 60000; // 1 minute into round 1
      final state = ScheduleEngine.deriveState(testRun, now);

      expect(state.state, DerivedPhaseState.runningRound);
      expect(state.currentRoundIndex, 1);
      expect(state.activePhase?.phaseId, 'p1_r1');
      expect(state.formattedTime, '19:00');
    });

    test('Derives Cooldown phase automatically at round boundary', () {
      final now =
          baseTime + leadTime + roundDurationMs + 2000; // 2s into cooldown 1
      final state = ScheduleEngine.deriveState(testRun, now);

      expect(state.state, DerivedPhaseState.cooldown);
      expect(state.currentRoundIndex, 1);
      expect(state.activePhase?.phaseId, 'p2_c1');
      expect(state.formattedTime, '00:08');
    });

    test('Derives Round 2 phase after cooldown', () {
      final now = baseTime + leadTime + roundDurationMs + cooldownMs + 5000;
      final state = ScheduleEngine.deriveState(testRun, now);

      expect(state.state, DerivedPhaseState.runningRound);
      expect(state.currentRoundIndex, 2);
      expect(state.activePhase?.phaseId, 'p3_r2');
    });

    test('Derives Completed state after final round boundary', () {
      final now =
          baseTime + leadTime + (2 * roundDurationMs) + cooldownMs + 1000;
      final state = ScheduleEngine.deriveState(testRun, now);

      expect(state.state, DerivedPhaseState.completed);
      expect(state.remainingMs, 0);
      expect(state.formattedTime, '00:00');
    });

    test('Paused state freezes remaining time regardless of clock progression',
        () {
      final pausedRun = RoomRun(
        runId: 'test_run_paused',
        status: RunStatus.paused,
        revision: 2,
        roundCount: 2,
        standardRoundDurationMs: roundDurationMs,
        cooldownMs: cooldownMs,
        startsAt: baseTime + leadTime,
        schedule: const [round1, cooldown1, round2],
        pausedState: const PausedState(
          pausedAt: baseTime + leadTime + 60000,
          pausedPhaseId: 'p1_r1',
          remainingMs: 300000, // 5 mins left
        ),
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final state10MinutesLater =
          ScheduleEngine.deriveState(pausedRun, baseTime + 1000000);
      expect(state10MinutesLater.state, DerivedPhaseState.paused);
      expect(state10MinutesLater.remainingMs, 300000);
      expect(state10MinutesLater.formattedTime, '05:00');
    });

    test('Ended status takes precedence over schedule phase timestamps', () {
      final endedRun = RoomRun(
        runId: 'test_run_ended',
        status: RunStatus.ended,
        revision: 3,
        roundCount: 2,
        standardRoundDurationMs: roundDurationMs,
        cooldownMs: cooldownMs,
        startsAt: baseTime + leadTime,
        schedule: const [round1, cooldown1, round2],
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final state =
          ScheduleEngine.deriveState(endedRun, baseTime + leadTime + 1000);
      expect(state.state, DerivedPhaseState.ended);
      expect(state.remainingMs, 0);
    });

    test('Zero cooldown transitions directly from round to round', () {
      const Phase r1NoCooldown = Phase(
        phaseId: 'p1',
        type: PhaseType.round,
        roundIndex: 1,
        startsAt: baseTime,
        endsAt: baseTime + roundDurationMs,
      );
      const Phase r2NoCooldown = Phase(
        phaseId: 'p2',
        type: PhaseType.round,
        roundIndex: 2,
        startsAt: baseTime + roundDurationMs,
        endsAt: baseTime + (2 * roundDurationMs),
      );

      final zeroCooldownRun = RoomRun(
        runId: 'zero_cooldown_run',
        status: RunStatus.running,
        revision: 1,
        roundCount: 2,
        standardRoundDurationMs: roundDurationMs,
        cooldownMs: 0,
        startsAt: baseTime,
        schedule: const [r1NoCooldown, r2NoCooldown],
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final stateAtBoundary = ScheduleEngine.deriveState(
          zeroCooldownRun, baseTime + roundDurationMs + 100);
      expect(stateAtBoundary.state, DerivedPhaseState.runningRound);
      expect(stateAtBoundary.currentRoundIndex, 2);
    });
  });
}
