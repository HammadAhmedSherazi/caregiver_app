import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  static const _headline = 'Built for caregivers, not paperwork.';
  static const _subtitle =
      "Lorem Ipsum has been the industry's standard dummy text";

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      maxContentWidth: 430,
      showCurveLine: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            const Spacer(flex: 57),
            Text(
              _headline,
              style: AppTextStyles.onboardingHeadline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 38),
              child: Text(
                _subtitle,
                style: AppTextStyles.onboardingSubtitle,
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(flex: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: AuthPrimaryButton(
                label: 'Next',
                onPressed: () =>
                    context.read<AuthCubit>().completeOnboarding(),
              ),
            ),
            const SizedBox(height: 29),
          ],
        ),
      ),
    );
  }
}
