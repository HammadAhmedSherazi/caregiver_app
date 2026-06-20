import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../models/signup_flow_data.dart';

class PrivacyTermsView extends StatelessWidget {
  const PrivacyTermsView({super.key, required this.flowData});

  final SignupFlowData flowData;

  static const _termsBody =
      "Lorem Ipsum has been the industry's standard dummy text ever since the "
      '1500s, when an unknown printer took a galley of type and scrambled it to '
      'make a type specimen book. It has survived not only five centuries, but '
      'also the leap into electronic typesetting, remaining essentially '
      'unchanged. It was popularised in the 1960s with the release of Letraset '
      'sheets containing Lorem Ipsum passages, and more recently with desktop '
      'publishing software like Aldus PageMaker including versions of Lorem Ipsum.';

  Future<void> _acceptTerms(BuildContext context) async {
    final success = await context.read<AuthCubit>().acceptPrivacyTerms(
          email: flowData.email,
        );

    if (!context.mounted || !success) return;

    SnackbarHelper.showSuccess(
      context,
      'Registration complete. Please sign in to continue.',
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          SnackbarHelper.showError(context, state.errorMessage!);
        }
      },
      child: AuthScreenShell(
        maxContentWidth: 430,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  Text(
                    'Privacy Terms',
                    style: AppTextStyles.authTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 39),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _termsBody,
                        style: AppTextStyles.authTermsBody,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Accept Terms',
                    height: 60,
                    borderRadius: 14,
                    horizontalPadding: 32,
                    labelStyle: AppTextStyles.authLoginButtonLabel,
                    isLoading: state.isSubmitting,
                    onPressed: () => _acceptTerms(context),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
