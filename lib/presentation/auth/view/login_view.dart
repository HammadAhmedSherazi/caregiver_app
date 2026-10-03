import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../../data/local/face_id_store.dart';
import '../../../data/local/language_store.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../widgets/auth/auth_gradient_background.dart';
import '../../widgets/auth/water_ripple.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'forgot_password_view.dart';
import 'login_strings.dart';
import 'signup_view.dart';

/// Steps of the sign-in sheet, as in the VELORA design's `SignIn` page.
enum _Step {
  welcome,
  scan,
  faceFail,
  faceLocked,
  phone,
  code,
  busy,
  invite,
  inviteOk,
  email,
  setup,
  done,
  faceOff,
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteController = TextEditingController();
  final _biometric = sl<BiometricAuth>();
  final _languageStore = sl<LanguageStore>();
  final _faceStore = sl<FaceIdStore>();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  _Step _step = _Step.welcome;
  String _busyText = '';
  String? _error;
  bool _errorIsNotLive = false;

  // Phone sign-in.
  String _phone = '';
  String _code = '';
  String _phoneMasked = '';
  int _resendSecs = 0;
  Timer? _resendTimer;
  bool _inviteFlow = false;
  InviteDetailsModel? _invite;

  // Face ID unlocks the session saved in the Keychain / Keystore
  // (MOBILE_API_VELORA.md §1); no password is stored.
  bool _faceEnabled = false;
  String? _faceName;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Face ID';

  // First name of the caregiver who just signed in, for "You're in".
  String? _signedInName;

  /// Face ID can sign in right now: turned on, available, and a saved
  /// session is waiting to be unlocked.
  bool get _faceReady =>
      _biometricAvailable &&
      _faceEnabled &&
      context.read<AuthCubit>().state.faceLocked;

  static String? _firstName(String? name) {
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? null : first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRememberMe());
  }

  Future<void> _loadRememberMe() async {
    final credentials =
        await context.read<AuthCubit>().getRememberMeCredentials();
    final available = await _biometric.isAvailable();
    final label = available ? await _biometric.label() : _biometricLabel;
    final faceEnabled = await _faceStore.isEnabled();
    final faceName = await _faceStore.name();
    if (!mounted) return;

    setState(() {
      _rememberMe = credentials.enabled;
      if (credentials.email != null && credentials.email!.isNotEmpty) {
        _emailController.text = credentials.email!;
      }
      if (credentials.password != null && credentials.password!.isNotEmpty) {
        _passwordController.text = credentials.password!;
      }
      _faceEnabled = faceEnabled;
      _faceName = faceName;
      _biometricAvailable = available;
      _biometricLabel = label;
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _go(_Step step, {bool keepError = false}) {
    setState(() {
      _step = step;
      if (!keepError) {
        _error = null;
        _errorIsNotLive = false;
      }
    });
  }

  void _fail(_Step step, Object error, LoginStrings strings) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _errorIsNotLive = error is ApiNotLiveException;
      _error = switch (error) {
        ApiNotLiveException() => strings.phoneNotLive,
        ApiException(:final message) => message,
        _ => strings.genericError,
      };
    });
  }

  // -------------------------------------------------------------- email

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final user = await context.read<AuthCubit>().login(
          email: email,
          password: password,
          rememberMe: _rememberMe,
          deferSession: true,
        );
    if (user == null || !mounted) return; // the error is shown by the listener

    _afterSignIn(user.name);
  }

  /// Every sign-in (email, phone) ends here: offer Face ID if it's off,
  /// otherwise straight to "You're in". With Face ID on, the new session is
  /// what Face ID unlocks next time.
  void _afterSignIn(String? fullName) {
    _signedInName = _firstName(fullName);
    _go(_biometricAvailable && !_faceEnabled ? _Step.setup : _Step.done);
  }

  // ---------------------------------------------------- Face ID set-up

  Future<void> _turnOnFace(LoginStrings strings) async {
    // The first check also shows the iPhone "Allow Face ID?" permission.
    final result =
        await _biometric.authenticate(strings.faceReason(_biometricLabel));
    if (!mounted) return;
    if (result == BiometricResult.success) {
      await context
          .read<AuthCubit>()
          .setFaceIdEnabled(true, name: _signedInName);
      if (!mounted) return;
      setState(() {
        _faceEnabled = true;
        _faceName = _signedInName;
      });
    }
    _go(_Step.done);
  }

  void _enterApp() => context.read<AuthCubit>().finishSignIn();

  // ------------------------------------------------------------ Face ID

  Future<void> _signInWithFace(LoginStrings strings) async {
    if (!_faceReady) {
      // Not set up on the phone, or not turned on for this app yet.
      _go(_Step.faceOff);
      return;
    }
    _go(_Step.scan);
    final result =
        await _biometric.authenticate(strings.faceReason(_biometricLabel));
    if (!mounted || _step != _Step.scan) return;

    switch (result) {
      case BiometricResult.success:
        setState(() {
          _step = _Step.busy;
          _busyText = strings.signingIn;
        });
        final user = await context.read<AuthCubit>().unlockWithFaceId();
        if (!mounted) return;
        if (user == null) {
          // The saved session has ended; the listener shows why.
          _go(_Step.welcome, keepError: true);
          return;
        }
        _signedInName = _firstName(user.name) ?? _faceName;
        _go(_Step.done);
      case BiometricResult.cancelled:
        _go(_Step.welcome);
      case BiometricResult.failed:
        _go(_Step.faceFail);
      case BiometricResult.lockedOut:
        _go(_Step.faceLocked);
      case BiometricResult.unavailable:
        setState(() => _biometricAvailable = false);
        _go(_Step.welcome);
    }
  }

  void _cancelScan() {
    _biometric.cancel();
    _go(_Step.welcome);
  }

  // -------------------------------------------------------------- phone

  void _toPhone() {
    setState(() => _code = '');
    _go(_Step.phone);
  }

  void _toWelcome() {
    _resendTimer?.cancel();
    setState(() {
      _phone = '';
      _code = '';
      _inviteFlow = false;
      _invite = null;
    });
    _go(_Step.welcome);
  }

  void _onKey(String key, LoginStrings strings) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _errorIsNotLive = false;
      if (_step == _Step.phone) {
        if (key == 'del') {
          if (_phone.isNotEmpty) _phone = _phone.substring(0, _phone.length - 1);
        } else if (_phone.length < 10) {
          _phone += key;
        }
      } else if (_step == _Step.code) {
        if (key == 'del') {
          if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
        } else if (_code.length < 6) {
          _code += key;
        }
      }
    });
    if (_step == _Step.code && _code.length == 6) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted && _step == _Step.code && _code.length == 6) {
          _verifyCode(strings);
        }
      });
    }
  }

  Future<void> _sendCode(LoginStrings strings) async {
    setState(() {
      _step = _Step.busy;
      _busyText = strings.sending;
    });
    try {
      final cubit = context.read<AuthCubit>();
      final sent = _inviteFlow && _invite != null
          ? await cubit.confirmInvite(
              code: _inviteController.text,
              phone: _phone,
            )
          : await cubit.sendPhoneCode(_phone);
      if (!mounted) return;
      setState(() {
        _code = '';
        _phoneMasked = sent.phoneMasked.isNotEmpty
            ? sent.phoneMasked
            : _maskPhone(_phone);
      });
      _startResendTimer(sent.resendIn.inSeconds);
      _go(_Step.code);
    } catch (error) {
      _fail(_Step.phone, error, strings);
    }
  }

  Future<void> _verifyCode(LoginStrings strings) async {
    setState(() {
      _step = _Step.busy;
      _busyText = strings.verifying;
    });
    try {
      await context
          .read<AuthCubit>()
          .verifyPhoneCode(phone: _phone, code: _code);
      if (!mounted) return;
      _afterSignIn(context.read<AuthCubit>().pendingUserName);
    } catch (error) {
      setState(() => _code = '');
      _fail(_Step.code, error, strings);
    }
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecs = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSecs <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSecs = 0);
        return;
      }
      setState(() => _resendSecs--);
    });
  }

  static String _formatPhone(String p) {
    var out = '';
    if (p.isNotEmpty) out = '(${p.substring(0, math.min(3, p.length))}';
    if (p.length >= 3) out += ') ${p.substring(3, math.min(6, p.length))}';
    if (p.length >= 6) out += '-${p.substring(6)}';
    return out;
  }

  static String _maskPhone(String p) => p.length == 10
      ? '(${p.substring(0, 3)}) •••-${p.substring(6)}'
      : _formatPhone(p);

  // ------------------------------------------------------------- invite

  Future<void> _checkInvite(LoginStrings strings) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = _Step.busy;
      _busyText = strings.checking;
    });
    try {
      final invite =
          await context.read<AuthCubit>().checkInvite(_inviteController.text);
      if (!mounted) return;
      setState(() => _invite = invite);
      _go(_Step.inviteOk);
    } catch (error) {
      _fail(_Step.invite, error, strings);
    }
  }

  void _confirmInvite() {
    setState(() {
      _inviteFlow = true;
      _phone = '';
    });
    _toPhone();
  }

  // Kept for when the forgot-password and sign-up links return to this
  // screen; both are hidden in the current design.
  // ignore: unused_element
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

  // ignore: unused_element
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
    return ValueListenableBuilder<String>(
      valueListenable: _languageStore.language,
      builder: (context, language, _) {
        final strings = LoginStrings.of(language);
        return Directionality(
          textDirection:
              strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: _buildPage(context, strings),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, LoginStrings strings) {
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
                          Expanded(
                            child: _LoginHero(
                              strings: strings,
                              onLanguageChanged: _languageStore.set,
                            ),
                          ),
                          _buildSheet(context, strings),
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

  Widget _buildSheet(BuildContext context, LoginStrings strings) {
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
      // The white panel and its content span the full width (tablets too).
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: VeloraSpacing.maxContentWidth),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: const Cubic(0.2, 0.7, 0.2, 1),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(context, state, strings),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    AuthState state,
    LoginStrings strings,
  ) {
    final method = _biometricLabel;

    switch (_step) {
      case _Step.welcome:
        return _buildWelcome(state, strings);

      case _Step.scan:
        return _FaceScanPanel(
          title: strings.scanning,
          cancelLabel: strings.cancel,
          onCancel: _cancelScan,
          troubleLabel: strings.trouble,
          onTrouble: () {
            _biometric.cancel();
            _go(_Step.faceFail);
          },
        );

      case _Step.faceFail:
      case _Step.faceLocked:
        final locked = _step == _Step.faceLocked;
        return _FaceFailPanel(
          title:
              locked ? strings.lockedTitle(method) : strings.failTitle(method),
          message: locked ? strings.lockedSub : strings.failSub,
          retryLabel: locked ? null : strings.tryAgain(method),
          onRetry: () => _signInWithFace(strings),
          otherLabel: strings.usePhone,
          otherIcon: VeloraIcons.mobile,
          onOther: _toPhone,
        );

      case _Step.busy:
        return _BusyPanel(text: _busyText);

      case _Step.phone:
        return _buildPhone(strings);

      case _Step.code:
        return _buildCode(strings);

      case _Step.invite:
        return _buildInvite(strings);

      case _Step.inviteOk:
        return _buildInviteOk(strings);

      case _Step.email:
        return _buildEmail(state, strings);

      case _Step.setup:
        return _FaceSetupPanel(
          title: strings.setupTitle(method),
          message: strings.setupSub(method),
          turnOnLabel: strings.turnOn(method),
          notNowLabel: strings.notNow,
          onTurnOn: () => _turnOnFace(strings),
          onNotNow: () => _go(_Step.done),
        );

      case _Step.faceOff:
        return _FaceFailPanel(
          title: !_biometricAvailable
              ? strings.faceMissingTitle(method)
              : _faceEnabled
                  ? strings.faceSignedOutTitle(method)
                  : strings.faceOffTitle(method),
          message: !_biometricAvailable
              ? strings.faceMissingSub
              : _faceEnabled
                  ? strings.faceSignedOutSub(method)
                  : strings.faceOffSubFor(method),
          retryLabel: strings.usePhone,
          retryIcon: VeloraIcons.mobile,
          onRetry: _toPhone,
          otherLabel: strings.emailSignIn,
          otherIcon: VeloraIcons.mail,
          onOther: () => _go(_Step.email),
          calm: true,
        );

      case _Step.done:
        return _DonePanel(
          title: strings.doneTitle(_signedInName),
          message: strings.doneSub,
          goLabel: strings.go,
          onGo: _enterApp,
        );
    }
  }

  Widget _buildWelcome(AuthState state, LoginStrings strings) {
    final method = _biometricLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WelcomeRow(strings: strings, name: _faceEnabled ? _faceName : null),
        const SizedBox(height: 18),
        _SignInButton(
          label: strings.faceSignIn(method),
          icon: VeloraIcons.faceIdScan,
          big: true,
          isLoading: state.isSubmitting,
          onPressed: () => _signInWithFace(strings),
        ),
        const SizedBox(height: 12),
        _SignInButton(
          label: strings.usePhone,
          icon: VeloraIcons.mobile,
          variant: VeloraButtonVariant.ghost,
          onPressed: state.isSubmitting ? null : _toPhone,
        ),
        const SizedBox(height: 2),
        _LinkButton(
          label: strings.inviteLink,
          onPressed: () => _go(_Step.invite),
        ),
      ],
    );
  }

  Widget _buildPhone(LoginStrings strings) {
    final ready = _phone.length == 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: strings.phoneTitle,
          backLabel: strings.back,
          onBack: _inviteFlow ? () => _go(_Step.inviteOk) : _toWelcome,
        ),
        const SizedBox(height: 14),
        _PhoneDisplay(
          formatted: _formatPhone(_phone),
          placeholder: '(555) 000-0000',
        ),
        _ErrorLine(
          message: _error,
          actionLabel: _errorIsNotLive ? strings.emailLink : null,
          onAction: () => _go(_Step.email),
        ),
        const SizedBox(height: 14),
        _Keypad(
          deleteLabel: strings.delete,
          onKey: (k) => _onKey(k, strings),
        ),
        const SizedBox(height: 14),
        _SignInButton(
          label: strings.send,
          icon: VeloraIcons.send,
          onPressed: ready ? () => _sendCode(strings) : null,
        ),
        // Phone sign-in turned off (VELORA_GROUP1=false); keep the working
        // email sign-in one tap away.
        if (!ApiConfig.veloraGroup1Enabled && !_errorIsNotLive)
          _LinkButton(
            label: strings.emailLink,
            muted: true,
            onPressed: () => _go(_Step.email),
          ),
      ],
    );
  }

  Widget _buildCode(LoginStrings strings) {
    final secs = _resendSecs.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: strings.codeTitle,
          subtitle: strings.codeSub(_phoneMasked),
          backLabel: strings.back,
          onBack: _toPhone,
        ),
        const SizedBox(height: 14),
        _CodeBoxes(code: _code),
        _ErrorLine(message: _error),
        const SizedBox(height: 14),
        _Keypad(
          deleteLabel: strings.delete,
          onKey: (k) => _onKey(k, strings),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: Center(
            child: _resendSecs > 0
                ? Text(
                    strings.resendIn('0:$secs'),
                    style: VeloraText.body(13, color: VeloraColors.muted),
                  )
                : _LinkButton(
                    label: strings.resend,
                    onPressed: () => _sendCode(strings),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvite(LoginStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: strings.inviteTitle,
          backLabel: strings.back,
          onBack: _toWelcome,
        ),
        const SizedBox(height: 10),
        Text(
          strings.inviteSub,
          style: VeloraText.body(14, color: VeloraColors.muted)
              .copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        Text(
          strings.inviteLabel,
          style: VeloraText.body(
            12.5,
            weight: FontWeight.w700,
            color: VeloraColors.body,
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _inviteController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onSubmitted: (_) => _checkInvite(strings),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: VeloraText.display(22, color: VeloraColors.brand)
                .copyWith(letterSpacing: 22 * 0.12),
            decoration: InputDecoration(
              filled: true,
              fillColor: VeloraColors.subtle,
              hintText: 'SSHC-4821',
              hintStyle: VeloraText.display(22, color: VeloraColors.faint)
                  .copyWith(letterSpacing: 22 * 0.12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: VeloraColors.fieldBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: VeloraColors.teal, width: 1.5),
              ),
            ),
          ),
        ),
        _ErrorLine(
          message: _error,
          actionLabel: _errorIsNotLive ? strings.emailLink : null,
          onAction: () => _go(_Step.email),
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: _inviteController,
          builder: (context, _) => _SignInButton(
            label: strings.checkInvite,
            onPressed: _inviteController.text.trim().isEmpty
                ? null
                : () => _checkInvite(strings),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteOk(LoginStrings strings) {
    final invite = _invite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeloraColors.mintSoft,
            border: Border.all(color: const Color(0xFFCFE3DB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/brand/velora_mark.png',
                width: 44,
                height: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.invitedBy,
                      style: VeloraText.body(15, weight: FontWeight.w700),
                    ),
                    if (invite != null && invite.agencyName.isNotEmpty)
                      Text(
                        invite.agencyName,
                        style: VeloraText.body(
                          12.5,
                          color: VeloraColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: VeloraColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _DetailRow(label: strings.you, value: invite?.caregiverName),
              const Divider(height: 1, color: VeloraColors.line),
              _DetailRow(label: strings.client, value: invite?.clientName),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SignInButton(label: strings.looksRight, onPressed: _confirmInvite),
        _LinkButton(label: strings.notMe, onPressed: _toWelcome),
      ],
    );
  }

  Widget _buildEmail(AuthState state, LoginStrings strings) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeader(
              title: strings.emailTitle,
              backLabel: strings.back,
              onBack: _toWelcome,
            ),
            const SizedBox(height: 14),
            VeloraTextField(
              hint: strings.email,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.emailRequired;
                }
                return FormValidators.email(value) == null
                    ? null
                    : strings.emailInvalid;
              },
            ),
            const SizedBox(height: 12),
            VeloraTextField(
              hint: strings.password,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _onSubmit(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.passwordRequired
                  : null,
              suffix: IconButton(
                tooltip: _obscurePassword
                    ? strings.showPassword
                    : strings.hidePassword,
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
              label: strings.rememberMe,
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value);
              },
            ),
            const SizedBox(height: 10),
            _SignInButton(
              label: strings.signIn,
              icon: VeloraIcons.lock,
              isLoading: state.isSubmitting,
              onPressed: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet building blocks
// ---------------------------------------------------------------------------

/// Back chevron + title (+ optional subtitle), as on the phone/code steps.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            tooltip: backLabel,
            padding: EdgeInsets.zero,
            onPressed: onBack,
            icon: VeloraIcon(
              VeloraIcons.chevronLeft, // mirrored in RTL by VeloraIcon
              size: 22,
              color: VeloraColors.teal,
              strokeWidth: 2.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VeloraText.display(22)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: VeloraText.body(13, color: VeloraColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: VeloraColors.teal,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: VeloraText.body(
            13.5,
            weight: FontWeight.w700,
            color: muted ? VeloraColors.muted : VeloraColors.teal,
          ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message, this.actionLabel, this.onAction});

  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: VeloraText.body(
                13,
                weight: FontWeight.w600,
                color: VeloraColors.dangerText,
              ).copyWith(height: 1.4),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                ),
                child: Text(actionLabel!, style: VeloraText.link),
              ),
          ],
        ),
      ),
    );
  }
}

class _BusyPanel extends StatelessWidget {
  const _BusyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 34, 0, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: VeloraColors.teal,
              backgroundColor: VeloraColors.mint,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            text,
            textAlign: TextAlign.center,
            style: VeloraText.body(
              15,
              weight: FontWeight.w700,
              color: VeloraColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// `+1 | (586) 555-4002▍` field that the keypad types into.
class _PhoneDisplay extends StatelessWidget {
  const _PhoneDisplay({required this.formatted, required this.placeholder});

  final String formatted;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final empty = formatted.isEmpty;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        liveRegion: true,
        label: empty ? null : formatted,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: VeloraColors.teal, width: 1.5),
            boxShadow: const [
              BoxShadow(color: VeloraColors.mint, spreadRadius: 4),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.only(end: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: VeloraColors.line),
                  ),
                ),
                child: Text(
                  '+1',
                  style: VeloraText.body(
                    14,
                    weight: FontWeight.w700,
                    color: VeloraColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                empty ? placeholder : formatted,
                style: VeloraText.body(
                  22,
                  weight: empty ? FontWeight.w600 : FontWeight.w700,
                  color: empty ? const Color(0xFFA5B3AE) : VeloraColors.ink,
                ).copyWith(
                  letterSpacing: 22 * 0.02,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!empty) const _BlinkingCaret(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _blink.stop();
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, _) => Opacity(
        opacity: _blink.value < 0.5 ? 1 : 0,
        child: Container(
          width: 2,
          height: 26,
          margin: const EdgeInsets.only(left: 2),
          color: VeloraColors.teal,
        ),
      ),
    );
  }
}

/// Six boxes for the texted code (`.box`, `.box.cur`, `.box.fill`).
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        liveRegion: true,
        label: '${code.length} of 6',
        child: Row(
          children: [
            for (var i = 0; i < 6; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(child: _box(i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _box(int i) {
    final filled = i < code.length;
    final current = i == code.length;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled || current ? Colors.white : VeloraColors.subtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current ? VeloraColors.teal : VeloraColors.fieldBorder,
          width: 1.5,
        ),
        boxShadow: current
            ? const [BoxShadow(color: VeloraColors.mint, spreadRadius: 4)]
            : null,
      ),
      child: Text(
        filled ? code[i] : '',
        style: VeloraText.display(26, color: VeloraColors.brand),
      ),
    );
    if (!filled) return box;
    return TweenAnimationBuilder<double>(
      key: ValueKey('filled-$i'),
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: box,
    );
  }
}

/// 3×4 number pad (`.pad`): 1–9, blank, 0, delete.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.deleteLabel});

  final ValueChanged<String> onKey;
  final String deleteLabel;

  static const _keys = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del', //
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: _key(_keys[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _key(String key) {
    if (key.isEmpty) return const SizedBox(height: 52);
    final isDelete = key == 'del';
    return Semantics(
      button: true,
      label: isDelete ? deleteLabel : key,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFF2F6F4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: VeloraColors.mint,
          highlightColor: const Color(0xFFE6EEEA),
          onTap: () => onKey(key),
          child: SizedBox(
            height: 52,
            child: Center(
              child: isDelete
                  ? const VeloraIcon(
                      VeloraIcons.backspace,
                      size: 24,
                      color: VeloraColors.ink,
                      strokeWidth: 1.9,
                    )
                  : Text(
                      key,
                      style: VeloraText.display(
                        22,
                        weight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(label, style: VeloraText.body(14, color: VeloraColors.muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value == null || value!.isEmpty ? '—' : value!,
              textAlign: TextAlign.end,
              style: VeloraText.body(14, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeRow extends StatelessWidget {
  const _WelcomeRow({required this.strings, this.name});

  final LoginStrings strings;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                strings.greeting(),
                style: VeloraText.body(
                  13,
                  weight: FontWeight.w600,
                  color: VeloraColors.muted,
                ),
              ),
              Text(strings.welcomeFor(name), style: VeloraText.display(23)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero: language switch, water ripple, floating logo
// ---------------------------------------------------------------------------

class _LoginHero extends StatefulWidget {
  const _LoginHero({required this.strings, required this.onLanguageChanged});

  final LoginStrings strings;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<_LoginHero> createState() => _LoginHeroState();
}

class _LoginHeroState extends State<_LoginHero> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final AnimationController _drift = AnimationController(
    vsync: this,
    // One full there-and-back cycle of the design's 14s alternate drift.
    duration: const Duration(seconds: 28),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _intro.value = 1;
      _bob.stop();
      _drift.stop();
      return;
    }
    if (_started) return;
    _started = true;
    _intro.forward();
    _drift.repeat();
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted && !_bob.isAnimating) _bob.repeat();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _bob.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intro = CurvedAnimation(
      parent: _intro,
      curve: const Cubic(0.2, 0.7, 0.2, 1),
    );
    final tagline = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1, curve: Curves.ease),
    );

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DriftingBlobsPainter(_drift)),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(painter: _SurfaceLinesPainter()),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 250),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _LanguageToggle(
                        label: widget.strings.languageLabel,
                        isArabic: widget.strings.isArabic,
                        onChanged: widget.onLanguageChanged,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: WaterRipple()),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: intro,
                                  child: ScaleTransition(
                                    scale: Tween(begin: 0.94, end: 1.0)
                                        .animate(intro),
                                    child: SlideTransition(
                                      position: Tween(
                                        begin: const Offset(0, 0.12),
                                        end: Offset.zero,
                                      ).animate(intro),
                                      child: AnimatedBuilder(
                                        animation: _bob,
                                        builder: (context, child) =>
                                            Transform.translate(
                                          offset: Offset(
                                            0,
                                            -3 +
                                                3 *
                                                    math.cos(
                                                      _bob.value * 2 * math.pi,
                                                    ),
                                          ),
                                          child: child,
                                        ),
                                        child: const _ShadowedLogo(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FadeTransition(
                                  opacity: tagline,
                                  child: Text(
                                    widget.strings.tagline,
                                    textAlign: TextAlign.center,
                                    style: VeloraText.body(
                                      13,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFFCFE2DC),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft coloured light drifting slowly behind the logo (`.blob` in the design).
class _DriftingBlobsPainter extends CustomPainter {
  _DriftingBlobsPainter(this.drift) : super(repaint: drift);

  final Animation<double> drift;

  static const _blobs = [
    // (left, top, diameter, colour, phase)
    (-80.0, -60.0, 260.0, Color(0x8C37B199), 0.0),
    (200.0, 120.0, 280.0, Color(0x52E0A72E), 0.43),
    (60.0, 220.0, 300.0, Color(0x732E9C86), 0.21),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    for (final (left, top, d, color, phase) in _blobs) {
      // Triangle wave: forwards through the keyframes, then back again.
      final x = (drift.value + phase) % 1.0 * 2;
      final t = x <= 1 ? x : 2 - x;
      // 0 → 0.5 → 1 matches the design's drift keyframes.
      final (dx, dy, scale) = t < 0.5
          ? _lerp3((0, 0, 1), (30, 20, 1.12), t * 2)
          : _lerp3((30, 20, 1.12), (-20, 35, 0.95), (t - 0.5) * 2);
      final radius = d * sx * scale / 2;
      final center = Offset(
        (left + d / 2 + dx) * sx,
        top + d / 2 + dy,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  static (double, double, double) _lerp3(
    (double, double, double) a,
    (double, double, double) b,
    double t,
  ) {
    final e = Curves.easeInOut.transform(t.clamp(0, 1));
    return (
      a.$1 + (b.$1 - a.$1) * e,
      a.$2 + (b.$2 - a.$2) * e,
      a.$3 + (b.$3 - a.$3) * e,
    );
  }

  @override
  bool shouldRepaint(covariant _DriftingBlobsPainter oldDelegate) => false;
}

/// Two faint current lines across the lower hero.
class _SurfaceLinesPainter extends CustomPainter {
  const _SurfaceLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 400);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(-20, 300)
        ..cubicTo(80, 240, 160, 340, 260, 270)
        ..cubicTo(360, 200, 420, 230, 420, 230),
      paint..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 330)
        ..cubicTo(90, 270, 170, 370, 270, 300)
        ..cubicTo(370, 230, 420, 260, 420, 260),
      paint..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _SurfaceLinesPainter oldDelegate) => false;
}

/// English / العربية pill switch (`.seg` in the design).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.label,
    required this.isArabic,
    required this.onChanged,
  });

  final String label;
  final bool isArabic;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment('English', 'en', !isArabic),
            const SizedBox(width: 2),
            _segment('العربية', 'ar', isArabic),
          ],
        ),
      ),
    );
  }

  Widget _segment(String text, String code, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? VeloraColors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: VeloraText.body(
              12.5,
              weight: FontWeight.w700,
              color: selected ? VeloraColors.amberInk : const Color(0xFFCFE2DC),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Face ID states
// ---------------------------------------------------------------------------

class _FaceScanPanel extends StatefulWidget {
  const _FaceScanPanel({
    required this.title,
    required this.cancelLabel,
    required this.onCancel,
    required this.troubleLabel,
    required this.onTrouble,
  });

  final String title;
  final String cancelLabel;
  final VoidCallback onCancel;
  final String troubleLabel;
  final VoidCallback onTrouble;

  @override
  State<_FaceScanPanel> createState() => _FaceScanPanelState();
}

class _FaceScanPanelState extends State<_FaceScanPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scan
        ..stop()
        ..value = 0.5;
    } else if (!_scan.isAnimating) {
      _scan.repeat();
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const frame = 150.0;
    const corner = BorderSide(color: VeloraColors.teal, width: 4);

    Widget bracket(AlignmentGeometry at, BorderRadius radius, Border border) =>
        Align(
          alignment: at,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(border: border, borderRadius: radius),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: frame,
            child: Stack(
              children: [
                bracket(
                  Alignment.topLeft,
                  const BorderRadius.only(topLeft: Radius.circular(16)),
                  const Border(left: corner, top: corner),
                ),
                bracket(
                  Alignment.topRight,
                  const BorderRadius.only(topRight: Radius.circular(16)),
                  const Border(right: corner, top: corner),
                ),
                bracket(
                  Alignment.bottomLeft,
                  const BorderRadius.only(bottomLeft: Radius.circular(16)),
                  const Border(left: corner, bottom: corner),
                ),
                bracket(
                  Alignment.bottomRight,
                  const BorderRadius.only(bottomRight: Radius.circular(16)),
                  const Border(right: corner, bottom: corner),
                ),
                const Center(
                  child: VeloraIcon(
                    VeloraIcons.faceIdScan,
                    size: 74,
                    color: Color(0xFF9FC3B8),
                    strokeWidth: 1.4,
                  ),
                ),
                AnimatedBuilder(
                  animation: _scan,
                  builder: (context, _) {
                    // Sweep down and back up, like `@keyframes scan`.
                    final t = Curves.easeInOut.transform(
                      _scan.value < 0.5
                          ? _scan.value * 2
                          : 2 - _scan.value * 2,
                    );
                    return Positioned(
                      left: 12,
                      right: 12,
                      top: frame * (0.14 + 0.66 * t),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: VeloraColors.amber,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: VeloraColors.amber.withValues(alpha: 0.55),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(widget.title, style: VeloraText.display(20)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(widget.cancelLabel, style: VeloraText.link),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: widget.onTrouble,
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(
                  widget.troubleLabel,
                  style: VeloraText.link.copyWith(color: VeloraColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaceFailPanel extends StatelessWidget {
  const _FaceFailPanel({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.retryIcon,
    this.calm = false,
    required this.otherLabel,
    required this.otherIcon,
    required this.onOther,
  });

  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback onRetry;
  final VeloraIcons? retryIcon;

  /// Informational rather than an error: mint tile, no shake.
  final bool calm;
  final String otherLabel;
  final VeloraIcons otherIcon;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: calm || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 500),
            builder: (context, t, child) => Transform.translate(
              // Decaying side-to-side shake.
              offset: Offset(8 * (1 - t) * math.sin(t * 4 * math.pi), 0),
              child: child,
            ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: calm ? VeloraColors.mint : VeloraColors.dangerBg,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: VeloraIcon(
                VeloraIcons.faceId,
                size: 38,
                color: calm ? VeloraColors.teal : VeloraColors.dangerText,
                strokeWidth: 1.7,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: VeloraText.display(22),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: VeloraText.body(14, color: VeloraColors.muted)
              .copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        if (retryLabel != null) ...[
          _SignInButton(label: retryLabel!, icon: retryIcon, onPressed: onRetry),
          const SizedBox(height: 12),
        ],
        _SignInButton(
          label: otherLabel,
          icon: otherIcon,
          variant: retryLabel == null
              ? VeloraButtonVariant.primary
              : VeloraButtonVariant.ghost,
          onPressed: onOther,
        ),
      ],
    );
  }
}

class _RememberMeTile extends StatelessWidget {
  const _RememberMeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
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
                label,
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

/// "Sign in faster next time?" — offered after a sign-in while Face ID is off.
class _FaceSetupPanel extends StatelessWidget {
  const _FaceSetupPanel({
    required this.title,
    required this.message,
    required this.turnOnLabel,
    required this.notNowLabel,
    required this.onTurnOn,
    required this.onNotNow,
  });

  final String title;
  final String message;
  final String turnOnLabel;
  final String notNowLabel;
  final VoidCallback onTurnOn;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: VeloraColors.brand,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x400F4A41),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const VeloraIcon(
                VeloraIcons.faceIdScan,
                size: 44,
                color: Colors.white,
                strokeWidth: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: VeloraText.display(23)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: VeloraText.body(14, color: VeloraColors.muted)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
          _SignInButton(label: turnOnLabel, big: true, onPressed: onTurnOn),
          _LinkButton(label: notNowLabel, onPressed: onNotNow),
        ],
      ),
    );
  }
}

/// "You're in" with the drawn circle-and-tick from the design.
class _DonePanel extends StatelessWidget {
  const _DonePanel({
    required this.title,
    required this.message,
    required this.goLabel,
    required this.onGo,
  });

  final String title;
  final String message;
  final String goLabel;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 950),
              builder: (context, t, _) => CustomPaint(
                size: const Size.square(86),
                painter: _DoneTickPainter(t),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: VeloraText.display(24)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: VeloraText.body(14, color: VeloraColors.muted),
          ),
          const SizedBox(height: 18),
          _SignInButton(
            label: goLabel,
            icon: VeloraIcons.chevronRight,
            onPressed: onGo,
          ),
        ],
      ),
    );
  }
}

class _DoneTickPainter extends CustomPainter {
  _DoneTickPainter(this.t);

  /// 0–1: the circle draws over the first 60%, the tick over the rest.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 52;
    canvas.scale(s);
    final circle = Curves.easeOut.transform((t / 0.63).clamp(0.0, 1.0));
    final tick = Curves.easeOut.transform(((t - 0.53) / 0.47).clamp(0.0, 1.0));

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(26, 26), radius: 24),
      -math.pi / 2,
      2 * math.pi * circle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = VeloraColors.teal,
    );
    if (tick <= 0) return;
    final path = Path()
      ..moveTo(15, 27)
      ..lineTo(22.5, 34.5)
      ..lineTo(37, 19);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * tick),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = VeloraColors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _DoneTickPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// The sign-in sheet's `.btn` / `.btn.ghost` from the design: 54 px tall
/// (58 for the main action), radius 15, 15.5 px bold label, 19 px icon in
/// amber (teal on ghost).
class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = VeloraButtonVariant.primary,
    this.big = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final VeloraIcons? icon;
  final VeloraButtonVariant variant;
  final bool big;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ghost = variant == VeloraButtonVariant.ghost;
    final enabled = onPressed != null && !isLoading;
    final bg = ghost
        ? Colors.white
        : (enabled || isLoading ? VeloraColors.brand : VeloraColors.disabled);
    final fg = ghost ? VeloraColors.ink : Colors.white;
    final radius = BorderRadius.circular(15);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: ghost
              ? const BorderSide(color: VeloraColors.fieldBorder)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: big ? 58 : 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            VeloraIcon(
                              icon!,
                              size: 19,
                              color: ghost
                                  ? VeloraColors.teal
                                  : VeloraColors.amber,
                              strokeWidth: 1.9,
                            ),
                            const SizedBox(width: 9),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: VeloraText.body(
                                15.5,
                                weight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The white VELORA logo with the design's
/// `drop-shadow(0 12px 28px rgba(0,0,0,.35))`.
class _ShadowedLogo extends StatelessWidget {
  const _ShadowedLogo();

  static const _asset = 'assets/images/brand/velora_logo_light.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(0, 12),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const ColorFiltered(
                colorFilter: ColorFilter.mode(Color(0x59000000), BlendMode.srcIn),
                child: Image(image: AssetImage(_asset), width: 250),
              ),
            ),
          ),
        ),
        Image.asset(_asset, width: 250, semanticLabel: 'VELORA'),
      ],
    );
  }
}
