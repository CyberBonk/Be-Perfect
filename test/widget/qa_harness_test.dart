import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:be_perfect/qa/qa_harness.dart';

void main() {
  testWidgets('QA harness preserves the app and records tap coordinates',
      (tester) async {
    await tester.pumpWidget(
      const QaHarness(
        child: MaterialApp(
          home: Scaffold(body: Center(child: Text('Normal app'))),
        ),
      ),
    );

    expect(find.text('Normal app'), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

    await tester.tapAt(const Offset(100, 300));
    await tester.pump();

    expect(find.textContaining('Tap 1'), findsOneWidget);
  });
}
