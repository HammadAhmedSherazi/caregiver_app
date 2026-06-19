import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';

/// Generic list ↔ grid switcher.
/// Mobile: vertical list. Tablet/large: responsive grid.
class AdaptiveListGrid extends StatelessWidget {
  const AdaptiveListGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.listSeparatorHeight = 12,
    this.gridMaxCrossAxisExtent = 360,
    this.gridMainAxisExtent = 160,
    this.gridSpacing = 16,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double listSeparatorHeight;
  final double gridMaxCrossAxisExtent;
  final double gridMainAxisExtent;
  final double gridSpacing;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isCompact(context)) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: listSeparatorHeight),
        itemBuilder: itemBuilder,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: gridMaxCrossAxisExtent,
        mainAxisExtent: gridMainAxisExtent,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
