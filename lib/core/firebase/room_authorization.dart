/// Returns whether [currentUid] owns the room identified by [ownerUid].
///
/// Kept pure so the same invariant can be tested without Firebase and reused
/// by online and offline command paths.
bool isRoomController({String? ownerUid, String? currentUid}) {
  return ownerUid != null && ownerUid.isNotEmpty && ownerUid == currentUid;
}
