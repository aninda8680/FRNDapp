import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frnds/screens/utilities/terms_of_service_screen.dart';
import 'package:frnds/screens/utilities/help_support_screen.dart';

void main() {
  testWidgets('Terms of Service Screen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsOfServiceScreen()));
    expect(find.text('TERMS OF SERVICE'), findsOneWidget);
    expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
  });

  testWidgets('Help & Support Screen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    expect(find.text('HELP & FAQ'), findsOneWidget);
  });
}
