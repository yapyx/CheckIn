import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_flutter/main.dart';

void main() {
  testWidgets('CheckIn app renders welcome screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CheckInApp());

    expect(find.text('CheckIn'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);
  });
}
