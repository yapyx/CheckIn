import 'package:flutter_test/flutter_test.dart';
import 'package:checkin_flutter/main.dart';

void main() {
  testWidgets('CheckIn welcome flow renders', (tester) async {
    await tester.pumpWidget(const CheckInApp());

    expect(find.text('CheckIn'), findsOneWidget);
    expect(find.text('Tell us who you are'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);
  });
}
