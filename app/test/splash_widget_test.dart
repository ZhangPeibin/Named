import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/splash_widget.dart';

void main() {
  testWidgets('splash uses Named branding by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashWidget()));

    expect(find.text('Named'), findsOneWidget);
    expect(find.text('A reusable Flutter starter.'), findsOneWidget);
    expect(find.text('ArvoPay'), findsNothing);
    expect(find.textContaining('crypto'), findsNothing);
  });
}
