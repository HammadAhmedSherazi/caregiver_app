import 'package:caregiver_app/core/utils/velora_format.dart';
import 'package:caregiver_app/data/models/api/velora/velora_models.dart';
import 'package:caregiver_app/data/repositories/visit_repository.dart';
import 'package:caregiver_app/presentation/time/cubit/time_cubit.dart';
import 'package:caregiver_app/presentation/time/view/time_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoRepository implements VisitRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Seeds the Time tab with the planned `/time/week` and `/time/month`
/// payloads (the planned API is off in tests, so `load()` never fetches them).
class _SeededTimeCubit extends TimeCubit {
  _SeededTimeCubit(TimeState seed) : super(repository: _NoRepository()) {
    emit(seed);
  }

  @override
  Future<void> load() async {}
}

TimeWeekModel _setDaysWeek() => TimeWeekModel.fromJson({
      'week_start': '2026-09-21',
      'week_end': '2026-09-27',
      'label': 'Sep 21 – 27',
      'plan': {'type': 'set_days', 'set_days': ['mon', 'wed', 'fri'], 'label': 'Robert\'s plan: Mon, Wed and Fri'},
      'summary': {'days_done': 1, 'days_of': 3, 'hours_label': '5h 32m'},
      'days': [
        {'date': '2026-09-25', 'weekday_short': 'Fri', 'day_number': 25, 'is_today': true, 'is_set_day': true,
          'state': 'not_started', 'state_label': 'Not started'},
        {'date': '2026-09-24', 'weekday_short': 'Thu', 'day_number': 24, 'is_set_day': false,
          'state': 'not_set_day', 'state_label': 'Not a set day'},
        {'date': '2026-09-23', 'weekday_short': 'Wed', 'day_number': 23, 'is_set_day': true,
          'state': 'missed', 'state_label': 'Missed'},
        {'date': '2026-09-21', 'weekday_short': 'Mon', 'day_number': 21, 'is_set_day': true,
          'state': 'sent', 'state_label': 'Sent',
          'visit': {'id': 9, 'clock_in_at': '2026-09-21T08:58:00', 'clock_out_at': '2026-09-21T14:30:00',
            'hours_label': '5h 32m', 'services_label': 'Dressing, laundry'}},
      ],
    });

Future<void> _pump(WidgetTester tester, TimeState state) async {
  tester.view.physicalSize = const Size(1170, 3200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final cubit = _SeededTimeCubit(state);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider<TimeCubit>.value(value: cubit, child: const MaterialApp(home: Scaffold(body: TimeTabView()))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('set-days plan: set days done, off days, and a missed set day asks why', (tester) async {
    await _pump(tester, TimeState(status: TimeStatus.success, week: _setDaysWeek()));

    expect(find.text('SET DAYS DONE'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.textContaining('Robert\'s plan: Mon, Wed and Fri'), findsOneWidget);
    expect(find.text('Not a set day'), findsOneWidget);
    expect(find.text('Set day · no visit'), findsOneWidget);
    expect(find.text('Tell us why'), findsOneWidget);
    expect(find.text('Set day · today'), findsOneWidget);
    expect(find.text('Clock in from Home'), findsOneWidget);
    expect(find.text('5h 32m · Dressing, laundry'), findsOneWidget);
  });

  testWidgets('any-days plan keeps the visit-based week', (tester) async {
    final anyDays = TimeWeekModel.fromJson({
      'label': 'Sep 21 – 27',
      'plan': {'type': 'any_days', 'days_per_week': 5},
      'summary': {'days_done': 3},
      'days': const [],
    });
    await _pump(tester, TimeState(status: TimeStatus.success, week: anyDays));

    expect(find.text('SET DAYS DONE'), findsNothing);
    expect(find.text('DAYS WORKED'), findsOneWidget);
  });

  testWidgets('month view shows the client\'s approved hours', (tester) async {
    final month = TimeMonthModel.fromJson({
      'month': '2026-09',
      'label': 'September 2026',
      'days_worked': 18,
      'approved_hours': {'limit': 120, 'used': 104.8, 'remaining': 15.2, 'percent_used': 87},
    });
    await _pump(tester, TimeState(status: TimeStatus.success, month: month));
    await tester.tap(find.text(VeloraFormat.monthName(DateTime.now().month)).first);
    await tester.pumpAndSettle();

    expect(find.text('APPROVED HOURS'), findsOneWidget);
    expect(find.text('104.8 of 120 hrs'), findsOneWidget);
    expect(find.textContaining('15.2 hours left this month'), findsOneWidget);
  });
}
