import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_perfect/main.dart';
import 'package:be_perfect/features/rooms/join_room_dialog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('BePerfectApp builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BePerfectApp(),
      ),
    );

    expect(find.text('Timer Be Perfect'), findsWidgets);
  });

  testWidgets('Settings language dropdown applies locale transition',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BePerfectApp()),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('Join button is enabled while the form is idle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: JoinRoomDialog()),
      ),
    );

    final joinButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Join'),
    );
    expect(joinButton.onPressed, isNotNull);
  });
}
