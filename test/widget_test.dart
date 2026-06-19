import 'package:flutter_test/flutter_test.dart';

import 'package:caregiver_app/app.dart';
import 'package:caregiver_app/core/di/service_locator.dart';

void main() {
  setUpAll(() async {
    await setupServiceLocator();
  });

  testWidgets('App renders onboarding on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Built for caregivers, not paperwork.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
