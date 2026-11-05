import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/startup/configuration_error_app.dart';

void main() {
  testWidgets('shows a generic configuration error without internal values', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfigurationErrorApp());

    expect(find.text('Unable to start the app'), findsOneWidget);
    expect(find.textContaining('configuration is invalid'), findsOneWidget);
    expect(find.textContaining('API_BASE_URL'), findsNothing);
  });
}
