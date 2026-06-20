import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/auth/auth_page_header.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().forgotPassword(
          email: _emailController.text,
        );

    if (!mounted || !success) return;

    SnackbarHelper.showSuccess(
      context,
      'Reset instructions sent to your email.',
    );
    Navigator.of(context).pop();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const AuthPageHeader(
                      topSpacing: 100,
                      title: 'Forgot Password?',
                      subtitle:
                          'We’ll email you instructions to reset your password.',
                    ),
                    const SizedBox(height: 52),
                    AuthTextField(
                      hint: 'Enter Email',
                      prefixIconAsset: AppAssets.icEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => _onSubmit(),
                      validator: FormValidators.email,
                    ),
                    const SizedBox(height: 18),
                    AuthPrimaryButton(
                      label: 'Continue',
                      height: 60,
                      borderRadius: 14,
                      horizontalPadding: 32,
                      labelStyle: AppTextStyles.authLoginButtonLabel,
                      isLoading: state.isSubmitting,
                      onPressed: _onSubmit,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
