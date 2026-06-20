import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_page_footer.dart';
import '../../widgets/auth/auth_page_header.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_screen_shell.dart';
import '../../widgets/auth/auth_social_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'forgot_password_view.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRememberMe());
  }

  Future<void> _loadRememberMe() async {
    final credentials =
        await context.read<AuthCubit>().getRememberMeCredentials();
    if (!mounted) return;

    setState(() {
      _rememberMe = credentials.enabled;
      if (credentials.email != null && credentials.email!.isNotEmpty) {
        _emailController.text = credentials.email!;
      }
      if (credentials.password != null && credentials.password!.isNotEmpty) {
        _passwordController.text = credentials.password!;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const ForgotPasswordView(),
        ),
      ),
    );
  }

  void _goToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const SignupView(),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const AuthPageHeader(),
                              const SizedBox(height: 39),
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
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _onSubmit(),
                                validator: (value) => FormValidators.required(
                                  value,
                                  fieldName: 'Password',
                                ),
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  _RememberMeTile(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() => _rememberMe = value);
                                    },
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _goToForgotPassword,
                                    child: Text(
                                      'Forget Password?',
                                      style: AppTextStyles.authLink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              AuthPrimaryButton(
                                label: 'Login Now',
                                height: 60,
                                borderRadius: 14,
                                horizontalPadding: 32,
                                labelStyle: AppTextStyles.authLoginButtonLabel,
                                isLoading: state.isSubmitting,
                                onPressed: _onSubmit,
                              ),
                              // const SizedBox(height: 40),
                              // const AuthOrDivider(),
                              // const SizedBox(height: 34),
                              // AuthSocialButton(
                              //   label: 'Sign in with Apple',
                              //   iconAsset: AppAssets.icApple,
                              //   variant: AuthSocialButtonVariant.apple,
                              //   onPressed: () {},
                              // ),
                              // const SizedBox(height: 12),
                              // AuthSocialButton(
                              //   label: 'Sign in with Google',
                              //   iconAsset: AppAssets.icGoogle,
                              //   variant: AuthSocialButtonVariant.google,
                              //   onPressed: () {},
                              // ),
                              // const SizedBox(height: 12),
                              // AuthSocialButton(
                              //   label: 'Sign in with Facebook',
                              //   iconAsset: AppAssets.icFacebook,
                              //   variant: AuthSocialButtonVariant.facebook,
                              //   onPressed: () {},
                              // ),
                            ],
                          ),
                          AuthPageFooter(
                            title: 'Haven’t signed up yet?',
                            actionLabel: 'Create an account',
                            onActionTap: _goToSignup,
                            topSpacing: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RememberMeTile extends StatelessWidget {
  const _RememberMeTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: value
                ? SvgPicture.asset(AppAssets.icRememberMe)
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.authOnGradient,
                        width: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Text(
            'Remember Me',
            style: AppTextStyles.authLink,
          ),
        ],
      ),
    );
  }
}
