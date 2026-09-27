import 'package:flutter/material.dart';

import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

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

  // A getter, not a static list: tab labels follow the current language.
  static List<VeloraTabItem> get _items => [
    VeloraTabItem(icon: VeloraIcons.home, label: tr('Home')),
    VeloraTabItem(icon: VeloraIcons.clock, label: tr('Time')),
    VeloraTabItem(icon: VeloraIcons.clipboardCheck, label: tr('Check-in')),
    VeloraTabItem(icon: VeloraIcons.wallet, label: tr('Pay')),
    VeloraTabItem(icon: VeloraIcons.folder, label: tr('Docs')),
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
