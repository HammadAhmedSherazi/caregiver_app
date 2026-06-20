import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_setup_option_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../models/signup_flow_data.dart';
import 'activation_code_view.dart';
import 'registration_view.dart';

class FinishAccountSetupView extends StatefulWidget {
  const FinishAccountSetupView({super.key, required this.flowData});

  final SignupFlowData flowData;

  @override
  State<FinishAccountSetupView> createState() => _FinishAccountSetupViewState();
}

class _FinishAccountSetupViewState extends State<FinishAccountSetupView> {
  AccountSetupType? _selectedType;

  void _selectType(AccountSetupType type) {
    setState(() => _selectedType = type);
    _continueWithSelection(type);
  }

  void _continueWithSelection(AccountSetupType type) {
    final nextFlow = widget.flowData.copyWith(setupType: type);

    if (type == AccountSetupType.evv) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthCubit>(),
            child: ActivationCodeView(flowData: nextFlow),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: RegistrationView(flowData: nextFlow),
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    final success = await context.read<AuthCubit>().resendVerificationEmail(
          email: widget.flowData.email,
        );

    if (!mounted || !success) return;

    SnackbarHelper.showSuccess(
      context,
      'Verification email sent. Please check your inbox.',
    );
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
                    'Finish Account Setup Screen',
                    style: AppTextStyles.authTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 39),
                  AuthSetupOptionButton(
                    label: 'Perform Electronic Visit Verification (EVV)',
                    isActive: _selectedType == AccountSetupType.evv,
                    onTap: () => _selectType(AccountSetupType.evv),
                  ),
                  const SizedBox(height: 19),
                  AuthSetupOptionButton(
                    label: 'To Only answer daily Patient questions',
                    isActive: _selectedType == AccountSetupType.patientQuestionsOnly,
                    onTap: () =>
                        _selectType(AccountSetupType.patientQuestionsOnly),
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
                      style: AppTextStyles.authResendLinkRegular,
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
