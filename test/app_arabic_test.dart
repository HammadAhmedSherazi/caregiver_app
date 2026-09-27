import 'dart:convert';
import 'dart:io';

import 'package:caregiver_app/core/di/service_locator.dart';
import 'package:caregiver_app/core/i18n/tr.dart';
import 'package:caregiver_app/core/utils/velora_format.dart';
import 'package:caregiver_app/data/local/language_store.dart';
import 'package:caregiver_app/presentation/main/widgets/main_bottom_nav_bar.dart';
import 'package:caregiver_app/presentation/widgets/velora/velora.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every literal passed to tr('…') in lib/ — the guard below fails when a
/// new on-screen string is added without Arabic.
Set<String> _trLiterals() {
  final keys = <String>{};
  final pattern = RegExp(r"""\btr\(\s*'((?:[^'\\\n]|\\.)*)'""");
  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      keys.add(m.group(1)!.replaceAllMapped(
          RegExp(r'\\(.)'), (e) => e.group(1) == 'n' ? '\n' : e.group(1)!));
    }
  }
  return keys;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  tearDown(() => sl<LanguageStore>().set('en'));

  test('every tr() string in the app has an Arabic translation', () {
    final ar = (jsonDecode(File('assets/i18n/ar.json').readAsStringSync())
        as Map<String, dynamic>)['ui'] as Map<String, dynamic>;
    final missing = _trLiterals().where((k) => !ar.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'add these to the "ui" section of ar.json');
  });

  test('tr() follows the chosen language and fills placeholders', () async {
    expect(tr('Report a change'), 'Report a change');
    await sl<LanguageStore>().set('ar');
    expect(tr('Report a change'), 'الإبلاغ عن تغيير');
    expect(tr('Your visits with {0}', ['Robert']), 'زياراتك مع Robert');
    expect(tr('Not in the table yet'), 'Not in the table yet');
  });

  test('dates and times switch to Arabic', () async {
    await sl<LanguageStore>().set('ar');
    final d = DateTime(2026, 9, 25, 15, 10);
    expect(VeloraFormat.shortDate(d), 'الجمعة، سبتمبر 25'.replaceAll('،', ','));
    expect(VeloraFormat.time(d), '3:10 م');
    expect(VeloraFormat.duration(const Duration(hours: 6, minutes: 8)), '6س 08د');
  });

  testWidgets('tab bar and error card render in Arabic, right-to-left', (tester) async {
    await sl<LanguageStore>().set('ar');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: VeloraErrorState(onRetry: () {}),
        bottomNavigationBar: MainBottomNavBar(
          selectedTab: MainTab.home,
          onTabSelected: (_) {},
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الراتب'), findsOneWidget);
    expect(find.text('حدث خطأ ما'), findsOneWidget);
    expect(find.text('حاول مجدداً'), findsOneWidget);
    final ctx = tester.element(find.text('الرئيسية'));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });
}
