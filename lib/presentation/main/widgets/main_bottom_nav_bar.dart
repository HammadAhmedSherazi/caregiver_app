import 'package:flutter/material.dart';

import '../../widgets/velora/velora.dart';

/// Bottom tabs from the VELORA design: Home · Time · Check-in · Pay · Docs.
enum MainTab { home, time, checkIn, pay, docs }

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MainTab selectedTab;
  final ValueChanged<MainTab> onTabSelected;

  static const _items = [
    VeloraTabItem(icon: VeloraIcons.home, label: 'Home'),
    VeloraTabItem(icon: VeloraIcons.clock, label: 'Time'),
    VeloraTabItem(icon: VeloraIcons.clipboardCheck, label: 'Check-in'),
    VeloraTabItem(icon: VeloraIcons.wallet, label: 'Pay'),
    VeloraTabItem(icon: VeloraIcons.folder, label: 'Docs'),
  ];

  @override
  Widget build(BuildContext context) {
    return VeloraTabBar(
      items: _items,
      selectedIndex: selectedTab.index,
      onSelected: (index) => onTabSelected(MainTab.values[index]),
    );
  }
}
