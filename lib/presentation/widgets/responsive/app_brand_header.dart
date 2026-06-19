import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shared brand header — compact (mobile) and expanded (tablet+) variants.
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader.compact({super.key}) : _variant = _BrandVariant.compact;

  const AppBrandHeader.expanded({super.key}) : _variant = _BrandVariant.expanded;

  final _BrandVariant _variant;

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _BrandVariant.compact => const _CompactBrand(),
      _BrandVariant.expanded => const _ExpandedBrand(),
    };
  }
}

enum _BrandVariant { compact, expanded }

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.volunteer_activism,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: AppTextStyles.titleLarge,
        ),
      ],
    );
  }
}

class _ExpandedBrand extends StatelessWidget {
  const _ExpandedBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sidebar,
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coordinate care visits, manage clients, and stay connected with your team — all in one place.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
