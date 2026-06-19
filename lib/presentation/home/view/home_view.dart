import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers/snackbar_helper.dart';
import '../../../data/models/care_recipient_model.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive/adaptive_list_grid.dart';
import '../../widgets/responsive/adaptive_scaffold.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _navItems = [
    ShellNavItem(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    ShellNavItem(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Clients',
    ),
    ShellNavItem(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Schedule',
    ),
    ShellNavItem(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          SnackbarHelper.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return AdaptiveScaffold(
          title: 'Dashboard',
          destinations: _navItems,
          actions: [
            IconButton(
              onPressed: () => context.read<HomeCubit>().refresh(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.isLoading && state.recipients.isEmpty) {
      return const LoadingWidget(message: 'Loading care recipients...');
    }

    if (state.hasError && state.recipients.isEmpty) {
      return ErrorDisplayWidget(
        message: state.errorMessage ?? 'Something went wrong',
        onRetry: () => context.read<HomeCubit>().loadRecipients(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          ResponsiveHelper.value(context, compact: 16, medium: 24, expanded: 32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Care Visits',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and review your assigned care recipients.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AdaptiveListGrid(
              itemCount: state.recipients.length,
              itemBuilder: (context, index) {
                return _RecipientCard(recipient: state.recipients[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.recipient});

  final CareRecipientModel recipient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  recipient.name.isNotEmpty
                      ? recipient.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recipient.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recipient.careType,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recipient.nextVisit,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
