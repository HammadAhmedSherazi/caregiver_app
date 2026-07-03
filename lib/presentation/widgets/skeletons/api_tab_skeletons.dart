import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/widgets/vertical_overlap.dart';

class HomeTabSkeleton extends StatelessWidget {
  const HomeTabSkeleton({super.key});

  static const _headerHeight = 280.0;
  static const _cardOverlap = 100.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.homeHeader,
            child: SizedBox(
              height: _headerHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back, Caregiver',
                              style: AppTextStyles.homeWelcome,
                            ),
                            Text(
                              'Monday, January 01',
                              style: AppTextStyles.homeDate,
                            ),
                          ],
                        ),
                      ),
                      const _SkeletonAvatar(size: 24),
                      const SizedBox(width: 16),
                      const _SkeletonAvatar(size: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
          VerticalOverlap(
            overlap: _cardOverlap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _SkeletonCard(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Client Name', style: AppTextStyles.homeCardTitle),
                          const SizedBox(height: 8),
                          Text(
                            '248 Oak Street, Brooklyn',
                            style: AppTextStyles.homeCardSubtitle,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '9:00 AM – 1:00 PM',
                            style: AppTextStyles.homeCardSubtitle,
                          ),
                        ],
                      ),
                    ),
                    const _SkeletonAvatar(size: 110),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Today's Schedule",
                    style: AppTextStyles.homeSectionTitle,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _SkeletonCard(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _SkeletonAvatar(size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Client Name',
                                  style: AppTextStyles.homeCardTitle,
                                ),
                                Text(
                                  '9:00 AM · 4h',
                                  style: AppTextStyles.homeCardSubtitle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SkeletonCard(
                          height: 88,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonCard(
                          height: 88,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pending Task',
                    style: AppTextStyles.homeSectionTitle,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < 2; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _SkeletonCard(
                      height: 64,
                      child: Row(
                        children: [
                          Text('9:30 AM', style: AppTextStyles.homeCardSubtitle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Task title placeholder',
                              style: AppTextStyles.homeCardTitle,
                            ),
                          ),
                        ],
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

class ScheduleTabContentSkeleton extends StatelessWidget {
  const ScheduleTabContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          Text('JANUARY 2026', style: AppTextStyles.homeSectionTitle),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, _) => Container(
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('MON', style: AppTextStyles.homeCardSubtitle),
                    Text('01', style: AppTextStyles.homeCardTitle),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SkeletonCard(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2:00 PM', style: AppTextStyles.homeCardTitle),
                    const SizedBox(height: 8),
                    Text('Client Name', style: AppTextStyles.homeCardTitle),
                    Text(
                      '742 Evergreen, Dearborn, MI',
                      style: AppTextStyles.homeCardSubtitle,
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

class PayrollContentSkeleton extends StatelessWidget {
  const PayrollContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Container(
            height: 141,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Text('Paystubs', style: AppTextStyles.homeSectionTitle),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _SkeletonCard(
                height: 92,
                child: Row(
                  children: [
                    const _SkeletonAvatar(size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pay period', style: AppTextStyles.homeCardTitle),
                          Text('\$0.00', style: AppTextStyles.homeCardSubtitle),
                        ],
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

class ComplianceHistorySkeleton extends StatelessWidget {
  const ComplianceHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
        children: [
          Text('Record', style: AppTextStyles.homeCardTitle),
          const SizedBox(height: 16),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _SkeletonCard(
                height: 72,
                child: Row(
                  children: [
                    const _SkeletonAvatar(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('May 2026', style: AppTextStyles.homeCardTitle),
                          Text('Submitted', style: AppTextStyles.homeCardSubtitle),
                        ],
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

class ProfileTabSkeleton extends StatelessWidget {
  const ProfileTabSkeleton({super.key});

  static const _headerHeight = 230.0;
  static const _cardOverlap = 47.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SkeletonScreenHeader(
                  height: _headerHeight,
                  title: 'Mitchell',
                  subtitle: 'Profile',
                ),
                VerticalOverlap(
                  overlap: _cardOverlap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _ProfileCardSkeleton(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          const _SkeletonAvatar(size: 97),
          const SizedBox(height: 24),
          Text('Caregiver Name', style: AppTextStyles.profileName),
          const SizedBox(height: 8),
          Text('Certified Home Healer', style: AppTextStyles.profileTitle),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 86),
            child: _SkeletonDividerLine(),
          ),
          const SizedBox(height: 17),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _ProfileStatSkeleton(label: '3 years'),
                _ProfileStatSkeleton(label: '247 visits'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33),
            child: _SkeletonDividerLine(),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(33, 0, 33, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours This Week',
                  style: AppTextStyles.profileHoursLabel,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('28.5', style: AppTextStyles.profileHoursValue),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Text('h', style: AppTextStyles.profileHoursUnit),
                    ),
                    const Spacer(),
                    Container(
                      height: 24,
                      width: 132,
                      decoration: BoxDecoration(
                        color: AppColors.scheduleScheduledBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+12% vs last week',
                        style: AppTextStyles.profileGrowthBadge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('of 40h target', style: AppTextStyles.profileTitle),
                const SizedBox(height: 24),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final height in [0.95, 0.62, 0.38, 0.72, 0.48])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 110 * height,
                                  decoration: BoxDecoration(
                                    color: AppColors.homeSheetDetailsBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('M', style: AppTextStyles.homeCardSubtitle),
                              ],
                            ),
                          ),
                        ),
                    ],
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

class _ProfileStatSkeleton extends StatelessWidget {
  const _ProfileStatSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SkeletonIconBox(),
        const SizedBox(width: 9),
        Text(label, style: AppTextStyles.profileStat),
      ],
    );
  }
}

class TaskTabSkeleton extends StatelessWidget {
  const TaskTabSkeleton({super.key});

  static const _headerHeight = 187.0;
  static const _searchOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SkeletonScreenHeader(
                height: _headerHeight,
                title: 'All Tasks',
                subtitle: '3 Pending',
              ),
              VerticalOverlap(
                overlap: _searchOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 19),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.homeCardShadow,
                          blurRadius: 26,
                          offset: Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.homeIconTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Text(
                          'Search Clients',
                          style: AppTextStyles.homeCardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in ['All', 'Compliance', 'Documents', 'Visits'])
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: label == 'All'
                                  ? AppColors.homePrimary
                                  : AppColors.homePrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              label,
                              style: AppTextStyles.homeCardSubtitle.copyWith(
                                fontSize: 10,
                                color: label == 'All'
                                    ? AppColors.authOnGradient
                                    : AppColors.homePrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < 2; i++) ...[
                  _TaskActionCardSkeleton(
                    title: i == 0
                        ? 'May Compliance Form Due'
                        : "Upload Updated Driver's License",
                    subtitle: i == 0 ? 'Due today' : 'Due in 3 days',
                    actionLabel: i == 0 ? 'Complete form' : 'Upload now',
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  "Today's Schedule",
                  style: AppTextStyles.homeCardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < 2; i++) ...[
                  _TaskVisitCardSkeleton(
                    title: 'John Doe',
                    subtitle: '9:00 AM · 4h',
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                for (final entry in [
                  ('My Clients', 'Assigned clients & profiles'),
                  ('Payroll', 'View paystubs & earnings'),
                  ('Compliance History', 'Past submissions & records'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskQuickLinkSkeleton(
                      title: entry.$1,
                      subtitle: entry.$2,
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

class _TaskActionCardSkeleton extends StatelessWidget {
  const _TaskActionCardSkeleton({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonIconBox(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.homeCardTitle, maxLines: 2),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.homeCardSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 22,
                width: 58,
                decoration: BoxDecoration(
                  color: AppColors.homeSheetDetailsBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pending',
                  style: AppTextStyles.homeCardSubtitle.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 53,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.homePrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              actionLabel,
              style: AppTextStyles.homeCardTitle.copyWith(
                color: AppColors.homePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskVisitCardSkeleton extends StatelessWidget {
  const _TaskVisitCardSkeleton({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          const _SkeletonAvatar(size: 48),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.homeCardTitle, maxLines: 1),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.homeCardSubtitle),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.homeSheetDetailsBg,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskQuickLinkSkeleton extends StatelessWidget {
  const _TaskQuickLinkSkeleton({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          const _SkeletonIconBox(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.homeCardTitle, maxLines: 1),
                Text(
                  subtitle,
                  style: AppTextStyles.homeCardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.homeSheetDetailsBg,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonIconBox extends StatelessWidget {
  const _SkeletonIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 47,
      decoration: BoxDecoration(
        color: AppColors.homeIconTint,
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }
}

class _SkeletonDividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.homeMutedText.withValues(alpha: 0.2),
    );
  }
}

class _SkeletonScreenHeader extends StatelessWidget {
  const _SkeletonScreenHeader({
    required this.height,
    required this.title,
    required this.subtitle,
  });

  final double height;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.homeHeader,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(19, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.homeWelcome),
                  Text(subtitle, style: AppTextStyles.homeDate),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientsListSkeleton extends StatelessWidget {
  const ClientsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const Divider(height: 24),
                Row(
                  children: [
                    const _SkeletonAvatar(size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Client Name', style: AppTextStyles.homeCardTitle),
                          Text(
                            '742 Evergreen, Dearborn, MI',
                            style: AppTextStyles.homeCardSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonIconBox(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Updated',
                          style: AppTextStyles.homeCardTitle,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            'New visit added for Thursday at 6:00 PM.',
                            style: AppTextStyles.homeCardSubtitle,
                            maxLines: 2,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '4 days ago',
                            style: AppTextStyles.homeCardSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class InboxListSkeleton extends StatelessWidget {
  const InboxListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonAvatar(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salena James',
                          style: AppTextStyles.homeCardTitle,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            'Hi, can you confirm your shift on Thursday?',
                            style: AppTextStyles.homeCardSubtitle,
                            maxLines: 2,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '4 days ago',
                            style: AppTextStyles.homeCardSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        for (final isMine in [false, true, false, true, false])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment:
                  isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isMine
                      ? 'Account setup help.'
                      : 'How can we help you today?',
                  style: AppTextStyles.homeCardSubtitle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SkeletonAvatar extends StatelessWidget {
  const _SkeletonAvatar({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        shape: BoxShape.circle,
      ),
    );
  }
}
