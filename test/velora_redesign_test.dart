import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caregiver_app/core/utils/velora_format.dart';
import 'package:caregiver_app/data/models/api/visit_model.dart';
import 'package:caregiver_app/presentation/time/visit_summary.dart';
import 'package:caregiver_app/presentation/widgets/velora/velora.dart';

VisitModel _visit({
  required int id,
  required DateTime clockIn,
  DateTime? clockOut,
  String status = 'Completed',
  double? hours,
}) {
  return VisitModel(
    id: id,
    clientId: 1,
    clientName: 'Robert Ellison',
    status: status,
    clockInAt: clockIn,
    clockOutAt: clockOut,
    totalHours: hours,
  );
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('VeloraFormat', () {
    test('formats times, dates and durations', () {
      final d = DateTime(2026, 9, 25, 15, 10);
      expect(VeloraFormat.time(d), '3:10 PM');
      expect(VeloraFormat.time(DateTime(2026, 9, 25, 0, 5)), '12:05 AM');
      expect(VeloraFormat.longDate(d), 'Friday, September 25');
      expect(VeloraFormat.shortDate(d), 'Fri, Sep 25');
      expect(VeloraFormat.duration(const Duration(hours: 6, minutes: 8)), '6h 08m');
      expect(VeloraFormat.timer(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(VeloraFormat.initials('Robert  Ellison'), 'RE');
      expect(VeloraFormat.firstName('  Michael Rodriguez '), 'Michael');
      expect(VeloraFormat.startOfWeek(d), DateTime(2026, 9, 21));
    });
  });

  group('VisitPeriodSummary', () {
    test('counts worked days, totals and missing clock-outs', () {
      final monday = VeloraFormat.startOfWeek(DateTime.now());
      final visits = [
        _visit(
          id: 1,
          clockIn: monday.add(const Duration(hours: 9)),
          clockOut: monday.add(const Duration(hours: 14, minutes: 30)),
        ),
        // Clock never stopped on a past day → needs a fix.
        _visit(
          id: 2,
          clockIn: monday.subtract(const Duration(days: 7)).add(const Duration(hours: 9)),
          status: 'Clocked in',
        ),
        _visit(
          id: 3,
          clockIn: monday.add(const Duration(days: 1, hours: 9)),
          status: 'Missed',
        ),
      ];

      final week = VisitPeriodSummary.week(visits);
      expect(week.days, hasLength(7));
      expect(week.daysWorked, 1);
      expect(week.total, const Duration(hours: 5, minutes: 30));

      expect(visits[1].isMissingClockOut, isTrue);
      expect(visits[2].isMissingClockOut, isTrue);
      expect(visits[0].isMissingClockOut, isFalse);
    });

    test('prefers total_hours from the API when present', () {
      final v = _visit(
        id: 1,
        clockIn: DateTime(2026, 9, 21, 9),
        clockOut: DateTime(2026, 9, 21, 17),
        hours: 7.5,
      );
      expect(v.worked, const Duration(hours: 7, minutes: 30));
    });

    test('a visit clocked in today and still running is not a missed clock-out', () {
      final v = _visit(id: 1, clockIn: DateTime.now(), status: 'Clocked in');
      expect(v.isMissingClockOut, isFalse);
      expect(v.isOpenToday, isTrue);
    });
  });

  group('Velora components', () {
    testWidgets('YesNoToggle reports the tapped answer', (tester) async {
      bool? answer;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => YesNoToggle(
                value: answer,
                onChanged: (v) => setState(() => answer = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Yes'));
      await tester.pump();
      expect(answer, isTrue);
      await tester.tap(find.text('No'));
      await tester.pump();
      expect(answer, isFalse);
    });

    testWidgets('VeloraButton ignores taps when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(const VeloraButton(label: 'Clock out', onPressed: null)));
      await tester.tap(find.text('Clock out'));
      expect(taps, 0);

      await tester.pumpWidget(_host(VeloraButton(label: 'Clock out', onPressed: () => taps++)));
      await tester.tap(find.text('Clock out'));
      expect(taps, 1);
    });

    testWidgets('VeloraTabBar selects the tapped tab', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: VeloraTabBar(
              items: const [
                VeloraTabItem(icon: VeloraIcons.home, label: 'Home'),
                VeloraTabItem(icon: VeloraIcons.clock, label: 'Time'),
                VeloraTabItem(icon: VeloraIcons.wallet, label: 'Pay'),
              ],
              selectedIndex: selected,
              onSelected: (i) => selected = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pay'));
      expect(selected, 2);
    });

    testWidgets('VeloraHeader shows back button only for pushed pages', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: VeloraHeader(title: 'Pay'))));
      expect(find.bySemanticsLabel('Back'), findsNothing);

      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeloraHeader(title: 'Paystub', onBack: () => popped = true),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      expect(popped, isTrue);
    });

    testWidgets('API-required sheet never claims the data was sent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showApiRequiredSheet(context, feature: 'Change reports'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Not connected yet'), findsOneWidget);
      expect(find.textContaining('Nothing was sent'), findsOneWidget);
    });
  });
}
