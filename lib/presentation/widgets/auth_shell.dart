import 'package:flutter/material.dart';

import 'responsive/adaptive_form_page.dart';

/// Thin wrapper around [AdaptiveFormPage] for auth screens.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.footer,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AdaptiveFormPage(
      title: title,
      subtitle: subtitle,
      footer: footer,
      child: child,
    );
  }
}
