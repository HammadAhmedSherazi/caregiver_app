import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/velora_format.dart';
import '../../../data/local/face_id_store.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/local/language_store.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../clients/view/clients_list_view.dart';
import '../../home/cubit/home_cubit.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/logout_dialog.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_hours_chart.dart';
import '../../../core/i18n/tr.dart';

/// Profile & settings, opened from the person icon on Home (`GET /me`,
/// `GET /earnings/summary`).
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() {
    final user = context.read<AuthCubit>().state.user;
    return context.read<ProfileCubit>().loadProfile(user: user);
  }

  @override
  Widget build(BuildContext context) {
    return VeloraScaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final data = state.data;
          final user = context.read<AuthCubit>().state.user;
          final name = data?.name ?? user?.name ?? '';
          final shift = context.read<HomeCubit>().state.dashboard?.activeShift;

          return VeloraPage(
            onRefresh: _load,
            header: VeloraHeader(
              title: tr('Profile'),
              onBack: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              bottom: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    _Avatar(url: data?.avatarUrl ?? user?.avatarUrl, name: name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: VeloraText.display(21, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(
                            data?.title ?? tr('Caregiver'),
                            style: VeloraText.body(13, color: VeloraColors.onHeaderMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            children: [
              if (shift != null)
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCaption(tr('Your client')),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          InitialsTile(shift.clientInitials, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shift.clientName, style: VeloraText.body(15, weight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  [shift.serviceType, if (data?.isLiveIn ?? false) tr('Live-in')].join(' · '),
                                  style: VeloraText.subtitle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (state.hasError && data == null)
                VeloraErrorState(message: tr('We couldn\'t load your profile.'), onRetry: _load)
              else if (data == null)
                const VeloraLoadingState()
              else ...[
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyValueRow(showDivider: false, label: tr('Mobile'), value: data.phone ?? '—'),
                      KeyValueRow(label: tr('Email'), value: data.email ?? user?.email ?? '—'),
                      KeyValueRow(label: tr('Home address'), value: data.address ?? '—'),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: VeloraColors.line)),
                        ),
                        child: Center(
                          child: VeloraTextLink(
                            label: tr('Update my info'),
                            size: 13.5,
                            onTap: () => AppNavigator.openMyInfo(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.weeklyHours.isNotEmpty)
                  VeloraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionCaption(tr('Hours by week')),
                        const SizedBox(height: 12),
                        ProfileHoursChart(
                          weeklyHours: data.weeklyHours,
                          targetLineHours: data.targetLineHours,
                          maxHours: data.chartMaxHours,
                        ),
                      ],
                    ),
                  ),
              ],
              const _SettingsCard(),
              VeloraCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _LinkRow(
                      icon: VeloraIcons.user,
                      label: tr('My clients'),
                      showDivider: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ClientsListView()),
                      ),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.phone,
                      label: tr('Contact the office'),
                      onTap: () => AppNavigator.openInbox(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.question,
                      label: tr('Help & questions'),
                      onTap: () => AppNavigator.openHelp(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.shield,
                      label: tr('Privacy & your information'),
                      onTap: () => AppNavigator.openPrivacy(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.logout,
                      label: tr('Sign out'),
                      danger: true,
                      onTap: () => LogoutDialog.show(context),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Image.asset('assets/images/brand/velora_logo_dark.png', height: 22, semanticLabel: 'VELORA'),
                  const SizedBox(height: 6),
                  Text('powered by Beydoun Tech', style: VeloraText.body(11, color: VeloraColors.caption)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = VeloraFormat.initials(name);
    Widget fallback() => Center(
          child: initials.isEmpty
              ? const VeloraIcon(VeloraIcons.user, size: 34, color: VeloraColors.teal, strokeWidth: 1.7)
              : Text(initials, style: VeloraText.display(22, color: VeloraColors.teal)),
        );
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: VeloraColors.mint,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback())
          : fallback(),
    );
  }
}

/// Language / reminders / Face ID from the design. Face ID is live (it
/// guards the saved session, see the sign-in screen); language and
/// reminders have no app support yet, so they show as unavailable rather
/// than as switches that do nothing.
class _SettingsCard extends StatefulWidget {
  const _SettingsCard();

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  final _biometric = sl<BiometricAuth>();
  final _faceStore = sl<FaceIdStore>();

  bool _loaded = false;
  bool _available = false;
  bool _enabled = false;
  bool _busy = false;
  String _label = 'Face ID';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await _biometric.isAvailable();
    final label = available ? await _biometric.label() : _label;
    final enabled = await _faceStore.isEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _label = label;
      _enabled = enabled;
      _loaded = true;
    });
  }

  Future<void> _toggleFace() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthCubit>();
    if (_enabled) {
      await auth.setFaceIdEnabled(false);
      if (mounted) setState(() => _enabled = false);
    } else {
      // Same check as on sign-in; the first time it also shows the iPhone
      // "Allow Face ID?" permission.
      final result =
          await _biometric.authenticate(tr('Turn on {0} for VELORA', [_label]));
      if (result == BiometricResult.success) {
        final first = auth.state.user?.name.trim().split(RegExp(r'\s+')).first;
        await auth.setFaceIdEnabled(true, name: first);
        if (mounted) setState(() => _enabled = true);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget row(VeloraIcons icon, String label, String value, {bool divider = true}) {
      return VeloraListRow(
        showDivider: divider,
        leading: IconTile(icon, size: 36, iconSize: 17, radius: 11),
        title: label,
        trailing: StatusPill(value, tone: PillTone.mute),
        showChevron: false,
      );
    }

    final faceTitle = tr('Sign in with {0}', [_label]);
    final Widget faceRow = !_loaded
        ? row(VeloraIcons.faceId, faceTitle, '…')
        : !_available
            ? row(VeloraIcons.faceId, faceTitle, tr('Not set up on this phone'))
            : Semantics(
                toggled: _enabled,
                label: faceTitle,
                excludeSemantics: true,
                child: VeloraListRow(
                  leading:
                      IconTile(VeloraIcons.faceId, size: 36, iconSize: 17, radius: 11),
                  title: faceTitle,
                  trailing: _DesignSwitch(value: _enabled, busy: _busy),
                  showChevron: false,
                  onTap: _toggleFace,
                ),
              );

    return VeloraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          VeloraListRow(
            showDivider: false,
            leading: IconTile(VeloraIcons.globe, size: 36, iconSize: 17, radius: 11),
            title: tr('Language'),
            trailing: const _LanguageSwitch(),
            showChevron: false,
          ),
          row(VeloraIcons.bell, tr('Clock-out & payday reminders'), tr('Coming soon')),
          faceRow,
        ],
      ),
    );
  }
}

/// English / العربية (`.seg` in the design). Switches the whole app at once
/// and, once `PUT /me/settings` is live, saves it on the caregiver too.
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  Future<void> _set(String code) async {
    await sl<LanguageStore>().set(code);
    try {
      await sl<ProfileRepository>()
          .updateSettings(CaregiverSettingsModel(language: code));
    } catch (_) {
      // Planned endpoint (not live yet) or offline: the phone's choice is
      // what drives the app language.
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = sl<LanguageStore>().current;
    Widget option(String label, String code) {
      final selected = current == code;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : () => _set(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? VeloraColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: VeloraText.body(
                12.5,
                weight: FontWeight.w700,
                color: selected ? Colors.white : VeloraColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: VeloraColors.muteBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option('English', 'en'),
          const SizedBox(width: 2),
          option('العربية', 'ar'),
        ],
      ),
    );
  }
}

/// The design's `.sw` switch: 48×28 track (teal on, grey off), 22 px knob.
class _DesignSwitch extends StatelessWidget {
  const _DesignSwitch({required this.value, this.busy = false});

  final bool value;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: busy ? 0.5 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? VeloraColors.teal : VeloraColors.disabled,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
    this.danger = false,
  });

  final VeloraIcons icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return VeloraListRow(
      showDivider: showDivider,
      leading: IconTile(
        icon,
        tone: danger ? IconTileTone.danger : IconTileTone.mint,
        size: 36,
        iconSize: 17,
        radius: 11,
      ),
      title: label,
      titleColor: danger ? VeloraColors.dangerText : null,
      showChevron: !danger,
      onTap: onTap,
    );
  }
}
