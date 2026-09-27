import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_error_message.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/profile_cubit.dart';
import '../../../core/i18n/tr.dart';

/// "My info" form, pre-filled from `GET /me`.
///
/// Sends `POST /me/info-change` (🚧 PLANNED — NOT LIVE) when
/// `ApiConfig.veloraApiEnabled`; otherwise "Send changes" explains the
/// endpoint isn't available. Only changed fields are sent, and the profile
/// is **not** updated locally — the change stays pending until the office
/// approves. Bank changes go through the document upload.
class MyInfoView extends StatefulWidget {
  const MyInfoView({super.key});

  @override
  State<MyInfoView> createState() => _MyInfoViewState();
}

class _MyInfoViewState extends State<MyInfoView> {
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  late final String _initialPhone;
  late final String _initialEmail;
  late final String _initialAddress;
  bool _sending = false;

  String? _changed(TextEditingController c, String initial) =>
      c.text.trim() == initial.trim() ? null : c.text;

  Future<void> _send() async {
    if (!ApiConfig.veloraApiEnabled) {
      await showApiRequiredSheet(
        context,
        feature: tr('Profile changes'),
        onContactOffice: () => AppNavigator.openInbox(context),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await sl<ProfileRepository>().requestInfoChange(
        InfoChangeRequest(
          mobile: _changed(_phone, _initialPhone),
          email: _changed(_email, _initialEmail),
          address: _changed(_address, _initialAddress),
          emergencyContact: EmergencyContactModel(
            name: _emergencyName.text,
            phone: _emergencyPhone.text,
          ),
        ),
      );
      if (!mounted) return;
      // Pending until the office approves — the live profile is unchanged.
      showVeloraToast(
        context,
        [result.message, result.change.reviewEta].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showVeloraToast(context, apiErrorMessage(error));
    }
  }

  @override
  void initState() {
    super.initState();
    final data = context.read<ProfileCubit>().state.data;
    _phone = TextEditingController(text: data?.phone ?? '');
    _email = TextEditingController(text: data?.email ?? '');
    _address = TextEditingController(text: data?.address ?? '');
    _initialPhone = _phone.text;
    _initialEmail = _email.text;
    _initialAddress = _address.text;
  }

  @override
  void dispose() {
    for (final c in [_phone, _email, _address, _emergencyName, _emergencyPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VeloraScaffold(
      body: VeloraPage(
        header: VeloraHeader(
          title: tr('My info'),
          subtitle: tr('Changes go to the office to approve'),
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCaption(tr('How we reach you')),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: tr('Mobile phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: tr('Email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: tr('Home address'),
                  controller: _address,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
          ),
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCaption(tr('Emergency contact')),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: tr('Name'),
                  controller: _emergencyName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: tr('Phone'),
                  controller: _emergencyPhone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCaption(tr('Direct deposit')),
                const SizedBox(height: 10),
                Text(
                  tr('To change your bank, send a photo of a voided check or a new direct deposit form. Your pay stays with the old account until the office confirms.'),
                  style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VeloraTextLink(
                    label: tr('Upload a new direct deposit form'),
                    size: 13.5,
                    icon: VeloraIcons.camera,
                    onTap: () => AppNavigator.openUpload(context, initialType: 'tax', directDeposit: true),
                  ),
                ),
              ],
            ),
          ),
          VeloraButton(
            label: tr('Send changes to office'),
            isLoading: _sending,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
