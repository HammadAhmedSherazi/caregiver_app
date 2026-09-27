import 'package:equatable/equatable.dart';

import 'common_models.dart';
import 'json.dart';

class PayHowItWorksStepModel extends Equatable {
  const PayHowItWorksStepModel({required this.step, required this.title, required this.text});

  final int step;
  final String title;
  final String text;

  factory PayHowItWorksStepModel.fromJson(Json j) => PayHowItWorksStepModel(
        step: intOrNull(j['step']) ?? 0,
        title: strOr(j['title']),
        text: strOr(j['text']),
      );

  @override
  List<Object?> get props => [step, title, text];
}

/// `GET /pay/next` 🚧 PLANNED — NOT LIVE.
class PayNextModel extends Equatable {
  const PayNextModel({
    this.payDate,
    required this.payLabel,
    this.forLabel,
    required this.state,
    this.stateLabel,
    this.checkInFormId,
    this.checkInOpensAt,
    this.checkInOpensLabel,
    this.checkInDueAt,
    this.checkInDueLabel,
    this.checkInAction,
    this.deposit,
    this.netYtd,
    this.howItWorks = const [],
  });

  final DateTime? payDate;
  final String payLabel;
  final String? forLabel;

  /// `waiting_on_check_in` · `ready` · `in_grace` · `late_rolled` · `held` · `paid`.
  final String state;
  final String? stateLabel;
  final int? checkInFormId;
  final DateTime? checkInOpensAt;
  final String? checkInOpensLabel;
  final DateTime? checkInDueAt;
  final String? checkInDueLabel;
  final AppActionModel? checkInAction;
  final DepositModel? deposit;

  /// From the server — never computed on the device.
  final double? netYtd;
  final List<PayHowItWorksStepModel> howItWorks;

  factory PayNextModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    final ci = jsonMap(d['check_in']) ?? const {};
    return PayNextModel(
      payDate: dateOrNull(d['pay_date']),
      payLabel: strOr(d['pay_label']),
      forLabel: str(d['for_label']),
      state: strOr(d['state']),
      stateLabel: str(d['state_label']),
      checkInFormId: intOrNull(ci['form_id']),
      checkInOpensAt: dateOrNull(ci['opens_at']),
      checkInOpensLabel: str(ci['opens_label']),
      checkInDueAt: dateOrNull(ci['due_at']),
      checkInDueLabel: str(ci['due_label']),
      checkInAction: AppActionModel.maybeFromJson(ci['action']),
      deposit: DepositModel.maybeFromJson(d['deposit']),
      netYtd: dblOrNull(d['net_ytd']),
      howItWorks: jsonList(d['how_it_works']).map(PayHowItWorksStepModel.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [
        payDate, payLabel, forLabel, state, stateLabel, checkInFormId, checkInOpensAt,
        checkInOpensLabel, checkInDueAt, checkInDueLabel, checkInAction, deposit, netYtd, howItWorks,
      ];
}

/// `taxes` of `GET /pay/{id}`. [estimated] must be surfaced (Open decision D3).
class PayTaxesModel extends Equatable {
  const PayTaxesModel({
    this.federal,
    this.socialSecurity,
    this.medicare,
    this.state,
    this.total,
    required this.estimated,
  });

  final double? federal;
  final double? socialSecurity;
  final double? medicare;
  final double? state;
  final double? total;
  final bool estimated;

  static PayTaxesModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return PayTaxesModel(
      federal: dblOrNull(j['federal']),
      socialSecurity: dblOrNull(j['social_security']),
      medicare: dblOrNull(j['medicare']),
      state: dblOrNull(j['state']),
      total: dblOrNull(j['total']),
      // Unknown means estimated: never present unverified numbers as final.
      estimated: boolOrNull(j['estimated']) ?? true,
    );
  }

  @override
  List<Object?> get props => [federal, socialSecurity, medicare, state, total, estimated];
}

/// Additive fields of `GET /pay/{id}` (Paystub). `null` on today's API.
class PayDetailExtensionModel extends Equatable {
  const PayDetailExtensionModel({
    this.net,
    this.paidOn,
    this.deposit,
    this.workPeriodStart,
    this.workPeriodEnd,
    this.workPeriodLabel,
    this.client,
    this.employer,
    this.earningsHours,
    this.earningsRate,
    this.earningsGross,
    this.taxes,
    this.ytdGross,
    this.ytdNet,
  });

  final double? net;
  final DateTime? paidOn;
  final DepositModel? deposit;
  final DateTime? workPeriodStart;
  final DateTime? workPeriodEnd;
  final String? workPeriodLabel;
  final String? client;
  final String? employer;
  final double? earningsHours;
  final double? earningsRate;
  final double? earningsGross;
  final PayTaxesModel? taxes;
  final double? ytdGross;
  final double? ytdNet;

  static PayDetailExtensionModel? maybeFromJson(Json json) {
    const keys = ['net', 'paid_on', 'deposit', 'work_period', 'earnings', 'taxes', 'year_to_date'];
    if (!keys.any(json.containsKey)) return null;
    final wp = jsonMap(json['work_period']) ?? const {};
    final e = jsonMap(json['earnings']) ?? const {};
    final ytd = jsonMap(json['year_to_date']) ?? const {};
    return PayDetailExtensionModel(
      net: dblOrNull(json['net']),
      paidOn: dateOrNull(json['paid_on']),
      deposit: DepositModel.maybeFromJson(json['deposit']),
      workPeriodStart: dateOrNull(wp['start']),
      workPeriodEnd: dateOrNull(wp['end']),
      workPeriodLabel: str(wp['label']),
      client: str(json['client']),
      employer: str(json['employer']),
      earningsHours: dblOrNull(e['hours']),
      earningsRate: dblOrNull(e['rate']),
      earningsGross: dblOrNull(e['gross']),
      taxes: PayTaxesModel.maybeFromJson(json['taxes']),
      ytdGross: dblOrNull(ytd['gross']),
      ytdNet: dblOrNull(ytd['net']),
    );
  }

  @override
  List<Object?> get props => [
        net, paidOn, deposit, workPeriodStart, workPeriodEnd, workPeriodLabel, client, employer,
        earningsHours, earningsRate, earningsGross, taxes, ytdGross, ytdNet,
      ];
}
