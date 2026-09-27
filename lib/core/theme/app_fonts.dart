import 'package:flutter/material.dart';

/// Central place for font configuration.
///
/// Body text uses Hanken Grotesk (VELORA redesign). DM Sans remains bundled
/// for any screen that still references it explicitly.
class AppFonts {
  AppFonts._();

  /// Must match the `family` value in [pubspec.yaml].
  static const String fontFamily = 'Hanken Grotesk';

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  static TextStyle base({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }
}
