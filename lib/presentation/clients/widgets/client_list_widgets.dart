import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../core/utils/helpers/client_call_helper.dart';
import '../../../core/utils/helpers/phone_launch_helper.dart';
import '../../../data/models/client_model.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../widgets/user_avatar.dart';

/// Figma node `1:2202` — client row with call action inside list card.
class ClientListSection extends StatelessWidget {
  const ClientListSection({
    super.key,
    required this.client,
    required this.onOpenProfile,
    this.showDivider = true,
  });

  final ClientModel client;
  final VoidCallback onOpenProfile;
  final bool showDivider;

  static const _callBorder = Color(0xFFCBCFD9);
  static const _badgeBg = Color(0xFFDFEAFF);
  static const _badgeText = Color(0xFF1A4DB4);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  imageUrl: client.avatarUrl,
                  name: client.name,
                  size: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: context.responsiveStyle(
                          AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        client.listSubtitle,
                        style: context.responsiveStyle(
                          AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.homeMutedText,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 29,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    client.scheduleBadge,
                    style: context.responsiveStyle(
                      AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _badgeText,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: () => initiateClientCall(
              context,
              clientId: client.id,
              fallbackPhone: client.clientPhone,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: _callBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HomeSvgIcon(
                  asset: AppAssets.icCallBulk,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 13),
                Text(
                  'Call Now',
                  style: context.responsiveStyle(
                    AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.homeMutedText,
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.homeMutedText.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class ClientScheduleBadge extends StatelessWidget {
  const ClientScheduleBadge({super.key, required this.label});

  final String label;

  static const _badgeBg = Color(0xFFDFEAFF);
  static const _badgeText = Color(0xFF1A4DB4);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: context.responsiveStyle(
          AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _badgeText,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class ClientContactRow extends StatelessWidget {
  const ClientContactRow({
    super.key,
    required this.label,
    required this.phone,
    this.clientId,
    this.showDivider = true,
  });

  final String label;
  final String phone;
  final String? clientId;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.homeIconTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const HomeSvgIcon(
                asset: AppAssets.icCallOutline,
                width: 16,
                height: 16,
                color: AppColors.homeDarkText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.responsiveStyle(
                      AppTextStyles.homeNavLabel.copyWith(
                        fontSize: 12,
                        color: AppColors.homeMutedText,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: context.responsiveStyle(
                      AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                if (clientId != null) {
                  initiateClientCall(
                    context,
                    clientId: clientId!,
                    fallbackPhone: phone,
                  );
                } else {
                  launchPhoneCall(phone);
                }
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(56, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.homeIconTint,
                foregroundColor: AppColors.homeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Call',
                style: context.responsiveStyle(
                  AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.homeAccent,
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.homeMutedText.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class ClientCarePlanList extends StatelessWidget {
  const ClientCarePlanList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily care plan',
          style: context.responsiveStyle(
            AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 12),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.homePrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    item,
                    style: context.responsiveStyle(
                      AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.homeMutedText,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
