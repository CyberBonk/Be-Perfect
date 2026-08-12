import 'package:cloud_firestore/cloud_firestore.dart';
import 'phase_model.dart';

enum RunStatus { starting, running, paused, completed, ended }

int _parseTimestampMs(dynamic val) {
  if (val == null) return DateTime.now().millisecondsSinceEpoch;
  if (val is Timestamp) return val.millisecondsSinceEpoch;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? DateTime.now().millisecondsSinceEpoch;
  }
  return DateTime.now().millisecondsSinceEpoch;
}

int _parseInt(dynamic val, int defaultValue) {
  if (val == null) return defaultValue;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? defaultValue;
  return defaultValue;
}

class PausedState {
  final int pausedAt;
  final String pausedPhaseId;
  final int remainingMs;

  const PausedState({
    required this.pausedAt,
    required this.pausedPhaseId,
    required this.remainingMs,
  });

  Map<String, dynamic> toJson() => {
        'pausedAt': pausedAt,
        'pausedPhaseId': pausedPhaseId,
        'remainingMs': remainingMs,
      };

  factory PausedState.fromJson(Map<String, dynamic> json) {
    return PausedState(
      pausedAt: _parseTimestampMs(json['pausedAt']),
      pausedPhaseId: json['pausedPhaseId'] as String? ?? '',
      remainingMs: _parseInt(json['remainingMs'], 0),
    );
  }
}

class RoomRun {
  final String runId;
  final RunStatus status;
  final int revision;
  final int roundCount;
  final int standardRoundDurationMs;
  final int cooldownMs;
  final int startsAt;
  final List<Phase> schedule;
  final PausedState? pausedState;
  final int createdAt;
  final int updatedAt;
  final int? endedAt;

  const RoomRun({
    required this.runId,
    required this.status,
    required this.revision,
    required this.roundCount,
    required this.standardRoundDurationMs,
    required this.cooldownMs,
    required this.startsAt,
    required this.schedule,
    this.pausedState,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
  });

  factory RoomRun.fromJson(Map<String, dynamic> json) {
    return RoomRun(
      runId: json['runId'] as String? ?? 'run',
      status: _parseStatus(json['status'] as String?),
      revision: _parseInt(json['revision'], 1),
      roundCount: _parseInt(json['roundCount'], 1),
      standardRoundDurationMs:
          _parseInt(json['standardRoundDurationMs'], 60000),
      cooldownMs: _parseInt(json['cooldownMs'], 0),
      startsAt: _parseTimestampMs(json['startsAt']),
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((e) => Phase.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      pausedState: json['pausedState'] != null
          ? PausedState.fromJson(
              Map<String, dynamic>.from(json['pausedState'] as Map))
          : null,
      createdAt: _parseTimestampMs(json['createdAt']),
      updatedAt: _parseTimestampMs(json['updatedAt']),
      endedAt:
          json['endedAt'] != null ? _parseTimestampMs(json['endedAt']) : null,
    );
  }

  static RunStatus _parseStatus(String? status) {
    switch (status) {
      case 'starting':
        return RunStatus.starting;
      case 'paused':
        return RunStatus.paused;
      case 'completed':
        return RunStatus.completed;
      case 'ended':
        return RunStatus.ended;
      case 'running':
      default:
        return RunStatus.running;
    }
  }

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'status': status.name,
        'revision': revision,
        'roundCount': roundCount,
        'standardRoundDurationMs': standardRoundDurationMs,
        'cooldownMs': cooldownMs,
        'startsAt': startsAt,
        'schedule': schedule.map((p) => p.toJson()).toList(),
        'pausedState': pausedState?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'endedAt': endedAt,
      };
}
