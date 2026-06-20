import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../data/models/home_dashboard_model.dart';
import '../home_icon_box.dart';
import '../home_svg_icon.dart';
import 'shift_flow_sheet_scaffold.dart';

/// Runs the full Figma clock-in wizard (nodes `1:1547` → `1:1858`).
class ClockInFlow {
  ClockInFlow._();

  static Future<ClockInFlowResult?> run(
    BuildContext context, {
    required ActiveShift shift,
  }) async {
    final data = _FlowData(shift: shift);

    if (!await _ShiftDetailsSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    if (!await _SelectClientSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    if (!await _ConfirmVisitDetailsSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    if (!await _VerifyLocationSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    if (!await _ConfirmServiceTypeSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    if (!await _ReadyToClockInSheet.show(context, data)) return null;
    if (!context.mounted) return null;

    return ClockInFlowResult(
      clientName: data.clientName,
      serviceType: data.serviceType,
    );
  }
}

class ClockInFlowResult {
  const ClockInFlowResult({
    required this.clientName,
    required this.serviceType,
  });

  final String clientName;
  final String serviceType;
}

class _FlowData {
  _FlowData({required this.shift}) : serviceType = shift.serviceType;

  final ActiveShift shift;
  int selectedVisitIndex = 0;
  String serviceType;

  String get clientName =>
      shift.assignedVisits[selectedVisitIndex].clientName;

  String get clientInitials =>
      shift.assignedVisits[selectedVisitIndex].initials;
}

// ── Step 1: Shift Details (`1:1547`) ────────────────────────────────────────

class _ShiftDetailsSheet extends StatelessWidget {
  const _ShiftDetailsSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _ShiftDetailsSheet(data: data),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final shift = data.shift;
    final complianceMessage =
        'Your monthly compliance form was signed and uploaded to '
        '${shift.clientName}\'s record.';

    return ShiftFlowSheetScaffold(
      header: _ShiftDetailsHeader(message: complianceMessage),
      body: Column(
        children: [
          _ShiftDetailsClientCard(
            initials: shift.clientInitials,
            name: shift.clientName,
            address: shift.address,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShiftDetailsInfoCard(
                  iconAsset: AppAssets.icHomeClock,
                  label: 'Scheduled',
                  value: shift.scheduledTimeDisplay,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _ShiftDetailsInfoCard(
                  iconAsset: AppAssets.icHomeUserOutline,
                  label: 'Authorized',
                  value: shift.authorizedHours,
                ),
              ),
            ],
          ),
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Continue',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

class _ShiftDetailsHeader extends StatelessWidget {
  const _ShiftDetailsHeader({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Shift details\nConfirm to start',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeAddress),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 306),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
          ),
        ),
      ],
    );
  }
}

class _ShiftDetailsClientCard extends StatelessWidget {
  const _ShiftDetailsClientCard({
    required this.initials,
    required this.name,
    required this.address,
  });

  final String initials;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 23, 17, 23),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.homeSheetDetailsBg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeInitialsBox(initials: initials),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftDetailsInfoCard extends StatelessWidget {
  const _ShiftDetailsInfoCard({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(23, 15, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.homeSheetDetailsBg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSvgIcon(
            asset: iconAsset,
            width: 17,
            height: 17,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.responsiveStyle(AppTextStyles.homeCardTitle),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Select Client (`1:1655`) ────────────────────────────────────────

class _SelectClientSheet extends StatefulWidget {
  const _SelectClientSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _SelectClientSheet(data: data),
    );
    return result == true;
  }

  @override
  State<_SelectClientSheet> createState() => _SelectClientSheetState();
}

class _SelectClientSheetState extends State<_SelectClientSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.data.selectedVisitIndex;
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.data.shift.assignedVisits;

    return ShiftFlowSheetScaffold(
      header: const _SelectClientHeader(),
      body: Column(
        children: [
          for (var i = 0; i < visits.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _SelectClientCard(
              visit: visits[i],
              isSelected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          ],
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Continue',
        onPressed: () {
          widget.data.selectedVisitIndex = _selectedIndex;
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}

class _SelectClientHeader extends StatelessWidget {
  const _SelectClientHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Select assigned client',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeAddress),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 306),
          child: Text(
            'Choose the client you\'re starting a visit with.',
            textAlign: TextAlign.center,
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
          ),
        ),
      ],
    );
  }
}

class _SelectClientCard extends StatelessWidget {
  const _SelectClientCard({
    required this.visit,
    required this.isSelected,
    required this.onTap,
  });

  final AssignedVisit visit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.homeSheetDetailsBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.homeSheetDetailsBg),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 23, 17, 23),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeInitialsBox(
                  initials: visit.initials,
                  backgroundColor: AppColors.surface,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.clientName,
                        style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visit.scheduleLabel,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardSubtitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const HomeSvgIcon(
                    asset: AppAssets.icHomeSelectionCheck,
                    width: 26,
                    height: 26,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Confirm Visit Details (`1:1751`) ────────────────────────────────

class _ConfirmVisitDetailsSheet extends StatelessWidget {
  const _ConfirmVisitDetailsSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _ConfirmVisitDetailsSheet(data: data),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final shift = data.shift;
    final visit = shift.assignedVisits[data.selectedVisitIndex];

    return ShiftFlowSheetScaffold(
      header: const _ConfirmVisitDetailsHeader(),
      body: Column(
        children: [
          _ConfirmVisitDetailsCard(
            clientName: data.clientName,
            visitDate: shift.visitDate,
            scheduledLabel: visit.scheduledLabel,
            serviceType: visit.serviceType,
          ),
          const SizedBox(height: 12),
          _ConfirmVisitLocationBar(address: shift.gpsAddress),
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Looks correct',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

class _ConfirmVisitDetailsHeader extends StatelessWidget {
  const _ConfirmVisitDetailsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Confirm visit details',
      textAlign: TextAlign.center,
      style: context.responsiveStyle(AppTextStyles.homeAddress),
    );
  }
}

class _ConfirmVisitDetailsCard extends StatelessWidget {
  const _ConfirmVisitDetailsCard({
    required this.clientName,
    required this.visitDate,
    required this.scheduledLabel,
    required this.serviceType,
  });

  final String clientName;
  final String visitDate;
  final String scheduledLabel;
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 204,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.homeSheetDetailsBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          _ConfirmVisitDetailRow(label: 'Client', value: clientName),
          const SizedBox(height: 12),
          _ConfirmVisitDetailRow(label: 'Date', value: visitDate),
          const SizedBox(height: 12),
          _ConfirmVisitDetailRow(label: 'Scheduled', value: scheduledLabel),
          const SizedBox(height: 12),
          _ConfirmVisitDetailRow(label: 'Service', value: serviceType),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Authorization',
                style: _labelStyle(context),
              ),
              const Spacer(),
              const ShiftFlowStatusBadge(
                label: 'Active',
                backgroundColor: AppColors.homeVerifiedBg,
                textColor: AppColors.homeVerifiedText,
                iconAsset: AppAssets.icHomeVerified,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.32,
        color: AppColors.homeSheetLabel,
      ),
    );
  }
}

class _ConfirmVisitDetailRow extends StatelessWidget {
  const _ConfirmVisitDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.32,
        color: AppColors.homeSheetLabel,
      ),
    );
    final valueStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.8,
        color: AppColors.homeDarkText,
      ),
    );

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(
          value,
          style: valueStyle,
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ConfirmVisitLocationBar extends StatelessWidget {
  const _ConfirmVisitLocationBar({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.homeSheetDetailsBg),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icHomeLocation,
            width: 12,
            height: 12,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              address,
              style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Verify Location (`1:1977`) ──────────────────────────────────────

class _VerifyLocationSheet extends StatelessWidget {
  const _VerifyLocationSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _VerifyLocationSheet(data: data),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final shift = data.shift;

    return ShiftFlowSheetScaffold(
      header: const _VerifyLocationHeader(),
      body: Column(
        children: [
          _VerifyLocationCard(address: shift.gpsAddress),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 191,
                child: _VerifyLocationActionButton(
                  label: 'Retry',
                  iconAsset: AppAssets.icHomeRetry,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 184,
                child: _VerifyLocationActionButton(
                  label: 'Office',
                  iconAsset: AppAssets.icHomeCall,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Continue',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

class _VerifyLocationHeader extends StatelessWidget {
  const _VerifyLocationHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Verify your location',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeAddress),
        ),
        const SizedBox(height: 12),
        Text(
          'We confirm you\'re at the client address for EVV.',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
        ),
      ],
    );
  }
}

class _VerifyLocationCard extends StatelessWidget {
  const _VerifyLocationCard({required this.address});

  final String address;

  static const _cardBorder = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 183,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  AppColors.homePrimary.withValues(alpha: 0.18),
                  AppColors.homePrimary.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 59,
                  left: 26,
                  right: 26,
                  child: HomeSvgIcon(
                    asset: AppAssets.icHomeMapWave,
                    width: 330,
                    height: 65,
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.homePrimary.withValues(alpha: 0.22),
                        AppColors.homePrimary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                HomeSvgIcon(
                  asset: AppAssets.icHomeMapRing,
                  width: 71,
                  height: 71,
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.homePrimary,
                  ),
                  alignment: Alignment.center,
                  child: const HomeSvgIcon(
                    asset: AppAssets.icHomeLocation,
                    width: 19,
                    height: 19,
                    color: AppColors.authOnGradient,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(21, 20, 21, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Client address',
                        style: context.responsiveStyle(
                          AppTextStyles.labelSmall.copyWith(
                            fontSize: 12,
                            color: AppColors.homeMutedText,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const _CompactGpsVerifiedBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    address,
                    style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 8),
                  Text(
                    'You\'re within 50 ft of the client address.',
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactGpsVerifiedBadge extends StatelessWidget {
  const _CompactGpsVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.homeVerifiedBg,
        borderRadius: BorderRadius.circular(86),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icHomeVerified,
            width: 8,
            height: 8,
          ),
          const SizedBox(width: 4),
          Text(
            'GPS verified',
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: AppColors.homeVerifiedText,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyLocationActionButton extends StatelessWidget {
  const _VerifyLocationActionButton({
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onPressed;

  static const _cardBorder = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeSvgIcon(
                asset: iconAsset,
                width: 17,
                height: 17,
                color: AppColors.homeDarkText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.responsiveStyle(
                  AppTextStyles.homeCardTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    letterSpacing: -0.7,
                    color: AppColors.homeDarkText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 5: Confirm Service Type (`1:2092`) ─────────────────────────────────

class _ConfirmServiceTypeSheet extends StatefulWidget {
  const _ConfirmServiceTypeSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _ConfirmServiceTypeSheet(data: data),
    );
    return result == true;
  }

  @override
  State<_ConfirmServiceTypeSheet> createState() =>
      _ConfirmServiceTypeSheetState();
}

class _ConfirmServiceTypeSheetState extends State<_ConfirmServiceTypeSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.data.shift.serviceTypeOptions.indexOf(
      widget.data.serviceType,
    );
    if (_selectedIndex < 0) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.data.shift.serviceTypeOptions;

    return ShiftFlowSheetScaffold(
      header: const _ConfirmServiceTypeHeader(),
      body: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ServiceTypeOption(
              label: options[i],
              isSelected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          ],
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Continue',
        onPressed: () {
          widget.data.serviceType = options[_selectedIndex];
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}

class _ConfirmServiceTypeHeader extends StatelessWidget {
  const _ConfirmServiceTypeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Confirm service type',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeAddress),
        ),
        const SizedBox(height: 12),
        Text(
          'Used for authorization and billing.',
          textAlign: TextAlign.center,
          style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
        ),
      ],
    );
  }
}

// ── Step 6: Ready to Clock In (`1:1858`) ────────────────────────────────────

class _ReadyToClockInSheet extends StatelessWidget {
  const _ReadyToClockInSheet({required this.data});

  final _FlowData data;

  static Future<bool> show(BuildContext context, _FlowData data) async {
    final result = await showShiftFlowSheet(
      context: context,
      child: _ReadyToClockInSheet(data: data),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final shift = data.shift;

    return ShiftFlowSheetScaffold(
      header: const _ReadyToClockInHeader(),
      body: Column(
        children: [
          _ReadyToClockInDetailCard(
            clientName: data.clientName,
            serviceType: data.serviceType,
            dateTimeLabel: shift.visitDateTime,
          ),
          const SizedBox(height: 12),
          const ShiftFlowOfflineBanner(),
        ],
      ),
      action: ShiftFlowPrimaryButton(
        label: 'Clock In',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

class _ReadyToClockInHeader extends StatelessWidget {
  const _ReadyToClockInHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ready to clock in',
      textAlign: TextAlign.center,
      style: context.responsiveStyle(AppTextStyles.homeAddress),
    );
  }
}

class _ReadyToClockInDetailCard extends StatelessWidget {
  const _ReadyToClockInDetailCard({
    required this.clientName,
    required this.serviceType,
    required this.dateTimeLabel,
  });

  final String clientName;
  final String serviceType;
  final String dateTimeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 204,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.homePrimary.withValues(alpha: 0.14),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          _ConfirmVisitDetailRow(label: 'Client', value: clientName),
          const SizedBox(height: 12),
          _ConfirmVisitDetailRow(label: 'Service', value: serviceType),
          const SizedBox(height: 12),
          _ConfirmVisitDetailRow(label: 'Date / Time', value: dateTimeLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'GPS',
                style: _labelStyle(context),
              ),
              const Spacer(),
              const ShiftFlowStatusBadge(
                label: 'Verified',
                backgroundColor: AppColors.homeVerifiedBg,
                textColor: AppColors.homeVerifiedText,
                iconAsset: AppAssets.icHomeVerified,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'HHAExchange',
                style: _labelStyle(context),
              ),
              const Spacer(),
              const ShiftFlowStatusBadge(
                label: 'Ready to sync',
                backgroundColor: AppColors.homeSyncBg,
                textColor: AppColors.homePrimary,
                iconAsset: AppAssets.icHomeSync,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.32,
        color: AppColors.homeSheetLabel,
      ),
    );
  }
}

// ── Shared sub-widgets ──────────────────────────────────────────────────────

class _ServiceTypeOption extends StatelessWidget {
  const _ServiceTypeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _optionBorder = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 63,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.homeSheetDetailsBg : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.homePrimary.withValues(alpha: 0.27)
                  : _optionBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardTitle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.8,
                        color: AppColors.homeDarkText,
                      ),
                    ),
                  ),
                ),
                HomeSvgIcon(
                  asset: isSelected
                      ? AppAssets.icHomeRadioSelected
                      : AppAssets.icHomeRadioUnselected,
                  width: 22,
                  height: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
