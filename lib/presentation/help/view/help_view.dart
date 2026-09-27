import 'package:flutter/material.dart';

import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../widgets/velora/velora.dart';

class _Faq {
  const _Faq(this.question, this.answer, this.action, this.onGo);

  final String question;
  final String answer;
  final String action;
  final void Function(BuildContext context) onGo;
}

/// Help & questions: static answers, each linking to the screen that helps.
class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  int? _open;

  static final _faqs = [
    _Faq(
      'I forgot to clock out',
      'Open Time, find the day marked "No clock-out" and add the time you left. The office reviews it, usually within 1 business day.',
      'Open Time',
      (c) => AppNavigator.goToTab(c, MainTab.time),
    ),
    _Faq(
      'When do I get paid?',
      'Once your monthly check-in is signed, the office confirms your days and pays you by direct deposit on the next payday. Your paystubs are in Pay.',
      'See my pay',
      (c) => AppNavigator.goToTab(c, MainTab.pay),
    ),
    _Faq(
      'What is the monthly sign-off?',
      'A quick review of the month you just worked: answer a few questions and sign. It is what releases your pay.',
      'Go to check-in',
      (c) => AppNavigator.goToTab(c, MainTab.checkIn),
    ),
    _Faq(
      'My client went to the hospital',
      'Do not clock in while your client is admitted. Tell the office the dates so those days are taken off your time.',
      'Report a change',
      (c) => AppNavigator.openReportChange(c),
    ),
    _Faq(
      'How do I send the office a document?',
      'Go to Docs and tap Upload. Take a photo or pick a file and it goes straight to your file at the office.',
      'Upload a document',
      (c) => AppNavigator.openUpload(c),
    ),
    _Faq(
      'How do I update my phone or address?',
      'Open your profile and tap Update my info, or message the office.',
      'Open profile',
      (c) => AppNavigator.openProfile(c),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return VeloraScaffold(
      body: VeloraPage(
        gap: 12,
        header: VeloraHeader(
          title: 'Help & questions',
          subtitle: 'We\'re here to help',
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          Material(
            color: VeloraColors.brand,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => AppNavigator.openInbox(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const VeloraIcon(VeloraIcons.message, size: 22, color: VeloraColors.amber, strokeWidth: 2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Message the office',
                          style: VeloraText.body(15, weight: FontWeight.w700, color: Colors.white)),
                    ),
                    const VeloraIcon(VeloraIcons.chevronRight, size: 16, color: Colors.white, strokeWidth: 2.2),
                  ],
                ),
              ),
            ),
          ),
          VeloraCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionCaption('Common questions', padding: EdgeInsets.only(top: 8, bottom: 6)),
                for (var i = 0; i < _faqs.length; i++) _item(i),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  'Emergency with your client? Call 911 first, then tell us in',
                  textAlign: TextAlign.center,
                  style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.5),
                ),
                VeloraTextLink(
                  label: 'Report a change',
                  onTap: () => AppNavigator.openReportChange(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final faq = _faqs[i];
    final open = _open == i;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: VeloraColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: () => setState(() => _open = open ? null : i),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(faq.question, style: VeloraText.body(14.5, weight: FontWeight.w600)),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const VeloraIcon(
                          VeloraIcons.chevronRight,
                          size: 16,
                          color: VeloraColors.chevron,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.answer, style: VeloraText.body(13.5, color: VeloraColors.body, height: 1.5)),
                  const SizedBox(height: 8),
                  Material(
                    color: VeloraColors.mint,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: () => faq.onGo(context),
                      borderRadius: BorderRadius.circular(11),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        child: Text(faq.action,
                            style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.brandDark)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
