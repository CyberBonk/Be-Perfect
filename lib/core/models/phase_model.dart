import 'package:cloud_firestore/cloud_firestore.dart';

enum PhaseType { round, cooldown }

int _parseTimestampMs(dynamic val) {
  if (val == null) return DateTime.now().millisecondsSinceEpoch;
  if (val is Timestamp) return val.millisecondsSinceEpoch;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? DateTime.now().millisecondsSinceEpoch;
  }
  return DateTime.now().millisecondsSinceEpoch;
}

class Phase {
  final String phaseId;
  final PhaseType type;
  final int? roundIndex;
  final int startsAt; // UTC milliseconds
  final int endsAt; // UTC milliseconds

  const Phase({
    required this.phaseId,
    required this.type,
    this.roundIndex,
    required this.startsAt,
    required this.endsAt,
  });

  int get durationMs => endsAt - startsAt;

  Map<String, dynamic> toJson() => {
        'phaseId': phaseId,
        'type': type == PhaseType.round ? 'round' : 'cooldown',
        'roundIndex': roundIndex,
        'startsAt': startsAt,
        'endsAt': endsAt,
      };

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      phaseId: json['phaseId'] as String? ?? 'phase',
      type: (json['type'] as String?) == 'round'
          ? PhaseType.round
          : PhaseType.cooldown,
      roundIndex: json['roundIndex'] is num
          ? (json['roundIndex'] as num).toInt()
          : null,
      startsAt: _parseTimestampMs(json['startsAt']),
      endsAt: _parseTimestampMs(json['endsAt']),
    );
  }
}
