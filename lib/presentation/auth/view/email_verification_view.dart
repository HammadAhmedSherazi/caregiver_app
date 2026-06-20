import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../models/signup_flow_data.dart';
import 'finish_account_setup_view.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _returnToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: FinishAccountSetupView(
            flowData: SignupFlowData(email: widget.email.trim()),
          ),
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    final success = await context.read<AuthCubit>().resendVerificationEmail(
          email: widget.email,
        );

    if (!mounted || !success) return;

    SnackbarHelper.showSuccess(
      context,
      'Verification email sent. Please check your inbox.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = widget.email.trim().toLowerCase();

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
                    'Email Verification Required',
                    style: AppTextStyles.authTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 39),
                  AuthTextField(
                    hint: normalizedEmail,
                    prefixIconAsset: AppAssets.icEmail,
                    controller: _emailController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'We\'ve emailed a verification link to $normalizedEmail. '
                    'Please follow the link in the email to verify your account '
                    'before you can log in.\n\n'
                    'Don\'t forget to check your spam or junk folder if you '
                    'don\'t see the email.',
                    style: AppTextStyles.authSubtitle,
                  ),
                  const SizedBox(height: 32),
                  AuthPrimaryButton(
                    label: 'Return to login',
                    height: 60,
                    borderRadius: 14,
                    horizontalPadding: 32,
                    labelStyle: AppTextStyles.authLoginButtonLabel,
                    isLoading: state.isSubmitting,
                    onPressed: _returnToLogin,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        state.isSubmitting ? null : _resendVerificationEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.authOnGradient,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Resend Verification Email',
                      style: AppTextStyles.authResendLink,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
