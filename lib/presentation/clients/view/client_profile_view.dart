import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../core/utils/helpers/phone_launch_helper.dart';
import '../../../data/models/client_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/header_back_button.dart';
import '../../widgets/user_avatar.dart';
import '../widgets/client_list_widgets.dart';

/// Figma node `1:2356` — client profile detail.
class ClientProfileView extends StatelessWidget {
  const ClientProfileView({
    super.key,
    required this.client,
  });

  final ClientModel client;

  static const _headerHeight = 230.0;
  static const _cardOverlap = 47.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ClientProfileHeader(onBack: () => Navigator.of(context).pop()),
                VerticalOverlap(
                  overlap: _cardOverlap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _ClientProfileCard(client: client),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientProfileHeader extends StatelessWidget {
  const _ClientProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.homeHeader,
        child: SizedBox(
          height: ClientProfileView._headerHeight,
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
                      HeaderBackButton(onTap: onBack),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client',
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

class _ClientProfileCard extends StatelessWidget {
  const _ClientProfileCard({required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(33, 27, 33, 32),
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
          UserAvatar(
            imageUrl: client.avatarUrl,
            name: client.name,
            size: 97,
          ),
          const SizedBox(height: 24),
          Text(
            client.name,
            textAlign: TextAlign.center,
            style: context.responsiveStyle(
              AppTextStyles.profileName.copyWith(letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            client.address,
            textAlign: TextAlign.center,
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => launchMapSearch(client.address),
            style: TextButton.styleFrom(
              minimumSize: const Size(138, 39),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: AppColors.homeIconTint,
              foregroundColor: AppColors.homeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Open in Map',
              style: context.responsiveStyle(
                AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.homeAccent,
                  letterSpacing: -0.28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.homeMutedText.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Contact',
              style: context.responsiveStyle(
                AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClientContactRow(
            label: 'Client',
            phone: client.clientPhone,
            clientId: client.id,
          ),
          ClientContactRow(
            label: client.emergencyContact.label,
            phone: client.emergencyContact.phone,
            showDivider: false,
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.homeMutedText.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 24),
          ClientCarePlanList(items: client.dailyCarePlan),
        ],
      ),
    );
  }
}
