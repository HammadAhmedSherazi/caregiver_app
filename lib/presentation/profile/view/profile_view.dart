import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/velora_format.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../clients/view/clients_list_view.dart';
import '../../home/cubit/home_cubit.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/logout_dialog.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_hours_chart.dart';

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
              title: 'Profile',
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
                            data?.title ?? 'Caregiver',
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
                      const SectionCaption('Your client'),
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
                                  [shift.serviceType, if (data?.isLiveIn ?? false) 'Live-in'].join(' · '),
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
                VeloraErrorState(message: 'We couldn\'t load your profile.', onRetry: _load)
              else if (data == null)
                const VeloraLoadingState()
              else ...[
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyValueRow(showDivider: false, label: 'Mobile', value: data.phone ?? '—'),
                      KeyValueRow(label: 'Email', value: data.email ?? user?.email ?? '—'),
                      KeyValueRow(label: 'Home address', value: data.address ?? '—'),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: VeloraColors.line)),
                        ),
                        child: Center(
                          child: VeloraTextLink(
                            label: 'Update my info',
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
                        const SectionCaption('Hours by week'),
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
                      label: 'My clients',
                      showDivider: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ClientsListView()),
                      ),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.phone,
                      label: 'Contact the office',
                      onTap: () => AppNavigator.openInbox(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.question,
                      label: 'Help & questions',
                      onTap: () => AppNavigator.openHelp(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.shield,
                      label: 'Privacy & your information',
                      onTap: () => AppNavigator.openPrivacy(context),
                    ),
                    _LinkRow(
                      icon: VeloraIcons.logout,
                      label: 'Sign out',
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

/// Language / reminders / Face ID from the design. None of these have app
/// or API support yet, so they are shown as unavailable rather than as
/// switches that do nothing.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

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

    return VeloraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          row(VeloraIcons.globe, 'Language', 'English', divider: false),
          row(VeloraIcons.bell, 'Clock-out & payday reminders', 'Coming soon'),
          row(VeloraIcons.faceId, 'Sign in with Face ID', 'Coming soon'),
        ],
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
