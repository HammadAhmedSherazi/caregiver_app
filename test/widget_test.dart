import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caregiver_app/app.dart';
import 'package:caregiver_app/core/di/service_locator.dart';
import 'package:caregiver_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:caregiver_app/presentation/auth/view/signup_view.dart';

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
