import 'package:flutter/material.dart';

import '../../../core/theme/velora_theme.dart';
import 'velora_icon.dart';

class VeloraTabItem {
  const VeloraTabItem({required this.icon, required this.label});

  final VeloraIcons icon;
  final String label;
}

/// Floating dark tab bar with amber active icon and dot (`.tabbar`).
class VeloraTabBar extends StatelessWidget {
  const VeloraTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<VeloraTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset * 0.55 : 14,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeloraSpacing.maxContentWidth - 32,
          ),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: VeloraColors.brandDark,
              borderRadius: BorderRadius.circular(22),
              boxShadow: VeloraShadows.tabBar,
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _TabButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final VeloraTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VeloraIcon(
              item.icon,
              size: 22,
              strokeWidth: 1.8,
              color: selected ? VeloraColors.amber : VeloraColors.tabInactive,
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: VeloraText.body(
                  11,
                  weight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? VeloraColors.tabActive
                      : VeloraColors.tabInactive,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: VeloraColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
