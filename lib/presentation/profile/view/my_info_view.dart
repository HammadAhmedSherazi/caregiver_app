import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/profile_cubit.dart';

/// "My info" form, pre-filled from `GET /me`.
///
/// UI ONLY — API REQUIRED: there is no endpoint to submit contact or
/// emergency-contact changes, so "Send changes" explains that instead of
/// pretending to send. Bank changes go through the existing document upload.
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

  @override
  void initState() {
    super.initState();
    final data = context.read<ProfileCubit>().state.data;
    _phone = TextEditingController(text: data?.phone ?? '');
    _email = TextEditingController(text: data?.email ?? '');
    _address = TextEditingController(text: data?.address ?? '');
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
          title: 'My info',
          subtitle: 'Changes go to the office to approve',
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionCaption('How we reach you'),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: 'Mobile phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: 'Home address',
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
                const SectionCaption('Emergency contact'),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: 'Name',
                  controller: _emergencyName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                VeloraTextField(
                  label: 'Phone',
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
                const SectionCaption('Direct deposit'),
                const SizedBox(height: 10),
                Text(
                  'To change your bank, send a photo of a voided check or a new direct deposit form. '
                  'Your pay stays with the old account until the office confirms.',
                  style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VeloraTextLink(
                    label: 'Upload a new direct deposit form',
                    size: 13.5,
                    icon: VeloraIcons.camera,
                    onTap: () => AppNavigator.openUpload(context, initialType: 'tax'),
                  ),
                ),
              ],
            ),
          ),
          VeloraButton(
            label: 'Send changes to office',
            onPressed: () => showApiRequiredSheet(
              context,
              feature: 'Profile changes',
              onContactOffice: () => AppNavigator.openInbox(context),
            ),
          ),
        ],
      ),
    );
  }
}
