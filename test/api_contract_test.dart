import 'package:flutter_test/flutter_test.dart';

import 'package:caregiver_app/core/network/api_client.dart';
import 'package:caregiver_app/core/network/api_error_message.dart';
import 'package:caregiver_app/core/network/api_exception.dart';
import 'package:caregiver_app/core/network/session_expired_notifier.dart';
import 'package:caregiver_app/core/network/token_refresh_handler.dart';
import 'package:caregiver_app/data/api/velora_api.dart';
import 'package:caregiver_app/data/local/language_store.dart';
import 'package:caregiver_app/data/local/session_storage_impl.dart';
import 'package:caregiver_app/data/local/token_storage_impl.dart';
import 'package:caregiver_app/data/models/api/compliance_form_model.dart';
import 'package:caregiver_app/data/models/api/dashboard_model.dart';
import 'package:caregiver_app/data/models/api/document_model.dart';
import 'package:caregiver_app/data/models/api/notification_item_model.dart';
import 'package:caregiver_app/data/models/api/pay_detail_model.dart';
import 'package:caregiver_app/data/models/api/pay_item_model.dart';
import 'package:caregiver_app/data/models/api/velora/velora_models.dart';
import 'package:caregiver_app/data/models/api/visit_model.dart';

/// Samples are copied from MOBILE_API_VELORA.md. Planned endpoints are not
/// live; these tests only check the Flutter side of the contract.
void main() {
  group('Extended endpoints stay backward compatible', () {
    test('today\'s /notifications item parses with no VELORA fields', () {
      final m = NotificationItemModel.fromJson({
        'id': 1,
        'type': 'secure_message',
        'title': 'Hi',
        'body': 'Body',
        'read': false,
        'created_at': '2026-09-23T09:40:00-04:00',
        'time_ago': '2 days ago',
      });
      expect(m.category, isNull);
      expect(m.action, isNull);
    });

    test('VELORA /notifications item exposes category, is_new and action', () {
      final m = NotificationItemModel.fromJson({
        'id': 42,
        'type': 'secure_message',
        'category': 'time',
        'title': 'Tuesday is missing a clock-out',
        'body': 'Tap to add the time you left Robert\'s.',
        'is_new': true,
        'read': false,
        'action': {'screen': 'fix_clockout', 'params': {'visit_id': 123}},
        'created_at': '2026-09-23T09:40:00-04:00',
        'time_ago': '2 days ago',
      });
      expect(m.category, 'time');
      expect(m.isNew, isTrue);
      expect(m.action!.screen, AppScreen.fixClockout);
      expect(m.action!.intParam('visit_id'), 123);
    });

    test('/dashboard: legacy payload → velora null; new payload parsed', () {
      const caregiver = {'id': 5, 'name': 'Michael Rodriguez'};
      final legacy = DashboardModel.fromJson(const {'caregiver': caregiver});
      expect(legacy.velora, isNull);

      final d = DashboardModel.fromJson({
        'caregiver': caregiver,
        'client': {
          'id': 12,
          'name': 'Robert Ellison',
          'initials': 'RE',
          'address': '2141 Maple Ave, Warren',
          'plan': {'type': 'any_days', 'days_per_week': 5, 'set_days': [], 'label': 'DHS Home Help · 5 days a week'},
        },
        'week': {
          'week_start': '2026-09-21',
          'week_end': '2026-09-27',
          'plan_type': 'any_days',
          'done': 3,
          'of': 5,
          'days': [
            {'date': '2026-09-21', 'weekday_short': 'MON', 'day_number': 21, 'state': 'worked', 'hours': 5.53},
          ],
          'missed_note': {
            'date': '2026-09-23',
            'label': 'Tell us why Wednesday was missed',
            'action': {'screen': 'report', 'params': {}},
          },
        },
        'needs_attention': [
          {
            'key': 'id_expiring',
            'title': 'Your photo ID expires Oct 12',
            'subtitle': 'Snap a photo of the new one',
            'action': {
              'screen': 'upload',
              'params': {'document_type': 'photo_id', 'replaces_document_id': 40},
            },
          },
        ],
        'next_payday': {
          'date': '2026-10-16',
          'label': 'Fri, Oct 16',
          'last_paid': {'amount': 1293.16, 'date': '2026-09-11', 'label': 'Last paid \$1,293.16 on Sep 11'},
          'action': {'screen': 'pay', 'params': {}},
        },
      });
      final v = d.velora!;
      expect(v.client!.plan!.daysPerWeek, 5);
      expect(v.week!.days.single.hours, 5.53);
      expect(v.week!.missedNote!.action!.screen, AppScreen.report);
      expect(v.needsAttention.single.action!.stringParam('document_type'), 'photo_id');
      expect(v.nextPayday!.lastPaidAmount, 1293.16);
    });

    test('/pay/{id}: taxes.estimated preserved; missing flag treated as estimated', () {
      final d = PayDetailModel.fromJson({
        'id': 31,
        'net': 1293.16,
        'paid_on': '2026-09-11',
        'deposit': {'bank': 'Chase', 'last4': '4821', 'label': 'Chase ••4821'},
        'work_period': {'start': '2026-08-01', 'end': '2026-08-31', 'label': 'Aug 1 – 31, 2026'},
        'earnings': {'hours': 104.0, 'rate': 15.0, 'gross': 1560.0},
        'taxes': {'federal': 81.20, 'social_security': 96.72, 'medicare': 22.62, 'state': 66.30, 'total': 266.84, 'estimated': false},
        'year_to_date': {'gross': 12592.50, 'net': 10482.36},
      });
      expect(d.velora!.net, 1293.16);
      expect(d.velora!.taxes!.estimated, isFalse);
      expect(d.velora!.ytdNet, 10482.36);
      expect(PayTaxesModel.maybeFromJson({'federal': 1})!.estimated, isTrue);
      expect(PayDetailModel.fromJson({'id': 1}).velora, isNull);
    });

    test('/pay item, /documents, /compliance-forms additive fields', () {
      final pay = PayItemModel.fromJson({'id': 1, 'month_label': 'August', 'net': null, 'paid_on_label': 'Sep 11'});
      expect(pay.monthLabel, 'August');
      expect(pay.net, isNull);

      final doc = DocumentModel.fromJson({
        'id': 41,
        'filed_under': 'Your file › Identity',
        'replaces': {'id': 40, 'label': 'ID expiring Oct 12'},
        'review_eta': 'usually within 1 business day',
        'status': 'Received',
      });
      expect(doc.filedUnder, 'Your file › Identity');
      expect(doc.replacesId, 40);

      final form = ComplianceFormListItemModel.fromJson({
        'id': 7,
        'mode': 'live_in_mich',
        'state': 'upcoming',
        'due_at': '2026-10-06T12:00:00-04:00',
        'summary': {'visits_with_answers': {'done': 23, 'total': 23}, 'hospital_stays': [], 'care_not_given_days': 0},
        'timeline': [
          {'step': 1, 'label': 'By Tuesday, Oct 6 at 12:00 PM', 'title': 'Review & sign'},
        ],
      });
      expect(form.velora!.mode, CheckInMode.liveInMich);
      expect(form.velora!.visitsWithAnswersDone, 23);
      expect(form.velora!.timeline.single.title, 'Review & sign');
      expect(ComplianceFormListItemModel.fromJson({'id': 1}).velora, isNull);
    });

    test('check_in block: locked hospital days and day cycling', () {
      final detail = CheckInDetailModel.maybeFromJson({
        'prefill': {'care_not_given': false, 'missed_or_late': false},
        'days': [
          {'date': '2026-09-24', 'state': 'hospital', 'locked': true},
          {'date': 'bad', 'state': 'worked'},
        ],
        'counts': {'worked': 23, 'not_worked': 6, 'hospital': 1},
        'signature': {'type': 'typed_name', 'confirmation_text': 'I confirm…'},
      })!;
      expect(detail.days.single.locked, isTrue);
      expect(detail.counts!.hospital, 1);
      expect(CheckInDayState.worked.next, CheckInDayState.notWorked);
      expect(CheckInDayState.hospital.next, CheckInDayState.worked);
    });

    test('clock-out response summary parsed; old response has none', () {
      final v = VisitModel.fromJson({
        'id': 88,
        'client_id': 1,
        'status': 'Completed',
        'clock_in_at': '2026-09-25T09:02:00-04:00',
        'clock_out_at': '2026-09-25T15:10:00-04:00',
        'hospital': {'was_in_hospital': false, 'days_removed': 0},
        'summary': {'range_label': '9:02 AM – 3:10 PM', 'hours_label': '6h 08m', 'sent_to_office': true},
      });
      expect(v.clockOutDetails!.hoursLabel, '6h 08m');
      expect(v.clockOutDetails!.hospital!.daysRemoved, 0);
    });
  });

  group('New endpoint responses', () {
    test('/time/week and /time/month', () {
      final week = TimeWeekModel.fromJson({
        'data': {
          'label': 'Sep 21 – 27',
          'plan': {'type': 'set_days', 'set_days': ['mon', 'wed', 'fri']},
          'summary': {'days_done': 1, 'days_of': 3, 'hours': 5.53, 'hours_label': '5h 32m'},
          'days': [
            {
              'date': '2026-09-22',
              'weekday_short': 'TUE',
              'day_number': 22,
              'state': 'missing_clockout',
              'state_label': 'No clock-out',
              'visit': {'id': 123, 'clock_in_at': '2026-09-22T09:15:00-04:00', 'clock_out_at': null},
              'cta': {'key': 'add_clockout', 'label': 'Add clock-out time', 'action': {'screen': 'fix_clockout', 'params': {'visit_id': 123}}},
            },
          ],
        },
      });
      expect(week.plan!.isSetDays, isTrue);
      expect(week.hoursLabel, '5h 32m');
      expect(week.days.single.visit!.clockOutAt, isNull);
      expect(week.days.single.cta!.action!.intParam('visit_id'), 123);

      final month = TimeMonthModel.fromJson({
        'data': {
          'month': '2026-09',
          'days_worked': 18,
          'hours_label': '104h 50m',
          'approved_hours': {'limit': 120.0, 'used': 104.8, 'remaining': 15.2, 'percent_used': 87},
          'clock_in_rate': {'completed': 17, 'total': 18, 'percent': 94, 'required_percent': 85, 'meets_requirement': true},
          'calendar': {'first_weekday': 2, 'days': [{'day': 22, 'state': 'needs_fix'}]},
        },
      });
      expect(month.approvedHours!.remaining, 15.2);
      expect(month.clockInRate!.meetsRequirement, isTrue);
      expect(month.calendar[22], 'needs_fix');
    });

    test('/pay/next, /documents/required, /inbox/office-thread, auth', () {
      final next = PayNextModel.fromJson({
        'data': {
          'pay_label': 'Fri, Oct 16',
          'state': 'waiting_on_check_in',
          'check_in': {'form_id': 7, 'due_label': 'Tue, Oct 6 · 12 PM', 'action': {'screen': 'check_in', 'params': {'form_id': 7}}},
          'deposit': {'bank': null, 'last4': '4821', 'label': 'Direct deposit to ••4821'},
          'net_ytd': 10482.36,
          'how_it_works': [{'step': 1, 'title': 'Work the month.', 'text': 'Clock in and out at every visit.'}],
        },
      });
      expect(next.checkInFormId, 7);
      expect(next.deposit!.bank, isNull);
      expect(next.howItWorks.single.step, 1);

      final req = RequiredDocumentsModel.fromJson({
        'data': {
          'summary': {'up_to_date': 6, 'total': 7, 'needs_attention': 1},
          'items': [
            {'key': 'photo_id', 'label': 'Photo ID', 'status': 'expiring', 'status_label': 'Expires Oct 12', 'expires_on': '2026-10-12', 'document_id': 40},
          ],
        },
      });
      expect(req.items.single.needsAttention, isTrue);

      final thread = OfficeThreadModel.fromJson({
        'data': {'thread_id': 7, 'office_name': 'Supportive Solutions office', 'office_phone': '+13135550100'},
      });
      expect(thread.threadId, 7);

      final sent = PhoneCodeSentModel.fromJson({
        'message': 'If that number is registered, a code is on its way.',
        'data': {'phone_masked': '(•••) •••-4002', 'expires_in': 300, 'resend_in': 30},
      });
      expect(sent.resendIn, const Duration(seconds: 30));

      final verify = PhoneVerifyResultModel.maybeFromJson({
        'token': '12|aBc',
        'user': {'id': 5, 'name': 'Michael Rodriguez', 'email': 'm@example.com'},
        'first_sign_in': true,
      });
      expect(verify!.firstSignIn, isTrue);
    });

    test('push data → action', () {
      final a = AppActionModel.fromPushData({'screen': 'paystub', 'pay_id': '31'});
      expect(a!.screen, AppScreen.paystub);
      expect(a.intParam('pay_id'), 31);
      expect(AppActionModel.fromPushData({'screen': 'future_screen'})!.screen, isNull);
      expect(AppActionModel.fromPushData({}), isNull);
    });
  });

  group('Request payloads follow the contract', () {
    test('clock-out answers', () {
      final answers = ClockOutAnswers(
        hospital: HospitalStayModel(
          wasInHospital: true,
          from: DateTime(2026, 9, 24),
          to: DateTime(2026, 9, 26),
        ),
        careNotGiven: false,
      );
      expect(answers.toJson(), {
        'hospital': {'was_in_hospital': true, 'from': '2026-09-24', 'to': '2026-09-26', 'still_in_hospital': false},
        'care_not_given': false,
      });
      expect(
        () => ClockOutAnswers(
          hospital: HospitalStayModel(wasInHospital: true, from: DateTime(2026, 9, 26), to: DateTime(2026, 9, 24)),
          careNotGiven: false,
        ).validate(),
        throwsA(isA<RequestValidationException>()),
      );
      expect(const HospitalStayModel.none().toJson()['was_in_hospital'], isFalse);
    });

    test('fix-clockout: reason values and 24 h rule', () {
      final clockIn = DateTime(2026, 9, 22, 9, 15);
      final ok = FixClockoutRequest(
        leftAt: DateTime(2026, 9, 22, 15),
        reason: FixClockoutReason.forgotToTapOut,
        note: '  Left at 3  ',
        clockInAt: clockIn,
      );
      ok.validate();
      expect(ok.toJson()['reason'], 'forgot_to_tap_out');
      expect(ok.toJson()['note'], 'Left at 3');
      expect((ok.toJson()['left_at'] as String).startsWith('2026-09-22T15:00:00'), isTrue);

      expect(
        () => FixClockoutRequest(leftAt: DateTime(2026, 9, 22, 8), reason: FixClockoutReason.appProblem, clockInAt: clockIn).validate(),
        throwsA(isA<RequestValidationException>()),
      );
      expect(
        () => FixClockoutRequest(leftAt: DateTime(2026, 9, 23, 10), reason: FixClockoutReason.appProblem, clockInAt: clockIn).validate(),
        throwsA(isA<RequestValidationException>()),
      );
    });

    test('change reports: required fields per type', () {
      expect(
        () => const ChangeReportRequest(type: ChangeReportType.hospitalStay).validate(),
        throwsA(isA<RequestValidationException>()),
      );
      expect(
        () => ChangeReportRequest(type: ChangeReportType.fallInjury, from: DateTime(2026, 9, 24)).validate(),
        throwsA(isA<RequestValidationException>()),
      );
      final hosp = ChangeReportRequest(type: ChangeReportType.hospitalStay, from: DateTime(2026, 9, 24), note: 'Henry Ford');
      hosp.validate();
      expect(hosp.toJson(), {'type': 'hospital_stay', 'from': '2026-09-24', 'until': null, 'note': 'Henry Ford'});
      final contact = const ChangeReportRequest(type: ChangeReportType.contactChanged, note: 'New phone', documentId: 9);
      expect(contact.toJson().containsKey('document_id'), isFalse, reason: 'contact_changed takes no document');
    });

    test('info-change, settings, devices, typed check-in', () {
      expect(() => const InfoChangeRequest().validate(), throwsA(isA<RequestValidationException>()));
      expect(
        const InfoChangeRequest(mobile: '(586) 555-4003', email: ' ').toJson(),
        {'mobile': '(586) 555-4003'},
      );
      expect(() => const CaregiverSettingsModel(language: 'fr').validate(), throwsA(isA<RequestValidationException>()));
      expect(const CaregiverSettingsModel(reminders: true).toJson(), {'reminders': true});
      expect(
        () => const DeviceRegistrationRequest(token: '', platform: 'ios', appVersion: '1.0.0', language: 'en').validate(),
        throwsA(isA<RequestValidationException>()),
      );

      const answers = CheckInAnswers(
        hospital: HospitalStayModel.none(),
        careNotGiven: CheckInYesNoAnswer.no,
        missedOrLate: CheckInYesNoAnswer.no,
      );
      expect(
        () => const CheckInSubmitRequest(answers: answers, signatureName: 'Michael', confirmed: true).validate(),
        throwsA(isA<RequestValidationException>()),
      );
      const ok = CheckInSubmitRequest(answers: answers, signatureName: 'Michael Rodriguez', confirmed: true);
      ok.validate();
      expect(ok.toJson()['signature_name'], 'Michael Rodriguez');
      expect((ok.toJson()['answers'] as Map)['additional_notes'], isNull);
      expect((ok.toJson()['answers'] as Map)['care_not_given'], {'answer': false, 'details': null});

      // `details` is required when the answer is Yes.
      const lateNoDetails = CheckInAnswers(
        hospital: HospitalStayModel.none(),
        careNotGiven: CheckInYesNoAnswer.no,
        missedOrLate: CheckInYesNoAnswer(answer: true, details: '  '),
      );
      expect(
        () => const CheckInSubmitRequest(answers: lateNoDetails, signatureName: 'Michael Rodriguez', confirmed: true)
            .validate(),
        throwsA(isA<RequestValidationException>()),
      );
      const late = CheckInYesNoAnswer(answer: true, details: ' Ran 20 minutes late. ');
      expect(late.toJson(), {'answer': true, 'details': 'Ran 20 minutes late.'});
    });

    test('check-in detail: object answers, live-in null prefill, estimate', () {
      final detail = CheckInDetailModel.maybeFromJson({
        'prefill': {
          'hospital': null,
          'care_not_given': {'answer': true, 'details': 'No bath Tuesday'},
          'missed_or_late': null,
          'additional_notes': null,
        },
        'hours_per_day_estimate': 5.8,
        'calendar': {'first_weekday': 2, 'days_in_month': 30},
      })!;
      expect(detail.prefill!.careNotGiven, const CheckInYesNoAnswer(answer: true, details: 'No bath Tuesday'));
      expect(detail.prefill!.missedOrLate, isNull);
      expect(detail.prefill!.isComplete, isFalse);
      expect(detail.calendarDaysInMonth, 30);
      expect(detail.hoursRemovedFor(3), closeTo(17.4, 0.001));
    });

    test('services catalog and clock-out services', () {
      final catalog = ServiceCatalogModel.fromJson({
        'data': {
          'groups': [
            {'key': 'personal_care', 'name': 'Personal care', 'items': [{'id': 'bathing', 'label': 'Bathing'}]},
          ],
          'summary': [
            {'id': 'meals', 'label': 'Meals', 'covers': ['meal_prep']},
          ],
        },
      });
      expect(catalog.isKnownId('bathing'), isTrue);
      expect(catalog.isKnownId('meals'), isTrue);
      expect(catalog.isKnownId('flying'), isFalse);
      expect(catalog.labelFor('bathing'), 'Bathing');
      expect(catalog.summary.single.covers, ['meal_prep']);

      const answers = ClockOutAnswers(
        hospital: HospitalStayModel.none(),
        careNotGiven: false,
        services: ['meals', 'bathing', 'meals'],
      );
      expect(answers.toJson()['services'], ['meals', 'bathing']);
    });

    test('clock-in location match, clock-out summary, client location', () {
      expect(LocationMatchModel.maybeFromJson({'matched': null, 'distance_feet': null})!.matched, isNull);
      final ext = ClockOutExtensionModel.maybeFromJson({
        'hospital': {'was_in_hospital': true, 'days_removed': 3, 'summary_line': 'Sep 24 – 26 · 3 days removed'},
        'summary': {'services_logged': 2, 'week': {'done': 4, 'of': 5, 'label': '4 of 5 days'}},
      })!;
      expect(ext.hospital!.summaryLine, 'Sep 24 – 26 · 3 days removed');
      expect(ext.servicesLogged, 2);
      expect(ext.week, const WeekProgressModel(done: 4, of: 5, label: '4 of 5 days'));

      final client = ClientSummaryModel.maybeFromJson({
        'id': 12,
        'name': 'Robert Ellison',
        'location': {'latitude': 42.4934, 'longitude': -83.0304, 'radius_feet': 300},
      })!;
      expect(client.location!.isWithin(42.4934, -83.0304), isTrue);
      expect(client.location!.isWithin(42.5034, -83.0304), isFalse);
    });

    test('document types and direct deposit purpose', () {
      expect(DocumentUploadType.stateLetter.value, 'state_letter');
      expect(
        DocumentUploadType.values.map((t) => t.value),
        isNot(anyOf(contains('dhs_letter'), contains('direct_deposit_form'))),
      );
      expect(
        () => const DocumentUploadExtras.directDeposit().validate(DocumentUploadType.photoId),
        throwsA(isA<RequestValidationException>()),
      );
      const DocumentUploadExtras.directDeposit().validate(DocumentUploadType.taxOrPayForm);
    });

    test('phone rules', () {
      expect(PhoneAuthRules.normalizeUsPhone('(586) 555-4002'), '+15865554002');
      expect(PhoneAuthRules.normalizeUsPhone('1 586 555 4002'), '+15865554002');
      expect(PhoneAuthRules.normalizeUsPhone('555-4002'), isNull);
      expect(PhoneAuthRules.isValidCode('481027'), isTrue);
      expect(PhoneAuthRules.isValidCode('48102'), isFalse);
    });
  });

  group('Errors', () {
    test('422 keeps field errors; 429 reads Retry-After / retry_after', () {
      final v = mapApiError(statusCode: 422, data: {
        'message': 'The given data was invalid.',
        'errors': {'left_at': ['Bad time']},
      });
      expect(v, isA<ValidationException>());
      expect((v as ValidationException).errorFor('left_at'), 'Bad time');
      expect(apiErrorMessage(v), 'Bad time');

      final h = mapApiError(statusCode: 429, data: {'message': 'Slow down'}, headers: {'Retry-After': ['45']});
      expect((h as TooManyRequestsException).retryAfter, const Duration(seconds: 45));
      expect(apiErrorMessage(h), 'Too many tries. Try again in 45 seconds.');

      final b = mapApiError(statusCode: 429, data: {'message': 'x', 'retry_after': 600});
      expect((b as TooManyRequestsException).retryAfter, const Duration(minutes: 10));

      expect(mapApiError(statusCode: 409, data: {'message': 'Already fixed'}), isA<ConflictException>());
      expect(mapApiError(statusCode: 403, data: null).message, 'Request failed');
      expect(mapApiError(statusCode: 404, data: {'message': 'Nope'}), isA<NotFoundException>());
    });

    test('planned endpoints refuse to run while VELORA_API is off (no request made)', () async {
      // Transport is never touched: the guard runs first.
      final tokens = TokenStorageImpl();
      final client = ApiClient(
        tokenStorage: tokens,
        sessionStorage: SessionStorageImpl(),
        sessionExpiredNotifier: SessionExpiredNotifier(),
        tokenRefreshHandler: TokenRefreshHandler(),
        languageStore: LanguageStore(),
      );
      final api = VeloraApi(apiClient: client, tokenStorage: tokens);
      expect(api.getPayNext(), throwsA(isA<ApiNotLiveException>()));
      expect(api.getTimeWeek(), throwsA(isA<ApiNotLiveException>()));
      expect(
        api.fixClockout(1, FixClockoutRequest(leftAt: DateTime(2026), reason: FixClockoutReason.appProblem)),
        throwsA(isA<ApiNotLiveException>()),
      );
    });
  });
}

