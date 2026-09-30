import 'package:caregiver_app/data/models/api/compliance_form_model.dart';
import 'package:caregiver_app/data/models/api/velora/velora_models.dart';
import 'package:caregiver_app/data/repositories/task_repository.dart';
import 'package:caregiver_app/presentation/checkin/view/checkin_days_flow.dart';
import 'package:caregiver_app/presentation/task/cubit/task_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Only the planned check-in draft / submit calls are exercised here.
class _FakeRepository implements TaskRepository {
  CheckInDraftRequest? draft;
  CheckInSubmitRequest? submitted;

  @override
  Future<ComplianceFormDetailModel> saveCheckInDraft(int formId, CheckInDraftRequest request) async {
    draft = request;
    return _detail(CheckInMode.clocks);
  }

  @override
  Future<ComplianceFormDetailModel> submitCheckIn(int formId, CheckInSubmitRequest request) async {
    submitted = request;
    return ComplianceFormDetailModel.fromJson({
      'id': formId,
      'period_label': 'September 2026',
      'status': 'Submitted',
      'submitted': true,
      'questions': const [],
      'counts': {'worked': 20, 'not_worked': 7, 'hospital': 3},
      'pay': {'pay_label': 'Fri, Oct 16', 'on_track': true},
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// September 2026: weekdays worked, weekends off (clock-in mode) or every
/// day worked (live-in), with a Sep 20 – 22 hospital stay pre-filled.
ComplianceFormDetailModel _detail(CheckInMode mode, {bool prefillHospital = true}) {
  final clocks = mode == CheckInMode.clocks;
  final start = mode == CheckInMode.liveInMich ? 16 : 1;
  return ComplianceFormDetailModel(
    id: 7,
    periodLabel: 'September 2026',
    status: 'Due',
    submitted: false,
    questions: const [],
    velora: ComplianceFormExtensionModel(mode: mode),
    checkIn: CheckInDetailModel(
      hoursPerDayEstimate: 5.8,
      prefill: clocks
          ? CheckInAnswers(
              hospital: prefillHospital
                  ? HospitalStayModel(wasInHospital: true, from: DateTime(2026, 9, 20), to: DateTime(2026, 9, 22))
                  : const HospitalStayModel.none(),
              careNotGiven: CheckInYesNoAnswer.no,
              missedOrLate: CheckInYesNoAnswer.no,
            )
          : null,
      days: [
        for (var d = start; d <= 30; d++)
          CheckInDayModel(
            date: DateTime(2026, 9, d),
            state: !clocks || DateTime(2026, 9, d).weekday <= 5 ? CheckInDayState.worked : CheckInDayState.notWorked,
          ),
      ],
    ),
  );
}

Future<void> _pump(WidgetTester tester, TaskCubit cubit, ComplianceFormDetailModel detail) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: CheckInDaysFlow(
          formId: 7,
          periodLabel: 'September 2026',
          detail: detail,
          checkIn: detail.checkIn!,
          clientName: 'Robert Ellison',
          initialName: 'Michael Rodriguez',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The "Worked / Not worked / Hospital" count tiles, in that order.
List<String> _counts(WidgetTester tester) {
  final labels = ['Worked', 'Not worked', 'Hospital'];
  return [
    for (final l in labels)
      (tester.widget<Text>(find
              .descendant(
                of: find.ancestor(of: find.text(l).last, matching: find.byType(Column)).first,
                matching: find.byType(Text),
              )
              .first))
          .data!,
  ];
}

void main() {
  late _FakeRepository repo;
  late TaskCubit cubit;

  setUp(() {
    repo = _FakeRepository();
    cubit = TaskCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  testWidgets('clock-in mode: prefilled answers, hospital days locked on the calendar, typed-name submit',
      (tester) async {
    await _pump(tester, cubit, _detail(CheckInMode.clocks));

    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.textContaining('Filled in from your answers'), findsOneWidget);
    expect(find.textContaining('(3 days) will be marked as hospital days'), findsOneWidget);

    await _tapButton(tester, 'Continue');
    expect(find.text('Your days'), findsOneWidget);
    // 22 weekdays in Sep 2026, 3 of them (20 is a Sunday) become hospital:
    // Mon 21 + Tue 22 were worked, Sun 20 was off.
    expect(_counts(tester), ['20', '7', '3']);
    expect(find.textContaining('about 11.6 hrs'), findsOneWidget);

    // Hospital days can't be tapped away.
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    expect(_counts(tester), ['20', '7', '3']);

    // Tue Sep 1: worked → not worked.
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(_counts(tester), ['19', '8', '3']);

    await _tapButton(tester, 'Continue');
    expect(find.text('Confirm to submit'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Submit check-in');

    final sent = repo.submitted!;
    expect(sent.signatureName, 'Michael Rodriguez');
    expect(sent.confirmed, isTrue);
    expect(sent.answers.hospital!.wasInHospital, isTrue);
    expect(sent.changedDays, [CheckInDayModel(date: DateTime(2026, 9, 1), state: CheckInDayState.notWorked)]);

    expect(find.text('Check-in sent'), findsOneWidget);
    expect(find.text('You\'re on track to be paid Fri, Oct 16.'), findsOneWidget);
  });

  testWidgets('live-in MICH: nothing prefilled, days outside the half-month are greyed', (tester) async {
    await _pump(tester, cubit, _detail(CheckInMode.liveInMich));

    expect(find.text('Answer all 3 to continue'), findsOneWidget);
    expect(find.textContaining('from Sep 16 to Sep 30'), findsOneWidget);
    for (final no in find.text('No').evaluate().toList()) {
      await tester.ensureVisible(find.byWidget(no.widget));
      await tester.tap(find.byWidget(no.widget));
    }
    await tester.pumpAndSettle();

    await _tapButton(tester, 'Continue');
    expect(_counts(tester), ['15', '0', '0']);
    expect(find.text('Live-in: every day is marked worked unless you change it.'), findsOneWidget);

    // Sep 3 is outside the MICH period: tapping it changes nothing.
    await tester.tap(find.text('3').first);
    await tester.pumpAndSettle();
    expect(_counts(tester), ['15', '0', '0']);
  });

  testWidgets('Yes without details blocks Continue; Save & exit sends a draft', (tester) async {
    await _pump(tester, cubit, _detail(CheckInMode.clocks, prefillHospital: false));

    await tester.tap(find.text('Yes').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Add details to continue'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Sep 9, no ride to the pharmacy');
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Save & exit'));
    await tester.pumpAndSettle();
    final draft = repo.draft!;
    expect(draft.answers!.careNotGiven!.answer, isTrue);
    expect(draft.answers!.careNotGiven!.details, 'Sep 9, no ride to the pharmacy');
  });
}
