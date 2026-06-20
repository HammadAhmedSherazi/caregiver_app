import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Generic auth text field with SVG prefix icon (Figma).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    this.prefixIconAsset,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.inputFormatters,
  });

  final String hint;
  final String? prefixIconAsset;
  final TextEditingController? controller;
  final bool readOnly;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final hasPrefixIcon = prefixIconAsset != null;

    return SizedBox(
      height: 60,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: AppTextStyles.authFieldInput,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.authFieldHint,
          filled: true,
          fillColor: AppColors.authOnGradient,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            vertical: 18,
            horizontal: hasPrefixIcon ? 0 : 19,
          ),
          prefixIcon: hasPrefixIcon
              ? Padding(
                  padding: const EdgeInsets.only(left: 19, right: 13),
                  child: SvgPicture.asset(
                    prefixIconAsset!,
                    width: 24,
                    height: 24,
                  ),
                )
              : null,
          prefixIconConstraints: hasPrefixIcon
              ? const BoxConstraints(minWidth: 56, minHeight: 24)
              : null,
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
