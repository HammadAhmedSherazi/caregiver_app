import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons taken from the VELORA design (24×24 viewBox, `currentColor`).
enum VeloraIcons {
  home('<path d="M4 11l8-7 8 7v8.5a1.5 1.5 0 01-1.5 1.5H15v-6H9v6H5.5A1.5 1.5 0 014 19.5z"/>'),
  clock('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>'),
  clipboardCheck(
      '<rect x="5" y="4.5" width="14" height="16.5" rx="2.5"/><path d="M9.5 3h5v3h-5z"/><path d="M9 13.5l2 2 4-4"/>'),
  wallet('<rect x="3" y="6" width="18" height="13" rx="2.5"/><circle cx="12" cy="12.5" r="2.5"/>'),
  folder(
      '<path d="M3.5 7.5a2 2 0 012-2h3.8l2 2h7.2a2 2 0 012 2v8a2 2 0 01-2 2h-13a2 2 0 01-2-2z"/>'),
  bell('<path d="M6 9a6 6 0 1112 0c0 5 2 6.5 2 6.5H4S6 14 6 9z"/><path d="M10 19a2 2 0 004 0"/>'),
  user('<circle cx="12" cy="9" r="3.6"/><path d="M5.5 19.5c1.2-3 3.6-4.5 6.5-4.5s5.3 1.5 6.5 4.5"/>'),
  chevronRight('<path d="M9 6l6 6-6 6"/>'),
  chevronLeft('<path d="M15 6l-6 6 6 6"/>'),
  check('<path d="M5 12.5l4.5 4.5L19 7.5"/>'),
  close('<path d="M6 6l12 12M18 6L6 18"/>'),
  pin('<path d="M12 21s-7-6-7-11a7 7 0 0114 0c0 5-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>'),
  alertCircle('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12"/><path d="M12 15.5v.5"/>'),
  info('<circle cx="12" cy="12" r="8.5"/><path d="M12 8v4.5M12 16v.5"/>'),
  idCard(
      '<rect x="3" y="5.5" width="18" height="13" rx="2.5"/><circle cx="8.5" cy="11" r="2"/><path d="M13 10h4.5M13 13.5h3"/>'),
  document('<path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h4"/>'),
  documentPlain('<path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/>'),
  phone(
      '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 005 5L15 13l5 2v4a2 2 0 01-2 2A16 16 0 013 6a2 2 0 012-2z"/>'),
  globe(
      '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.3 3.5 5.2 3.5 8.5s-1 6.2-3.5 8.5c-2.5-2.3-3.5-5.2-3.5-8.5s1-6.2 3.5-8.5z"/>'),
  faceId(
      '<path d="M4 8V6a2 2 0 012-2h2M16 4h2a2 2 0 012 2v2M20 16v2a2 2 0 01-2 2h-2M8 20H6a2 2 0 01-2-2v-2"/><path d="M9 10v1M15 10v1M9.5 16c1.5 1 3.5 1 5 0"/>'),
  /// Face ID with the nose line, as on the sign-in buttons.
  faceIdScan(
      '<path d="M4 8V6a2 2 0 012-2h2M16 4h2a2 2 0 012 2v2M20 16v2a2 2 0 01-2 2h-2M8 20H6a2 2 0 01-2-2v-2"/><path d="M9 10v1M15 10v1M12 10v3.5h-1M9.5 16c1.5 1 3.5 1 5 0"/>'),
  mobile('<rect x="7" y="3" width="10" height="18" rx="2.5"/><path d="M11 17.5h2"/>'),
  question('<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.5a2.5 2.5 0 014.8.9c0 1.7-2.4 2.2-2.4 3.6M12 17v.3"/>'),
  shield('<path d="M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6z"/>'),
  logout('<path d="M14 4h4a2 2 0 012 2v12a2 2 0 01-2 2h-4M10 16l-4-4 4-4M6 12h10"/>'),
  warning('<path d="M12 3.5l9 16H3z"/><path d="M12 10v4M12 17v.5"/>'),
  hospital('<path d="M4 21V7l8-4 8 4v14"/><path d="M9 21v-5h6v5"/><path d="M12 7v5M9.5 9.5h5"/>'),
  pulse('<path d="M20 12h-4l-3 7-4-14-3 7H2"/>'),
  calendar('<path d="M3.5 7.5h17v12h-17z"/><path d="M3.5 11h17M8 4v5M16 4v5"/>'),
  heart('<path d="M12 20s-7-4.5-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.5-7 10-7 10z"/>'),
  dots('<path d="M5 12h.01M12 12h.01M19 12h.01"/>'),
  send('<path d="M4 12l16-8-6 17-3-7z"/>'),
  download('<path d="M12 4v11M7.5 10.5L12 15l4.5-4.5M5 20h14"/>'),
  share('<path d="M12 15V4M8 7.5L12 3.5l4 4M6 11H5v9h14v-9h-1"/>'),
  camera(
      '<path d="M4 8.5A2 2 0 016 6.5h2l1.5-2h5l1.5 2h2a2 2 0 012 2V18a2 2 0 01-2 2H6a2 2 0 01-2-2z"/><circle cx="12" cy="13" r="3.5"/>'),
  plus('<path d="M12 6v12M6 12h12"/>'),
  mail('<path d="M3.5 6.5h17v12h-17z"/><path d="M3.5 7.5l8.5 6 8.5-6"/>'),
  stop('<rect x="6" y="6" width="12" height="12" rx="2.5"/>'),
  message('<path d="M4 5.5h16v11H9l-5 4z"/>'),
  backspace('<path d="M9 5h10a2 2 0 012 2v10a2 2 0 01-2 2H9l-6-7z"/><path d="M12 9.5l5 5M17 9.5l-5 5"/>'),
  eye('<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>'),
  eyeOff('<path d="M3 3l18 18"/><path d="M10.6 5.6A9.7 9.7 0 0112 5.5c6 0 9.5 6.5 9.5 6.5a16 16 0 01-2.7 3.4M6.4 6.4A15.6 15.6 0 002.5 12S6 18.5 12 18.5a9 9 0 004.2-1"/>'),
  lock('<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 018 0v2.5"/>');

  const VeloraIcons(this.paths);

  final String paths;
}

class VeloraIcon extends StatelessWidget {
  const VeloraIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.9,
  });

  final VeloraIcons icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="#000000" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">${icon.paths}</svg>';
    final picture = SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
    // Arrows and "back/next" chevrons point the other way in Arabic (RTL).
    final mirror = _directional.contains(icon) &&
        Directionality.maybeOf(context) == TextDirection.rtl;
    return mirror ? Transform.flip(flipX: true, child: picture) : picture;
  }

  static const _directional = {
    VeloraIcons.chevronRight,
    VeloraIcons.chevronLeft,
    VeloraIcons.send,
    VeloraIcons.logout,
  };
}
