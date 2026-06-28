import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/theme/app_colors.dart';
import 'error_widget.dart';

/// Wraps GET API screens: skeleton while loading, error + retry on failure.
class GetRequestView extends StatelessWidget {
  const GetRequestView({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.skeleton,
    required this.child,
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final Widget skeleton;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return ErrorDisplayWidget(onRetry: onRetry);
    }

    if (isLoading) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Skeletonizer(
          enabled: true,
          effect: ShimmerEffect(
            baseColor: AppColors.homeSheetDetailsBg,
            highlightColor: AppColors.surface,
          ),
          child: skeleton,
        ),
      );
    }

    return child;
  }
}

/// Shows a snackbar when a POST/action call fails.
class PostActionListener<C extends StateStreamable<S>, S> extends StatelessWidget {
  const PostActionListener({
    super.key,
    required this.listenWhen,
    required this.errorMessage,
    required this.onClearError,
    required this.child,
  });

  final bool Function(S previous, S current) listenWhen;
  final String? Function(S state) errorMessage;
  final VoidCallback onClearError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<C, S>(
      listenWhen: listenWhen,
      listener: (context, state) {
        final message = errorMessage(state);
        if (message == null || message.isEmpty) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        onClearError();
      },
      child: child,
    );
  }
}
