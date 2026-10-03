import 'package:flutter/material.dart';

/// VELORA design tokens (from the Claude Design canvas "VELORA Caregiver App").
class VeloraColors {
  VeloraColors._();

  // Brand
  static const Color brand = Color(0xFF0F4A41);
  static const Color brandDark = Color(0xFF0C3A34);
  static const Color brandDeepest = Color(0xFF0A2C28);
  static const Color teal = Color(0xFF16685B);
  static const Color amber = Color(0xFFE0A72E);
  static const Color amberInk = Color(0xFF3A2A06);
  static const Color mint = Color(0xFFDFEEE9);
  static const Color mintSoft = Color(0xFFF2F8F5);

  // Surfaces
  static const Color background = Color(0xFFF4F7F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color subtle = Color(0xFFF5F8F6);
  static const Color muteBg = Color(0xFFEEF3F0);
  static const Color line = Color(0xFFE3EAE6);
  static const Color fieldBorder = Color(0xFFD3DED8);
  static const Color disabled = Color(0xFFC9D5D0);
  static const Color paperBg = Color(0xFFDCE3DF);

  // Text
  static const Color ink = Color(0xFF122420);
  static const Color muted = Color(0xFF54655F);
  static const Color caption = Color(0xFF5E706A);
  static const Color body = Color(0xFF3E4F49);
  static const Color chevron = Color(0xFF849790);
  static const Color faint = Color(0xFFB6C3BE);
  static const Color onHeaderMuted = Color(0xFFBFD3CD);

  // Tab bar
  static const Color tabInactive = Color(0xFF9DB6AF);
  static const Color tabActive = Color(0xFFFBF3E3);

  // Tones
  static const Color goodText = Color(0xFF0E6649);
  static const Color goodBg = Color(0xFFDCEEE6);
  static const Color warnText = Color(0xFF86560C);
  static const Color warnBg = Color(0xFFF6EAD3);
  static const Color amberSoft = Color(0xFFF7ECD4);
  static const Color amberIcon = Color(0xFFA86E12);
  static const Color noteBg = Color(0xFFFBF4E6);
  static const Color noteBorder = Color(0xFFEBD3A5);
  static const Color noteLabel = Color(0xFF6B4A0C);
  static const Color dangerText = Color(0xFFA1362E);
  static const Color dangerBg = Color(0xFFF8E4E2);
  static const Color dangerStrong = Color(0xFFBC443B);
  static const Color live = Color(0xFF2FB37E);
}

class VeloraFonts {
  VeloraFonts._();

  /// Display face (headings, big numbers).
  static const String display = 'Bricolage Grotesque';

  /// Body face.
  static const String body = 'Hanken Grotesk';
}

/// Text styles used across the redesigned screens.
class VeloraText {
  VeloraText._();

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = VeloraColors.ink,
    double letterSpacing = -0.02,
    double? height,
  }) {
    return TextStyle(
      fontFamily: VeloraFonts.display,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: size * letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = VeloraColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: VeloraFonts.body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Uppercase card caption (`.cap` in the design).
  static TextStyle get caption => body(
        11,
        weight: FontWeight.w700,
        color: VeloraColors.caption,
        letterSpacing: 1.1,
      );

  static TextStyle get title => body(14.5, weight: FontWeight.w700);
  static TextStyle get subtitle => body(12.5, color: VeloraColors.muted);
  static TextStyle get link =>
      body(13, weight: FontWeight.w700, color: VeloraColors.teal);
}

class VeloraRadii {
  VeloraRadii._();

  static const double card = 18;
  static const double button = 14;
  static const double tile = 12;
  static const double field = 14;
  static const double sheet = 26;
}

class VeloraShadows {
  VeloraShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0A1E1A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0A1E1A), blurRadius: 28, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> tabBar = [
    BoxShadow(color: Color(0x470A1E1A), blurRadius: 30, offset: Offset(0, 12)),
  ];
}

/// Page gutters and gaps.
class VeloraSpacing {
  VeloraSpacing._();

  static const double gutter = 16;
  static const double gap = 14;

  /// Max width of page content, header text, tab bar and toasts. Unbounded:
  /// on tablets every screen uses the full width. Set a number (e.g. 640)
  /// to bring back a centred phone-width column.
  static const double maxContentWidth = double.infinity;

  /// Bottom padding for scroll views that sit under the floating tab bar.
  static double tabBarClearance(BuildContext context) =>
      112 + MediaQuery.paddingOf(context).bottom;
}
