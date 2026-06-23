import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/profile_page_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../clients/view/clients_list_view.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/header_back_button.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_hours_chart.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state.data != null) return;

    final user = context.read<AuthCubit>().state.user;
    cubit.loadProfile(user: user);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const LoadingWidget(message: 'Loading profile...');
        }

        if (state.hasError && state.data == null) {
          return ErrorDisplayWidget(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: _loadProfile,
          );
        }

        final data = state.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    title: data.headerTitle,
                    onBack: widget.onBack,
                  ),
                  VerticalOverlap(
                    overlap: _ProfileHeader.cardOverlap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ProfileCard(data: data),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  static const _headerHeight = 230.0;
  static const cardOverlap = 47.0;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.homeHeader,
        child: SizedBox(
          height: _headerHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 92,
                top: -222,
                width: 416,
                height: 353,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.authGlowTop,
                          AppColors.authGlowTop.withValues(alpha: 0.35),
                          AppColors.authGlowTop.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(19, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onBack != null) ...[
                        HeaderBackButton(onTap: onBack!),
                        const SizedBox(width: 24),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.responsiveStyle(
                              AppTextStyles.homeWelcome,
                            ),
                          ),
                          Text(
                            'Profile',
                            style: context.responsiveStyle(
                              AppTextStyles.homeDate,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.data});

  final ProfilePageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 25.9,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 27),
          UserAvatar(
            imageUrl: data.avatarUrl,
            name: data.name,
            size: 97,
          ),
          const SizedBox(height: 24),
          Text(
            data.name,
            style: context.responsiveStyle(AppTextStyles.profileName),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: context.responsiveStyle(AppTextStyles.profileTitle),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 86),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.homeMutedText.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 17),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProfileStat(
                  icon: AppAssets.icProfileAward,
                  label: '${data.experienceYears} years',
                ),
                _ProfileStat(
                  icon: AppAssets.icProfileUsers,
                  label: '${data.visitCount} visits',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ClientsListView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.homeMutedText.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(33, 0, 33, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours This Week',
                  style: context.responsiveStyle(AppTextStyles.profileHoursLabel),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.hoursThisWeek.toStringAsFixed(1),
                      style: context.responsiveStyle(
                        AppTextStyles.profileHoursValue,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        'h',
                        style: context.responsiveStyle(
                          AppTextStyles.profileHoursUnit,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.scheduleScheduledBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '+${data.weekChangePercent}% vs last week',
                        style: context.responsiveStyle(
                          AppTextStyles.profileGrowthBadge,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'of ${data.targetHours.toInt()}h target',
                  style: context.responsiveStyle(AppTextStyles.profileTitle),
                ),
                const SizedBox(height: 24),
                ProfileHoursChart(
                  weeklyHours: data.weeklyHours,
                  targetLineHours: data.targetLineHours,
                  maxHours: data.chartMaxHours,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSvgIcon(asset: icon, width: 24, height: 24),
        const SizedBox(width: 9),
        Text(
          label,
          style: context.responsiveStyle(AppTextStyles.profileStat),
        ),
      ],
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}
