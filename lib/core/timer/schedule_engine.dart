import '../models/phase_model.dart';
import '../models/run_model.dart';

enum DerivedPhaseState {
  starting,
  runningRound,
  cooldown,
  paused,
  completed,
  ended,
}

class TimerDerivedState {
  final DerivedPhaseState state;
  final Phase? activePhase;
  final int currentRoundIndex;
  final int totalRounds;
  final int remainingMs;
  final int targetEndTimestampMs;
  final bool isStartingCountdown;
  final int startingCountdownSeconds; // 3, 2, 1

  const TimerDerivedState({
    required this.state,
    this.activePhase,
    required this.currentRoundIndex,
    required this.totalRounds,
    required this.remainingMs,
    required this.targetEndTimestampMs,
    required this.isStartingCountdown,
    required this.startingCountdownSeconds,
  });

  String get formattedTime {
    final totalSeconds = (remainingMs / 1000).ceil();
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }
}

class ScheduleEngine {
  /// Pure function to derive current timer state from current time [nowMs] and [run].
  static TimerDerivedState deriveState(RoomRun run, int nowMs) {
    if (run.status == RunStatus.ended) {
      return TimerDerivedState(
        state: DerivedPhaseState.ended,
        currentRoundIndex: run.roundCount,
        totalRounds: run.roundCount,
        remainingMs: 0,
        targetEndTimestampMs: nowMs,
        isStartingCountdown: false,
        startingCountdownSeconds: 0,
      );
    }

    if (run.status == RunStatus.paused && run.pausedState != null) {
      final pausedPhase = run.schedule.firstWhere(
        (p) => p.phaseId == run.pausedState!.pausedPhaseId,
        orElse: () => run.schedule.first,
      );

      final roundIndex = pausedPhase.roundIndex ??
          _findLastRoundIndex(run.schedule, pausedPhase);

      return TimerDerivedState(
        state: DerivedPhaseState.paused,
        activePhase: pausedPhase,
        currentRoundIndex: roundIndex,
        totalRounds: run.roundCount,
        remainingMs: run.pausedState!.remainingMs,
        targetEndTimestampMs: nowMs + run.pausedState!.remainingMs,
        isStartingCountdown: false,
        startingCountdownSeconds: 0,
      );
    }

    // Check if run is in 5s lead time before starting
    if (nowMs < run.startsAt) {
      final leadTimeMs = run.startsAt - nowMs;
      final countdownSec = (leadTimeMs / 1000).ceil().clamp(1, 5);

      return TimerDerivedState(
        state: DerivedPhaseState.starting,
        activePhase: run.schedule.isNotEmpty ? run.schedule.first : null,
        currentRoundIndex: 1,
        totalRounds: run.roundCount,
        remainingMs: leadTimeMs,
        targetEndTimestampMs: run.startsAt,
        isStartingCountdown: true,
        startingCountdownSeconds: countdownSec,
      );
    }

    if (run.schedule.isEmpty) {
      return TimerDerivedState(
        state: DerivedPhaseState.completed,
        currentRoundIndex: run.roundCount,
        totalRounds: run.roundCount,
        remainingMs: 0,
        targetEndTimestampMs: nowMs,
        isStartingCountdown: false,
        startingCountdownSeconds: 0,
      );
    }

    final finalPhase = run.schedule.last;
    if (nowMs >= finalPhase.endsAt) {
      return TimerDerivedState(
        state: DerivedPhaseState.completed,
        activePhase: finalPhase,
        currentRoundIndex: run.roundCount,
        totalRounds: run.roundCount,
        remainingMs: 0,
        targetEndTimestampMs: finalPhase.endsAt,
        isStartingCountdown: false,
        startingCountdownSeconds: 0,
      );
    }

    // Find active phase derived from time
    final activePhase = run.schedule.firstWhere(
      (p) => p.startsAt <= nowMs && nowMs < p.endsAt,
      orElse: () => run.schedule.first,
    );

    final remainingMs = Math.max(0, activePhase.endsAt - nowMs);
    final roundIndex = activePhase.roundIndex ??
        _findLastRoundIndex(run.schedule, activePhase);

    final derivedState = activePhase.type == PhaseType.round
        ? DerivedPhaseState.runningRound
        : DerivedPhaseState.cooldown;

    return TimerDerivedState(
      state: derivedState,
      activePhase: activePhase,
      currentRoundIndex: roundIndex,
      totalRounds: run.roundCount,
      remainingMs: remainingMs,
      targetEndTimestampMs: activePhase.endsAt,
      isStartingCountdown: false,
      startingCountdownSeconds: 0,
    );
  }

  static int _findLastRoundIndex(List<Phase> schedule, Phase target) {
    int lastRound = 1;
    for (final p in schedule) {
      if (p.roundIndex != null) {
        lastRound = p.roundIndex!;
      }
      if (p.phaseId == target.phaseId) {
        break;
      }
    }
    return lastRound;
  }
}

class Math {
  static int max(int a, int b) => a > b ? a : b;
}
