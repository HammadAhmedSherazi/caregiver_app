import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../models/signup_flow_data.dart';
import 'registration_view.dart';

class ActivationCodeView extends StatefulWidget {
  const ActivationCodeView({super.key, required this.flowData});

  final SignupFlowData flowData;

  @override
  State<ActivationCodeView> createState() => _ActivationCodeViewState();
}

class _ActivationCodeViewState extends State<ActivationCodeView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().submitActivationCode(
          email: widget.flowData.email,
          code: _codeController.text.trim(),
        );

    if (!mounted || !success) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: RegistrationView(flowData: widget.flowData),
        ),
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      'Activation Code',
                      style: AppTextStyles.authTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 39),
                    AuthTextField(
                      hint: 'Enter Code',
                      prefixIconAsset: AppAssets.icPassword,
                      controller: _codeController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSubmit(),
                      validator: (value) => FormValidators.minLength(
                        value,
                        4,
                        fieldName: 'Activation code',
                      ),
                    ),
                    const SizedBox(height: 14),
                    AuthPrimaryButton(
                      label: 'Submit Code',
                      height: 60,
                      borderRadius: 14,
                      horizontalPadding: 32,
                      labelStyle: AppTextStyles.authLoginButtonLabel,
                      isLoading: state.isSubmitting,
                      onPressed: _onSubmit,
                    ),
                    const SizedBox(height: 32),
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
