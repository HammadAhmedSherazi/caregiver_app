import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/task_cubit.dart';
import '../widgets/compliance_form_widgets.dart';
import '../widgets/task_cards.dart';
import '../widgets/task_primary_button.dart';
import '../widgets/task_screen_header.dart';
import '../widgets/task_success_sheet.dart';

class ComplianceFormView extends StatefulWidget {
  const ComplianceFormView({
    super.key,
    this.formId,
    required this.title,
    this.questions = const [],
    this.isMonthly = false,
    this.heroTitle,
    this.heroSubtitle,
    this.sectionLabel,
  });

  final int? formId;
  final String title;
  final List<ComplianceQuestion> questions;
  final bool isMonthly;
  final String? heroTitle;
  final String? heroSubtitle;
  final String? sectionLabel;

  @override
  State<ComplianceFormView> createState() => _ComplianceFormViewState();
}

class _ComplianceFormViewState extends State<ComplianceFormView> {
  late List<ComplianceQuestion> _questions;
  final _notesController = TextEditingController();
  String? _signatureBase64;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _loadFailed = false;

  static const _headerHeight = 209.0;
  static const _heroOverlap = 32.0;
  static const _placeholderSignature =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  bool get _hasSignature => _signatureBase64 != null;

  @override
  void initState() {
    super.initState();
    _questions = List.of(widget.questions);
    if (widget.formId != null && _questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForm());
    }
  }

  Future<void> _loadForm() async {
    final formId = widget.formId;
    if (formId == null) return;

    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final questions =
          await context.read<TaskCubit>().loadComplianceForm(formId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final allAnswered = _questions.every((q) => q.selectedYes != null);
    return allAnswered && _hasSignature && !_isSubmitting;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final formId = widget.formId;
    if (formId != null) {
      setState(() => _isSubmitting = true);
      try {
        final answers = {
          for (final question in _questions) question.id: question.selectedYes!,
        };
        await context.read<TaskCubit>().submitComplianceForm(
              formId: formId,
              answers: answers,
              signature: _signatureBase64!,
              additionalNotes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
        if (!mounted) return;
        _showSuccessSheet();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to submit form. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }

    _showSuccessSheet();
  }

  void _showSuccessSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TaskSuccessSheet(
          title: widget.isMonthly
              ? 'Compliance submitted'
              : 'Form submitted',
          message: widget.isMonthly
              ? 'Your monthly compliance form has been submitted successfully.'
              : 'Your form has been submitted successfully.',
          primaryLabel: 'Done',
          onPrimary: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pop(true);
          },
          showSummary: widget.isMonthly,
          summaryRows: widget.isMonthly
              ? [
                  MapEntry('Form', widget.title),
                  MapEntry('Status', 'Submitted'),
                ]
              : const [],
        );
      },
    );
  }

  void _captureSignature() {
    setState(() => _signatureBase64 = _placeholderSignature);
  }

  void _clearSignature() {
    setState(() => _signatureBase64 = null);
  }

  void _updateQuestion(String id, bool value) {
    setState(() {
      final index = _questions.indexWhere((q) => q.id == id);
      if (index >= 0) {
        _questions[index] = _questions[index].copyWith(selectedYes: value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadFailed) {
      return Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskScreenHeader(
              title: widget.title,
              onBack: () => Navigator.of(context).pop(),
              height: 160,
            ),
            Expanded(
              child: GetRequestView(
                isLoading: _isLoading,
                hasError: _loadFailed,
                onRetry: _loadForm,
                skeleton: const TaskTabSkeleton(),
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isMonthly) {
      return _buildMonthlyForm(context);
    }
    return _buildSimpleForm(context);
  }

  Widget _buildMonthlyForm(BuildContext context) {
    if (_questions.isEmpty) {
      return _buildEmptyForm(context);
    }

    final sectionLabel = widget.sectionLabel ?? widget.title;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskScreenHeader(
                title: widget.title,
                subtitle: "Certify last month's services",
                onBack: () => Navigator.of(context).pop(),
                height: _headerHeight,
              ),
              VerticalOverlap(
                overlap: _heroOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ComplianceFormHeroCard(
                    title: widget.heroTitle ?? widget.title,
                    subtitle: widget.heroSubtitle ??
                        'Complete all required fields before submitting',
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
              children: [
                Text(
                  sectionLabel,
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.homeDarkText,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                for (var i = 0; i < _questions.length; i++) ...[
                  ComplianceQuestionCard(
                    question: _questions[i],
                    onChanged: (value) => _updateQuestion(_questions[i].id, value),
                  ),
                  if (i < _questions.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 24),
                ComplianceNotesSection(controller: _notesController),
                const SizedBox(height: 24),
                ComplianceSignatureCard(
                  hasSignature: _hasSignature,
                  onSign: _captureSignature,
                  onClear: _clearSignature,
                ),
                const SizedBox(height: 32),
                TaskPrimaryButton(
                  label: _isSubmitting ? 'Submitting...' : 'Submit form',
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleForm(BuildContext context) {
    if (_questions.isEmpty) {
      return _buildEmptyForm(context);
    }

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskScreenHeader(
            title: widget.title,
            onBack: () => Navigator.of(context).pop(),
            height: 160,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                for (final question in _questions) ...[
                  _SimpleQuestionCard(
                    question: question,
                    onChanged: (value) => _updateQuestion(question.id, value),
                  ),
                  const SizedBox(height: 16),
                ],
                _SimpleSignatureCard(
                  hasSignature: _hasSignature,
                  onTap: _captureSignature,
                ),
                const SizedBox(height: 24),
                TaskPrimaryButton(
                  label: _isSubmitting ? 'Submitting...' : 'Submit',
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyForm(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskScreenHeader(
            title: widget.title,
            onBack: () => Navigator.of(context).pop(),
            height: 160,
          ),
          Expanded(
            child: Center(
              child: Text(
                'No form data available',
                style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleQuestionCard extends StatelessWidget {
  const _SimpleQuestionCard({
    required this.question,
    required this.onChanged,
  });

  final ComplianceQuestion question;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: taskCardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: context.responsiveStyle(AppTextStyles.homeCardTitle),
          ),
          const SizedBox(height: 16),
          TaskYesNoToggle(
            selectedYes: question.selectedYes,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SimpleSignatureCard extends StatelessWidget {
  const _SimpleSignatureCard({
    required this.hasSignature,
    required this.onTap,
  });

  final bool hasSignature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSignature
                ? AppColors.homePrimary
                : AppColors.homeDialogDivider,
            width: hasSignature ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            hasSignature ? 'Signature captured' : 'Tap to sign',
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
          ),
        ),
      ),
    );
  }
}
