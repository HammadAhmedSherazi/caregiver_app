import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Generic auth text field with SVG prefix icon (Figma).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    required this.prefixIconAsset,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String hint;
  final String prefixIconAsset;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.authDarkText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.authFieldHint,
          filled: true,
          fillColor: AppColors.authOnGradient,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 19, right: 13),
            child: SvgPicture.asset(
              prefixIconAsset,
              width: 24,
              height: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }
}
