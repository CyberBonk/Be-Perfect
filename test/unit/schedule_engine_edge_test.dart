import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/core/models/phase_model.dart';
import 'package:be_perfect/core/models/run_model.dart';
import 'package:be_perfect/core/timer/schedule_engine.dart';

void main() {
  const start = 1000000;

  RoomRun runWith(List<Phase> schedule,
      {RunStatus status = RunStatus.running}) {
    return RoomRun(
      runId: 'edge-run',
      status: status,
      revision: 1,
      roundCount: 2,
      standardRoundDurationMs: 60000,
      cooldownMs: 10000,
      startsAt: start,
      schedule: schedule,
      createdAt: start,
      updatedAt: start,
    );
  }

  test('empty schedule completes instead of throwing', () {
    final state = ScheduleEngine.deriveState(runWith([]), start + 1000);
    expect(state.state, DerivedPhaseState.completed);
    expect(state.formattedTime, '00:00');
  });

  test('exact phase start belongs to that phase', () {
    const phase = Phase(
      phaseId: 'round-1',
      type: PhaseType.round,
      roundIndex: 1,
      startsAt: start,
      endsAt: start + 60000,
    );

    final state = ScheduleEngine.deriveState(runWith([phase]), start);

    expect(state.state, DerivedPhaseState.runningRound);
    expect(state.remainingMs, 60000);
  });

  test('formatted time rounds partial seconds up', () {
    const state = TimerDerivedState(
      state: DerivedPhaseState.runningRound,
      currentRoundIndex: 1,
      totalRounds: 1,
      remainingMs: 1001,
      targetEndTimestampMs: 0,
      isStartingCountdown: false,
      startingCountdownSeconds: 0,
    );

    expect(state.formattedTime, '00:02');
  });

  test('cooldown inherits the previous round when roundIndex is absent', () {
    const schedule = [
      Phase(
        phaseId: 'round-1',
        type: PhaseType.round,
        roundIndex: 1,
        startsAt: start,
        endsAt: start + 60000,
      ),
      Phase(
        phaseId: 'cooldown-1',
        type: PhaseType.cooldown,
        startsAt: start + 60000,
        endsAt: start + 70000,
      ),
    ];

    final state = ScheduleEngine.deriveState(runWith(schedule), start + 65000);

    expect(state.state, DerivedPhaseState.cooldown);
    expect(state.currentRoundIndex, 1);
  });
}
