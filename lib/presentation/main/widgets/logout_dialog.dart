import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../home/widgets/home_svg_icon.dart';

/// Figma node `1:923` — logout confirmation bottom sheet.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.homeDialogOverlay,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: const LogoutDialog(),
      ),
    );
  }

  static const _iconBoxSize = 99.0;
  static const _iconSize = 51.0;
  static const _sheetHeight = 254.0;
  static const _iconOverlap = 34.0;

  void _pop(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated,
      listener: (context, state) => _pop(context),
      builder: (context, state) {
        final isLoading = state.isSubmitting;

        return PopScope(
          canPop: !isLoading,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: _iconBoxSize - _iconOverlap),
                  child: Container(
                    height: _sheetHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.homeDialogShadow,
                          blurRadius: 26,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
                      child: Column(
                        children: [
                          Text(
                            'Logout ?',
                            style: context.responsiveStyle(
                              AppTextStyles.homeConfirmDialogTitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Are you sure want to logout ?',
                            textAlign: TextAlign.center,
                            style: context.responsiveStyle(
                              AppTextStyles.homeCardSubtitle,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: FilledButton(
                                    onPressed:
                                        isLoading ? null : () => _pop(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F4FE),
                                      foregroundColor: const Color(0xFF333333),
                                      disabledBackgroundColor:
                                          const Color(0xFFF1F4FE),
                                      disabledForegroundColor:
                                          const Color(0xFF333333)
                                              .withValues(alpha: 0.5),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: context.responsiveStyle(
                                        AppTextStyles.authLoginButtonLabel
                                            .copyWith(
                                          color: const Color(0xFF333333),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: isLoading
                                        ? null
                                        : () =>
                                            context.read<AuthCubit>().logout(),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.homePrimary,
                                      foregroundColor: AppColors.authOnGradient,
                                      disabledBackgroundColor: AppColors.homePrimary
                                          .withValues(alpha: 0.85),
                                      disabledForegroundColor:
                                          AppColors.authOnGradient,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: context.responsiveStyle(
                                        AppTextStyles.authLoginButtonLabel
                                            .copyWith(
                                          color: AppColors.authOnGradient,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.authOnGradient,
                                            ),
                                          )
                                        : const Text('Logout'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: _iconBoxSize,
                    height: _iconBoxSize,
                    decoration: BoxDecoration(
                      color: AppColors.homePrimary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.homeDialogShadow,
                          blurRadius: 26,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const HomeSvgIcon(
                      asset: AppAssets.icLogoutBold,
                      width: _iconSize,
                      height: _iconSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
