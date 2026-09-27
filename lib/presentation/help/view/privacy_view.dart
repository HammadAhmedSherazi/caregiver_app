import 'package:flutter/material.dart';

import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';

/// Privacy: static explanation of what the app keeps.
///
/// "Get a copy of my information" has no endpoint (API REQUIRED).
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

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
          title: 'Privacy',
          subtitle: 'What the app keeps, and who sees it',
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          VeloraCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionCaption('What the app collects', padding: EdgeInsets.only(bottom: 6)),
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
                              Text(rows[i].$2, style: VeloraText.body(14, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(rows[i].$3,
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
                const SectionCaption('Who sees it'),
                const SizedBox(height: 8),
                Text(
                  'The office you work for, and the state or insurance programs that pay for your '
                  'client\'s care. Your information is not sold or shared with advertisers.',
                  style: VeloraText.body(13.5, color: VeloraColors.body, height: 1.5),
                ),
              ],
            ),
          ),
          VeloraButton(
            label: 'Get a copy of my information',
            icon: VeloraIcons.download,
            variant: VeloraButtonVariant.ghost,
            onPressed: () => showApiRequiredSheet(
              context,
              feature: 'Information requests',
              onContactOffice: () => AppNavigator.openInbox(context),
            ),
          ),
          Center(
            child: VeloraTextLink(
              label: 'Question about privacy? Message the office',
              size: 13.5,
              onTap: () => AppNavigator.openInbox(context),
            ),
          ),
        ],
      ),
    );
  }
}
