import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/core/firebase/room_authorization.dart';

void main() {
  test('only the room owner is a controller', () {
    expect(
      isRoomController(ownerUid: 'owner', currentUid: 'owner'),
      isTrue,
    );
    expect(
      isRoomController(ownerUid: 'owner', currentUid: 'participant'),
      isFalse,
    );
    expect(isRoomController(ownerUid: null, currentUid: 'owner'), isFalse);
    expect(isRoomController(ownerUid: '', currentUid: ''), isFalse);
  });
}
