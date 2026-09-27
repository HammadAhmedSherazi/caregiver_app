import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators/form_validators.dart';
import '../../../core/utils/velora_format.dart';
import '../../widgets/auth/auth_gradient_background.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/velora/velora.dart';
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
  bool _obscurePassword = true;

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
    return PostActionListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          (previous.isSubmitting || current.isSubmitting),
      errorMessage: (state) => state.errorMessage,
      onClearError: () => context.read<AuthCubit>().clearActionError(),
      child: Scaffold(
        backgroundColor: VeloraColors.brandDeepest,
        resizeToAvoidBottomInset: true,
        body: AuthGradientBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: _LoginHero()),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _buildSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140A1E1A),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        24,
        22,
        26 + MediaQuery.paddingOf(context).bottom,
      ),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: VeloraColors.mint,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: VeloraColors.amber, spreadRadius: 2),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const VeloraIcon(
                          VeloraIcons.user,
                          size: 28,
                          color: VeloraColors.teal,
                          strokeWidth: 1.8,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              VeloraFormat.greeting(),
                              style: VeloraText.body(
                                13,
                                weight: FontWeight.w600,
                                color: VeloraColors.muted,
                              ),
                            ),
                            Text('Welcome back', style: VeloraText.display(23)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  VeloraTextField(
                    hint: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 12),
                  VeloraTextField(
                    hint: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _onSubmit(),
                    validator: (value) => FormValidators.required(
                      value,
                      fieldName: 'Password',
                    ),
                    suffix: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: VeloraIcon(
                        _obscurePassword ? VeloraIcons.eye : VeloraIcons.eyeOff,
                        size: 20,
                        color: VeloraColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _RememberMeTile(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  VeloraButton(
                    label: 'Sign in',
                    icon: VeloraIcons.lock,
                    isLoading: state.isSubmitting,
                    onPressed: _onSubmit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 250),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const HeaderRings(size: 360, opacity: 0.12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/brand/velora_logo_light.png',
                    width: 250,
                    semanticLabel: 'VELORA',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Caregiver app',
                    textAlign: TextAlign.center,
                    style: VeloraText.body(
                      13,
                      weight: FontWeight.w600,
                      color: const Color(0xFFCFE2DC),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return Semantics(
      checked: value,
      label: 'Remember me',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  activeColor: VeloraColors.brand,
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Remember me',
                style: VeloraText.body(
                  13.5,
                  weight: FontWeight.w600,
                  color: VeloraColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
