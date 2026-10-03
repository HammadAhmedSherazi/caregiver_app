import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_error_message.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';
import 'delete_account_sheet.dart';

/// Privacy: static explanation of what the app keeps.
///
/// "Get a copy of my information" → `POST /privacy/data-request`
/// (live, Group 1) when `ApiConfig.veloraGroup1Enabled`; otherwise it
/// explains the request can't be sent from the app yet.
///
/// "Delete my account" → `DELETE /account` via [DeleteAccountSheet]
/// (App Store / Google Play requirement), behind the same flag.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  Future<void> _requestCopy(BuildContext context) async {
    if (!ApiConfig.veloraGroup1Enabled) {
      await showApiRequiredSheet(
        context,
        feature: tr('Information requests'),
        onContactOffice: () => AppNavigator.openInbox(context),
      );
      return;
    }
    try {
      final result = await sl<ProfileRepository>().requestDataCopy();
      if (context.mounted) showVeloraToast(context, result.message);
    } catch (error) {
      if (context.mounted) showVeloraToast(context, apiErrorMessage(error));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (!ApiConfig.veloraGroup1Enabled) {
      await showApiRequiredSheet(
        context,
        feature: tr('Account deletion'),
        onContactOffice: () => AppNavigator.openInbox(context),
      );
      return;
    }
    await DeleteAccountSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        VeloraIcons.pin,
        'Your location, only when you clock in or out',
        'Used for visit verification. The app does not track you during the day or off the clock.',
      ),
      (
        VeloraIcons.clock,
        'Your visit times and answers',
        'Clock-in and clock-out times, tasks, and your check-in answers.',
      ),
      (
        VeloraIcons.documentPlain,
        'Documents you send',
        'Stored in your employee file at the office.',
      ),
    ];

    return VeloraScaffold(
      body: VeloraPage(
        header: VeloraHeader(
          title: tr('Privacy'),
          subtitle: tr('What the app keeps, and who sees it'),
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          VeloraCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCaption(tr('What the app collects'), padding: EdgeInsets.only(bottom: 6)),
                for (var i = 0; i < rows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: i > 0 ? const Border(top: BorderSide(color: VeloraColors.line)) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(rows[i].$1, size: 36, iconSize: 17, radius: 11),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr(rows[i].$2), style: VeloraText.body(14, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(tr(rows[i].$3),
                                  style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          VeloraCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCaption(tr('Who sees it')),
                const SizedBox(height: 8),
                Text(
                  tr('The office you work for, and the state or insurance programs that pay for your client\'s care. Your information is not sold or shared with advertisers.'),
                  style: VeloraText.body(13.5, color: VeloraColors.body, height: 1.5),
                ),
              ],
            ),
          ),
          VeloraButton(
            label: tr('Get a copy of my information'),
            icon: VeloraIcons.download,
            variant: VeloraButtonVariant.ghost,
            onPressed: () => _requestCopy(context),
          ),
          Center(
            child: VeloraTextLink(
              label: tr('Question about privacy? Message the office'),
              size: 13.5,
              onTap: () => AppNavigator.openInbox(context),
            ),
          ),
          Center(
            child: VeloraTextLink(
              label: tr('Delete my account'),
              size: 13.5,
              color: VeloraColors.dangerText,
              onTap: () => _deleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }
}
