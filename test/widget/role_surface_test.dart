import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/core/firebase/firebase_providers.dart';
import 'package:be_perfect/features/announcements/announcements_page.dart';

Widget roleHost({required bool isController}) {
  return ProviderScope(
    overrides: [
      feedStreamProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: AnnouncementsPage(isController: isController)),
    ),
  );
}

void main() {
  testWidgets('controller announcement surface exposes device notification',
      (tester) async {
    await tester.pumpWidget(roleHost(isController: true));

    expect(find.text('Notify Devices'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Type announcement...');
  });

  testWidgets('participant announcement surface cannot notify devices',
      (tester) async {
    await tester.pumpWidget(roleHost(isController: false));

    expect(find.text('Notify Devices'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Send a message to the room...');
  });
}
