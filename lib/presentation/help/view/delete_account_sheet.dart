import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/navigation/root_navigator.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../widgets/velora/velora.dart';

/// "Delete my account" (Profile → Privacy) — `DELETE /account`, required by
/// the App Store and Google Play (MOBILE_API_VELORA.md §10a).
///
/// Two steps: a "This can't be undone" confirmation, then the current
/// password. On success [AuthCubit.deleteAccount] clears the phone and the
/// session handler returns the app to sign-in.
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VeloraRadii.sheet)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: const DeleteAccountSheet(),
      ),
    );
  }

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _confirmed = false;
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final message = await context.read<AuthCubit>().deleteAccount(password: _password.text);
      // The session handler has already cleared the screens (this sheet
      // included), so the toast goes through the root navigator.
      final root = rootNavigatorKey.currentContext;
      if (root != null && root.mounted) showVeloraToast(root, message);
    } on ValidationException catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = error.errors['password']?.firstOrNull ?? apiErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_deleting,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 16),
              const Center(
                child: IconTile(
                  VeloraIcons.warning,
                  tone: IconTileTone.danger,
                  size: 56,
                  iconSize: 26,
                  radius: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('Delete your account?'),
                textAlign: TextAlign.center,
                style: VeloraText.display(20),
              ),
              const SizedBox(height: 8),
              if (!_confirmed) ..._confirmStep() else ..._passwordStep(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _confirmStep() => [
        Text(
          tr('This can\'t be undone. You will be signed out everywhere and your personal details will be erased.'),
          textAlign: TextAlign.center,
          style: VeloraText.body(14, color: VeloraColors.muted, height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          tr('Visit, pay and check-in records are kept without your name, because healthcare and payroll rules require it.'),
          textAlign: TextAlign.center,
          style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        VeloraButton(
          label: tr('Continue'),
          variant: VeloraButtonVariant.danger,
          onPressed: () => setState(() => _confirmed = true),
        ),
        const SizedBox(height: 10),
        VeloraButton(
          label: tr('Cancel'),
          variant: VeloraButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

  List<Widget> _passwordStep() => [
        Text(
          tr('Enter your password to confirm.'),
          textAlign: TextAlign.center,
          style: VeloraText.body(14, color: VeloraColors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        VeloraTextField(
          label: tr('Password'),
          controller: _password,
          obscureText: true,
          enabled: !_deleting,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) {
            if (_password.text.isNotEmpty && !_deleting) _delete();
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: VeloraText.body(12, color: VeloraColors.dangerText)),
        ],
        const SizedBox(height: 18),
        VeloraButton(
          label: tr('Delete my account'),
          variant: VeloraButtonVariant.danger,
          isLoading: _deleting,
          onPressed: _password.text.isEmpty ? null : _delete,
        ),
        const SizedBox(height: 10),
        VeloraButton(
          label: tr('Cancel'),
          variant: VeloraButtonVariant.ghost,
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
        ),
      ];
}
