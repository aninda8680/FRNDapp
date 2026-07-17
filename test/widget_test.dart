import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frnds/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FrndApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
