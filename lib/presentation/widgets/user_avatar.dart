import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Circular user avatar with network image, loading state, and initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 50,
    this.backgroundColor,
    this.initialsTextStyle,
  });

  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final TextStyle? initialsTextStyle;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _FallbackAvatar(
                    size: size,
                    initials: _initials,
                    backgroundColor: backgroundColor,
                    initialsTextStyle: initialsTextStyle,
                    showProgress: true,
                    progress: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  );
                },
                errorBuilder: (_, _, _) => _FallbackAvatar(
                  size: size,
                  initials: _initials,
                  backgroundColor: backgroundColor,
                  initialsTextStyle: initialsTextStyle,
                ),
              )
            : _FallbackAvatar(
                size: size,
                initials: _initials,
                backgroundColor: backgroundColor,
                initialsTextStyle: initialsTextStyle,
              ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.size,
    required this.initials,
    this.backgroundColor,
    this.initialsTextStyle,
    this.showProgress = false,
    this.progress,
  });

  final double size;
  final String initials;
  final Color? backgroundColor;
  final TextStyle? initialsTextStyle;
  final bool showProgress;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor ?? AppColors.homeAccent,
      alignment: Alignment.center,
      child: showProgress
          ? SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
                color: Colors.white,
              ),
            )
          : Text(
              initials,
              style: initialsTextStyle ??
                  AppFonts.base(
                    fontSize: size * 0.36,
                    fontWeight: AppFonts.semiBold,
                    color: Colors.white,
                  ),
            ),
    );
  }
}
