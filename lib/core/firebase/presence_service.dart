import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ConnectionStatus {
  final bool isOnline;
  final int lastSeen;

  const ConnectionStatus({
    required this.isOnline,
    required this.lastSeen,
  });
}

class PresenceService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  StreamSubscription? _connectionSubscription;
  DatabaseReference? _myConnectionsRef;
  DatabaseReference? _lastSeenRef;
  Timer? _heartbeat;
  String? _heartbeatRoomId;
  String? _heartbeatUid;

  /// Registers user presence in Realtime Database for active [roomId] and [uid]
  void registerPresence({
    required String roomId,
    required String uid,
  }) {
    unregisterPresence();
    // A previous lifecycle/network transition can leave the native client
    // manually offline; explicitly resume it when entering a room.
    _rtdb.goOnline();
    _heartbeatRoomId = roomId;
    _heartbeatUid = uid;
    _writeHeartbeat();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
      _writeHeartbeat();
    });

    final connectionId = _rtdb.ref().push().key;
    if (connectionId == null) return;

    _myConnectionsRef =
        _rtdb.ref('presence/$roomId/$uid/connections/$connectionId');
    _lastSeenRef = _rtdb.ref('presence/$roomId/$uid/lastSeen');

    _connectionSubscription =
        _rtdb.ref('.info/connected').onValue.listen((event) {
      final connected = (event.snapshot.value as bool?) ?? false;
      if (connected && _myConnectionsRef != null) {
        // Set onDisconnect handler first before going online
        _myConnectionsRef!.onDisconnect().remove();
        _lastSeenRef!.onDisconnect().set(ServerValue.timestamp);

        _myConnectionsRef!.set(true).catchError((error) {
          debugPrint('Presence connection write failed: $error');
        });
        _lastSeenRef!.set(ServerValue.timestamp).catchError((error) {
          debugPrint('Presence lastSeen write failed: $error');
        });
      }
    });
  }

  /// Listens to presence roster of room
  Stream<Map<String, ConnectionStatus>> watchRoomPresence(String roomId) {
    return _rtdb.ref('presence/$roomId').onValue.map((event) {
      final resultMap = <String, ConnectionStatus>{};
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return resultMap;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      data.forEach((uid, userPresenceRaw) {
        if (userPresenceRaw is Map) {
          final userMap = Map<String, dynamic>.from(userPresenceRaw);
          final connections = userMap['connections'];
          final isOnline = connections != null &&
              connections is Map &&
              connections.isNotEmpty;
          final lastSeen = (userMap['lastSeen'] as num?)?.toInt() ?? 0;

          resultMap[uid] = ConnectionStatus(
            isOnline: isOnline,
            lastSeen: lastSeen,
          );
        }
      });

      return resultMap;
    });
  }

  /// Emits the device's current Realtime Database connection state.
  /// This updates immediately when the phone loses or regains connectivity.
  Stream<bool> watchConnectionState() {
    return _rtdb.ref('.info/connected').onValue.map(
          (event) => (event.snapshot.value as bool?) ?? false,
        );
  }

  void unregisterPresence() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatRoomId = null;
    _heartbeatUid = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _myConnectionsRef?.remove();
    _myConnectionsRef = null;
    _lastSeenRef = null;
  }

  Future<void> _writeHeartbeat() async {
    final roomId = _heartbeatRoomId;
    final uid = _heartbeatUid;
    if (roomId == null || uid == null) return;
    try {
      await FirebaseFirestore.instance
          .doc('rooms/$roomId/members/$uid')
          .set({'lastSeenAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Presence heartbeat failed: $error');
    }
  }
}
