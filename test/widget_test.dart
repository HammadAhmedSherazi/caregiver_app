import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:caregiver_app/app.dart';
import 'package:caregiver_app/core/di/service_locator.dart';
import 'package:caregiver_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:caregiver_app/presentation/auth/view/signup_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  testWidgets('App opens on sign-in (no onboarding)', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Startup reads the Keychain/Keystore (real futures), and the sign-in
    // hero animates forever, so pump until sign-in shows (max ~5 s).
    for (var i = 0; i < 50 && find.text('Use my phone number').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Built for caregivers, not paperwork.'), findsNothing);
    expect(find.text('Use my phone number'), findsOneWidget);
    expect(find.text('New here? I have an invite code'), findsOneWidget);
  });

  testWidgets('Signup screen renders Figma fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => sl<AuthCubit>(),
        child: const MaterialApp(home: SignupView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getting Started'), findsOneWidget);
    expect(find.text('Enter Full Name'), findsOneWidget);
    expect(find.text('Enter Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Re - Enter Password'), findsOneWidget);
    expect(find.text('Signup Now'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
