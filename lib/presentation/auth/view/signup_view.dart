import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/auth/auth_page_footer.dart';
import '../../widgets/auth/auth_page_header.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().signup(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

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
                    const AuthPageHeader(topSpacing: 100),
                    const SizedBox(height: 39),
                    // AuthTextField(
                    //   hint: 'Enter Full Name',
                    //   prefixIconAsset: AppAssets.icUser,
                    //   controller: _nameController,
                    //   textInputAction: TextInputAction.next,
                    //   autofillHints: const [AutofillHints.name],
                    //   textCapitalization: TextCapitalization.words,
                    //   validator: (value) =>
                    //       FormValidators.required(value, fieldName: 'Name'),
                    // ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Enter Email',
                      prefixIconAsset: AppAssets.icEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: FormValidators.email,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Password',
                      prefixIconAsset: AppAssets.icPassword,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) => FormValidators.minLength(
                        value,
                        8,
                        fieldName: 'Password',
                      ),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Re - Enter Password',
                      prefixIconAsset: AppAssets.icPassword,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSubmit(),
                      validator: (value) {
                        final requiredError = FormValidators.required(
                          value,
                          fieldName: 'Confirm password',
                        );
                        if (requiredError != null) return requiredError;

                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    AuthPrimaryButton(
                      label: 'Signup',
                      height: 60,
                      borderRadius: 14,
                      horizontalPadding: 32,
                      labelStyle: AppTextStyles.authLoginButtonLabel,
                      isLoading: state.isSubmitting,
                      onPressed: _onSubmit,
                    ),
                    AuthPageFooter(
                      title: 'Already have an account?',
                      actionLabel: 'Sign in',
                      onActionTap: () => Navigator.of(context).pop(),
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
