import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:be_perfect/features/rooms/join_room_dialog.dart';

void main() {
  testWidgets('join validates PIN before contacting Firebase', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: JoinRoomDialog()),
    ));

    await tester.enterText(find.byKey(const ValueKey('room-pin-field')), '123');
    await tester.enterText(
        find.byKey(const ValueKey('participant-name-field')), 'Alpha');
    await tester.tap(find.byKey(const ValueKey('join-submit-button')));
    await tester.pump();

    expect(find.text('Join code must be exactly 6 numeric digits.'),
        findsOneWidget);
  });

  testWidgets('join validates participant name before contacting Firebase',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: JoinRoomDialog()),
    ));

    await tester.enterText(
        find.byKey(const ValueKey('room-pin-field')), '123456');
    await tester.tap(find.byKey(const ValueKey('join-submit-button')));
    await tester.pump();

    expect(find.text('Participant name must be between 1 and 30 characters.'),
        findsOneWidget);
  });
}
