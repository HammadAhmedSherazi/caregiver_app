import 'package:flutter/material.dart';

import '../../../core/theme/velora_theme.dart';

/// Header + scrolling body used by every redesigned screen.
///
/// Tab pages pass [underTabBar] so the list clears the floating tab bar.
/// Pushed pages pass a [header] with a back button and may add a pinned
/// [footer] (e.g. a Back / Continue bar).
class VeloraPage extends StatelessWidget {
  const VeloraPage({
    super.key,
    required this.header,
    required this.children,
    this.onRefresh,
    this.footer,
    this.underTabBar = false,
    this.gap = VeloraSpacing.gap,
    this.padding,
    this.overlay,
  });

  final Widget header;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? footer;
  final bool underTabBar;
  final double gap;
  final EdgeInsetsGeometry? padding;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final bottom = underTabBar
        ? VeloraSpacing.tabBarClearance(context)
        : (footer != null ? 16.0 : 28.0 + MediaQuery.paddingOf(context).bottom);

    Widget list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding ?? EdgeInsets.fromLTRB(16, 16, 16, bottom),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, index) => children[index],
    );

    if (onRefresh != null) {
      list = RefreshIndicator(
        color: VeloraColors.teal,
        onRefresh: onRefresh!,
        child: list,
      );
    }

    return ColoredBox(
      color: VeloraColors.background,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: VeloraSpacing.maxContentWidth),
                    child: list,
                  ),
                ),
              ),
              if (footer != null)
                Container(
                  decoration: const BoxDecoration(
                    color: VeloraColors.background,
                    border: Border(top: BorderSide(color: VeloraColors.line)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: VeloraSpacing.maxContentWidth - 32),
                      child: footer,
                    ),
                  ),
                ),
            ],
          ),
          ?overlay,
        ],
      ),
    );
  }
}

/// Scaffold wrapper for pushed routes.
class VeloraScaffold extends StatelessWidget {
  const VeloraScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloraColors.background,
      body: body,
    );
  }
}
