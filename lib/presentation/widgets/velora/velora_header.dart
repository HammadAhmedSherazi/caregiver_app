import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/velora_theme.dart';
import 'velora_icon.dart';
import '../../../core/i18n/tr.dart';

/// Dark-green page header with the concentric-ring decoration.
///
/// Tab pages use a large title and no back button; pushed pages pass
/// [onBack] to show the square back button next to a smaller title.
class VeloraHeader extends StatelessWidget {
  const VeloraHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.overline,
    this.onBack,
    this.trailing,
    this.leading,
    this.bottom,
    this.gradient = false,
    this.padding,
  });

  final String title;
  final String? subtitle;

  /// Small line shown above the title (Home's date).
  final String? overline;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leading;
  final Widget? bottom;
  final bool gradient;
  final EdgeInsetsGeometry? padding;

  bool get _isPushed => onBack != null;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          color: gradient ? null : VeloraColors.brand,
          gradient: gradient
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [VeloraColors.brand, VeloraColors.brandDark],
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            const Positioned(
              right: -70,
              top: -80,
              child: HeaderRings(size: 240),
            ),
            Padding(
              padding: (padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 22))
                  .add(EdgeInsets.only(top: topInset)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(height: 22)],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_isPushed) ...[
                        HeaderSquareButton(
                          icon: VeloraIcons.chevronLeft,
                          semanticLabel: tr('Back'),
                          onTap: onBack!,
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (overline != null) ...[
                              Text(
                                overline!,
                                style: VeloraText.body(
                                  13,
                                  weight: FontWeight.w500,
                                  color: VeloraColors.onHeaderMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              title,
                              style: VeloraText.display(
                                _isPushed ? 22 : 27,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              SizedBox(height: _isPushed ? 2 : 4),
                              Text(
                                subtitle!,
                                style: VeloraText.body(
                                  _isPushed ? 12.5 : 13,
                                  color: VeloraColors.onHeaderMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing!,
                      ],
                    ],
                  ),
                  ?bottom,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three faint concentric circles drawn top-right of every header.
class HeaderRings extends StatelessWidget {
  const HeaderRings({super.key, this.size = 240, this.opacity = 0.1});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RingsPainter(opacity),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..color = Colors.white.withValues(alpha: opacity);
    final center = Offset(120 * scale, 80 * scale);
    for (final r in const [40.0, 62.0, 84.0]) {
      canvas.drawCircle(center, r * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// 44×44 translucent square used for back/call buttons in headers.
class HeaderSquareButton extends StatelessWidget {
  const HeaderSquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.background,
    this.foreground = Colors.white,
  });

  final VeloraIcons icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background ?? Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: VeloraIcon(icon, size: 20, color: foreground, strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
  }
}
