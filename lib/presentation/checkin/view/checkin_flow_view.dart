import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_config.dart';
import '../../../data/models/task_page_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

/// Monthly sign-off: questions → review & sign → sent.
///
/// Uses `GET /compliance-forms/{id}` for the questions and
/// `POST /compliance-forms/{id}/submit` with the answers, the typed signature
/// (rendered as a PNG data URI, the format the endpoint already receives)
/// and optional notes.
///
/// The design's "Your days" calendar step is not included: there is no API
/// for per-day worked / hospital marks (API REQUIRED).
class CheckInFlowView extends StatefulWidget {
  const CheckInFlowView({
    super.key,
    required this.formId,
    required this.periodLabel,
  });

  final int formId;
  final String periodLabel;

  @override
  State<CheckInFlowView> createState() => _CheckInFlowViewState();
}

class _CheckInFlowViewState extends State<CheckInFlowView> {
  static const _stepCount = 2;

  int _step = 0; // 0 questions, 1 sign, 2 done
  List<ComplianceQuestion> _questions = const [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;
  bool _agree = false;
  final _notesController = TextEditingController();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<AuthCubit>().state.user?.name ?? '',
    );
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final questions = await context.read<TaskCubit>().loadComplianceForm(widget.formId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  bool get _allAnswered => _questions.every((q) => q.selectedYes != null);
  bool get _canSubmit => _agree && _nameController.text.trim().length >= 2;

  void _answer(ComplianceQuestion question, bool value) {
    setState(() {
      _questions = [
        for (final q in _questions) q.id == question.id ? q.copyWith(selectedYes: value) : q,
      ];
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    try {
      final signature = await _renderSignature(_nameController.text.trim());
      if (!mounted) return;
      final notes = _notesController.text.trim();
      await context.read<TaskCubit>().submitComplianceForm(
            formId: widget.formId,
            answers: {for (final q in _questions) q.id: q.selectedYes!},
            signature: signature,
            additionalNotes: notes.isEmpty ? null : notes,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = 2;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showVeloraToast(context, tr('We couldn\'t send your check-in. Please try again.'));
    }
  }

  /// Draws the typed name onto a transparent PNG and returns a data URI.
  static Future<String> _renderSignature(String name) async {
    const width = 600.0;
    const height = 160.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          fontFamily: VeloraFonts.display,
          fontSize: 56,
          fontWeight: FontWeight.w600,
          color: VeloraColors.brand,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width - 40);
    painter.paint(canvas, Offset(20, (height - painter.height) / 2));
    final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return 'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
  }

  void _close([bool submitted = false]) => Navigator.of(context).pop(submitted);

  @override
  Widget build(BuildContext context) {
    final inFlow = _step < 2;
    final title = switch (_step) {
      0 => tr('A few questions'),
      1 => tr('Review & sign'),
      _ => tr('All done'),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _submitting) return;
        switch (_step) {
          case 0:
            _close();
          case 1:
            setState(() => _step = 0);
          default:
            _close(true);
        }
      },
      child: VeloraScaffold(
        body: VeloraPage(
          header: VeloraHeader(
            title: title,
            subtitle: _step == 2
                ? tr('{0} · sent to the office', [widget.periodLabel])
                : tr('{0} check-in', [widget.periodLabel]),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            leading: inFlow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('STEP {0} OF {1}', [_step + 1, _stepCount]),
                              style: VeloraText.body(
                                12.5,
                                weight: FontWeight.w700,
                                color: VeloraColors.amber,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              onTap: _submitting ? null : () => _close(),
                              borderRadius: BorderRadius.circular(11),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Text(
                                  tr('Exit'),
                                  style: VeloraText.body(13, weight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VeloraProgressBar(
                        value: (_step + 1) / _stepCount,
                        height: 6,
                        color: VeloraColors.amber,
                        track: Colors.white.withValues(alpha: 0.14),
                      ),
                    ],
                  )
                : null,
          ),
          footer: inFlow && !_loading && !_loadFailed ? _footer() : null,
          children: _body(),
        ),
      ),
    );
  }

  Widget _footer() {
    final blocked = _step == 0 ? !_allAnswered : !_canSubmit;
    final nextLabel = _step == 0
        ? (blocked ? tr('Answer all {0} to continue', [_questions.length]) : tr('Continue'))
        : (blocked ? tr('Confirm and sign to submit') : tr('Submit check-in'));

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: VeloraButton(
            label: tr('Back'),
            variant: VeloraButtonVariant.ghost,
            onPressed: _submitting
                ? null
                : () => _step == 0 ? _close() : setState(() => _step = 0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: VeloraButton(
            label: nextLabel,
            isLoading: _submitting,
            onPressed: blocked
                ? null
                : (_step == 0 ? () => setState(() => _step = 1) : _submit),
          ),
        ),
      ],
    );
  }

  List<Widget> _body() {
    if (_loading) return [VeloraLoadingState(message: tr('Loading your check-in…'))];
    if (_loadFailed) {
      return [
        VeloraErrorState(
          message: tr('We couldn\'t load this check-in.'),
          onRetry: _load,
        ),
      ];
    }

    switch (_step) {
      case 0:
        return [
          if (_questions.isEmpty)
            VeloraEmptyState(
              title: tr('No questions this time'),
              message: tr('Continue to review and sign.'),
              icon: VeloraIcons.clipboardCheck,
            ),
          for (final question in _questions)
            VeloraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(question.prompt, style: VeloraText.body(15, weight: FontWeight.w700, height: 1.4)),
                  const SizedBox(height: 12),
                  YesNoToggle(
                    value: question.selectedYes,
                    onChanged: (v) => _answer(question, v),
                  ),
                ],
              ),
            ),
          VeloraCard(
            child: VeloraTextField(
              controller: _notesController,
              label: tr('Anything else the office should know?'),
              hint: tr('Optional'),
              maxLines: 4,
              minLines: 3,
            ),
          ),
        ];
      case 1:
        final yes = _questions.where((q) => q.selectedYes == true).length;
        return [
          VeloraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                KeyValueRow(showDivider: false, label: tr('Period'), value: widget.periodLabel),
                KeyValueRow(label: tr('Questions answered'), value: '${_questions.length}'),
                KeyValueRow(
                  label: tr('Answers'),
                  value: yes == 0 ? tr('All no') : tr('{0} yes', [yes]),
                ),
                if (_notesController.text.trim().isNotEmpty)
                  KeyValueRow(label: tr('Notes'), value: tr('Added')),
              ],
            ),
          ),
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _agree = !_agree),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agree,
                          activeColor: VeloraColors.brand,
                          onChanged: (v) => setState(() => _agree = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('I confirm the care I\'ve reported for {0} is true and accurate.', [widget.periodLabel]),
                          style: VeloraText.body(14, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tr('Type your full name to sign'),
                  style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  style: VeloraText.display(20, weight: FontWeight.w600, color: VeloraColors.brand),
                  decoration: VeloraTextField.decoration(hint: tr('Your full name')),
                ),
              ],
            ),
          ),
        ];
      default:
        return [
          VeloraDoneCard(
            title: tr('Check-in sent'),
            message: tr('Thanks. The office has your {0} check-in.', [widget.periodLabel]),
            // The receipt is `GET /compliance-forms/{id}/receipt` (🚧 planned):
            // only claim a saved copy when that API is on; the link itself
            // shows the viewer's "not connected yet" message while it is off.
            details: ApiConfig.veloraApiEnabled
                ? KeyValueRow(
                    showDivider: false,
                    label: tr('Copy saved'),
                    value: tr('Docs › From the office'),
                  )
                : null,
            actions: [
              VeloraTextLink(
                label: tr('View my receipt'),
                size: 13.5,
                icon: VeloraIcons.document,
                onTap: () => AppNavigator.openCheckInReceipt(
                  context,
                  formId: widget.formId,
                  periodLabel: widget.periodLabel,
                ),
              ),
            ],
          ),
          VeloraButton(
            label: tr('See my pay'),
            onPressed: () {
              _close(true);
              AppNavigator.selectTab(MainTab.pay);
            },
          ),
          VeloraButton(
            label: tr('Done'),
            variant: VeloraButtonVariant.ghost,
            onPressed: () => _close(true),
          ),
        ];
    }
  }
}
