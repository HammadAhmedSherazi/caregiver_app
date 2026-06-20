import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'privacy_terms_view.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key, required this.flowData});

  final SignupFlowData flowData;

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ssnController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _nameController.dispose();
    _ssnController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().completeRegistration(
          email: widget.flowData.email,
          fullName: _nameController.text.trim(),
          ssnLast4: _ssnController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

    if (!mounted || !success) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: PrivacyTermsView(flowData: widget.flowData),
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
                      'Registration',
                      style: AppTextStyles.authTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 39),
                    AuthTextField(
                      hint: 'Enter Full Name',
                      prefixIconAsset: AppAssets.icUser,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          FormValidators.required(value, fieldName: 'Full name'),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Last 4digitof SSN',
                      controller: _ssnController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: FormValidators.ssnLast4,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Date of birth',
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      validator: (value) =>
                          FormValidators.required(value, fieldName: 'Date of birth'),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hint: 'Primary Phone No',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSubmit(),
                      validator: FormValidators.phone,
                    ),
                    const SizedBox(height: 32),
                    AuthPrimaryButton(
                      label: 'Complete Registration',
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
