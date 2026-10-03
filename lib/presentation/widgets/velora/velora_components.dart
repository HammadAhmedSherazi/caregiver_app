import 'package:flutter/material.dart';

import '../../../core/theme/velora_theme.dart';
import 'velora_icon.dart';
import '../../../core/i18n/tr.dart';

/// White rounded card with the soft two-layer shadow (`.card`).
class VeloraCard extends StatelessWidget {
  const VeloraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = VeloraColors.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(VeloraRadii.card);
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: VeloraColors.line),
        boxShadow: VeloraShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Uppercase caption with an optional trailing widget on the same line.
class SectionCaption extends StatelessWidget {
  const SectionCaption(
    this.text, {
    super.key,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(), style: VeloraText.caption),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Inline text button in teal (`See hours`, `See all`, …).
class VeloraTextLink extends StatelessWidget {
  const VeloraTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 12.5,
    this.color = VeloraColors.teal,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final VeloraIcons? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                VeloraIcon(icon!, size: 17, color: color, strokeWidth: 2),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: VeloraText.body(size, weight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum VeloraButtonVariant { primary, ghost, outline, amber, danger }

/// Full-width action button (`.btn`, `.btn.ghost`, `.btn.out`, `.btn.big`).
class VeloraButton extends StatelessWidget {
  const VeloraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VeloraButtonVariant.primary,
    this.icon,
    this.big = false,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final VeloraButtonVariant variant;
  final VeloraIcons? icon;
  final bool big;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final (bg, fg, iconColor, border) = switch (variant) {
      VeloraButtonVariant.primary => (
          enabled ? VeloraColors.brand : VeloraColors.disabled,
          Colors.white,
          VeloraColors.amber,
          null,
        ),
      VeloraButtonVariant.ghost => (
          Colors.white,
          VeloraColors.ink,
          VeloraColors.teal,
          const BorderSide(color: VeloraColors.fieldBorder),
        ),
      VeloraButtonVariant.outline => (
          Colors.white,
          VeloraColors.brand,
          VeloraColors.brand,
          const BorderSide(color: VeloraColors.brand, width: 2),
        ),
      VeloraButtonVariant.amber => (
          VeloraColors.amber,
          VeloraColors.amberInk,
          VeloraColors.amberInk,
          null,
        ),
      VeloraButtonVariant.danger => (
          enabled ? VeloraColors.dangerText : VeloraColors.disabled,
          Colors.white,
          Colors.white,
          null,
        ),
    };
    final radius = BorderRadius.circular(big ? 16 : VeloraRadii.button);

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                VeloraIcon(icon!, size: 18, color: iconColor, strokeWidth: 2),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: VeloraText.body(
                    big ? 17 : 15,
                    weight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: border ?? BorderSide.none,
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: big ? 60 : 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PillTone { good, warn, info, mute, danger }

/// Small rounded status label (`.pill`).
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.info});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      PillTone.good => (VeloraColors.goodText, VeloraColors.goodBg),
      PillTone.warn => (VeloraColors.warnText, VeloraColors.warnBg),
      PillTone.info => (VeloraColors.brand, VeloraColors.mint),
      PillTone.mute => (VeloraColors.muted, VeloraColors.muteBg),
      PillTone.danger => (VeloraColors.dangerText, VeloraColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: VeloraText.body(11, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

enum IconTileTone { mint, amber, danger, good, mute, brand }

/// Rounded square holding an icon (`.ico`).
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.tone = IconTileTone.mint,
    this.size = 40,
    this.iconSize = 19,
    this.radius = 12,
  });

  final VeloraIcons icon;
  final IconTileTone tone;
  final double size;
  final double iconSize;
  final double radius;

  static (Color, Color) colors(IconTileTone tone) => switch (tone) {
        IconTileTone.mint => (VeloraColors.mint, VeloraColors.teal),
        IconTileTone.amber => (VeloraColors.amberSoft, VeloraColors.amberIcon),
        IconTileTone.danger => (VeloraColors.dangerBg, VeloraColors.dangerText),
        IconTileTone.good => (VeloraColors.goodBg, VeloraColors.goodText),
        IconTileTone.mute => (VeloraColors.muteBg, VeloraColors.muted),
        IconTileTone.brand => (VeloraColors.brand, VeloraColors.amber),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colors(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: VeloraIcon(icon, size: iconSize, color: fg),
    );
  }
}

/// Initials square used for clients (`RE`).
class InitialsTile extends StatelessWidget {
  const InitialsTile(
    this.initials, {
    super.key,
    this.size = 50,
    this.dark = false,
  });

  final String initials;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? VeloraColors.brand : VeloraColors.mint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: VeloraText.display(
          size * 0.32,
          color: dark ? Colors.white : VeloraColors.teal,
        ),
      ),
    );
  }
}

/// Divider-separated row with leading tile, two lines of text and chevron.
class VeloraListRow extends StatelessWidget {
  const VeloraListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.showChevron = true,
    this.titleColor,
    this.subtitleColor,
    this.minHeight = 56,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showChevron;
  final Color? titleColor;
  final Color? subtitleColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: VeloraText.body(
                      14,
                      weight: FontWeight.w700,
                      color: titleColor ?? VeloraColors.ink,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: VeloraText.body(
                        12.5,
                        color: subtitleColor ?? VeloraColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (showChevron && onTap != null) ...[
              const SizedBox(width: 8),
              const VeloraIcon(
                VeloraIcons.chevronRight,
                size: 16,
                color: VeloraColors.chevron,
                strokeWidth: 2.2,
              ),
            ],
          ],
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: VeloraColors.line))
            : null,
      ),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

/// Label / value row separated by hairlines (`.kv`, `.ln`).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool showDivider;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: VeloraColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: VeloraText.body(
                14,
                weight: emphasize ? FontWeight.w700 : FontWeight.w400,
                color: emphasize ? VeloraColors.ink : VeloraColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: VeloraText.body(
                14,
                weight: emphasize ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? VeloraColors.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-option No / Yes selector (`.yn`).
class YesNoToggle extends StatelessWidget {
  const YesNoToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _option(tr('No'), value == false, () => onChanged(false))),
        const SizedBox(width: 8),
        Expanded(child: _option(tr('Yes'), value == true, () => onChanged(true))),
      ],
    );
  }

  Widget _option(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? VeloraColors.brand : VeloraColors.subtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? VeloraColors.brand : VeloraColors.fieldBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                label,
                style: VeloraText.body(
                  14,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : VeloraColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggleable chip (`.chip`, `.opt`).
class VeloraChoiceChip extends StatelessWidget {
  const VeloraChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? VeloraColors.mint : VeloraColors.subtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(
            color: selected ? VeloraColors.teal : VeloraColors.fieldBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (showCheck) ...[
                    VeloraIcon(
                      selected ? VeloraIcons.check : VeloraIcons.plus,
                      size: 14,
                      strokeWidth: 2.4,
                      color: selected ? VeloraColors.brandDark : VeloraColors.muted,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: VeloraText.body(
                        13.5,
                        weight: FontWeight.w600,
                        color: selected ? VeloraColors.brandDark : VeloraColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labeled input field (`.fld`).
class VeloraTextField extends StatelessWidget {
  const VeloraTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.enabled = true,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final bool enabled;

  static InputDecoration decoration({String? hint, Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(VeloraRadii.field),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: VeloraText.body(15, color: VeloraColors.faint),
      filled: true,
      fillColor: VeloraColors.subtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      suffixIcon: suffix,
      border: border(VeloraColors.fieldBorder),
      enabledBorder: border(VeloraColors.fieldBorder),
      disabledBorder: border(VeloraColors.line),
      focusedBorder: border(VeloraColors.teal, 2),
      errorBorder: border(VeloraColors.dangerText),
      focusedErrorBorder: border(VeloraColors.dangerText, 2),
      errorStyle: VeloraText.body(12, color: VeloraColors.dangerText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
          ),
          const SizedBox(height: 7),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          autofillHints: autofillHints,
          readOnly: readOnly,
          onTap: onTap,
          enabled: enabled,
          style: VeloraText.body(15),
          decoration: decoration(hint: hint, suffix: suffix),
        ),
      ],
    );
  }
}

/// Amber callout box with an info icon (`.note` inside `.adj`).
class VeloraNote extends StatelessWidget {
  const VeloraNote({
    super.key,
    required this.text,
    this.icon = VeloraIcons.info,
    this.boxed = true,
    this.color = VeloraColors.body,
  });

  final String text;
  final VeloraIcons icon;
  final bool boxed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: VeloraIcon(icon, size: 16, color: VeloraColors.amberIcon, strokeWidth: 2.2),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text, style: VeloraText.body(12.5, color: color, height: 1.45)),
        ),
      ],
    );
    if (!boxed) return content;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VeloraColors.noteBg,
        border: Border.all(color: VeloraColors.noteBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }
}

/// Thin rounded progress bar.
class VeloraProgressBar extends StatelessWidget {
  const VeloraProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = VeloraColors.teal,
    this.track = VeloraColors.muteBg,
  });

  final double value;
  final double height;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

/// Success / confirmation card used at the end of flows.
class VeloraDoneCard extends StatelessWidget {
  const VeloraDoneCard({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
    this.icon = VeloraIcons.check,
    this.tone = IconTileTone.good,
    this.details,
  });

  final String title;
  final String message;
  final List<Widget> actions;
  final VeloraIcons icon;
  final IconTileTone tone;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: Column(
        children: [
          IconTile(icon, tone: tone, size: 66, iconSize: 30, radius: 21),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: VeloraText.display(22)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: VeloraText.body(14, color: VeloraColors.muted, height: 1.5),
          ),
          if (details != null) ...[const SizedBox(height: 10), details!],
          for (final action in actions) ...[const SizedBox(height: 10), action],
        ],
      ),
    );
  }
}
