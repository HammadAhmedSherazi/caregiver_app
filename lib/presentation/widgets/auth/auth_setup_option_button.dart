import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'auth_forward_icon.dart';

/// Selectable white option row for account setup (Figma 1:698).
class AuthSetupOptionButton extends StatelessWidget {
  const AuthSetupOptionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  static const _activeDotColor = Color(0xFF00BA00);
  static const _inactiveDotColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: Material(
        color: AppColors.authOnGradient,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isActive ? _activeDotColor : _inactiveDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.authSetupOptionLabel,
                  ),
                ),
                const AuthForwardIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
