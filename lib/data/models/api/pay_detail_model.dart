import '../base_model.dart';

class PayBreakdownModel extends BaseModel {
  const PayBreakdownModel({
    required this.gross,
    required this.federalTax,
    required this.stateTax,
    required this.fica,
    required this.net,
    required this.estimated,
  });

  final double gross;
  final double federalTax;
  final double stateTax;
  final double fica;
  final double net;
  final bool estimated;

  factory PayBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PayBreakdownModel(
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      federalTax: (json['federal_tax'] as num?)?.toDouble() ?? 0,
      stateTax: (json['state_tax'] as num?)?.toDouble() ?? 0,
      fica: (json['fica'] as num?)?.toDouble() ?? 0,
      net: (json['net'] as num?)?.toDouble() ?? 0,
      estimated: json['estimated'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'gross': gross,
        'federal_tax': federalTax,
        'state_tax': stateTax,
        'fica': fica,
        'net': net,
        'estimated': estimated,
      };

  @override
  List<Object?> get props =>
      [gross, federalTax, stateTax, fica, net, estimated];
}

class PayVisitSummaryItemModel extends BaseModel {
  const PayVisitSummaryItemModel({
    required this.clientId,
    required this.clientName,
    required this.hours,
  });

  final int clientId;
  final String clientName;
  final double hours;

  factory PayVisitSummaryItemModel.fromJson(Map<String, dynamic> json) {
    return PayVisitSummaryItemModel(
      clientId: json['client_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'client_name': clientName,
        'hours': hours,
      };

  @override
  List<Object?> get props => [clientId, clientName, hours];
}

class PayDetailModel extends BaseModel {
  const PayDetailModel({
    required this.id,
    required this.period,
    required this.periodKey,
    required this.hours,
    required this.rate,
    required this.gross,
    required this.status,
    this.payDate,
    required this.breakdown,
    required this.visitSummary,
  });

  final int id;
  final String period;
  final String periodKey;
  final double hours;
  final double rate;
  final double gross;
  final String status;
  final String? payDate;
  final PayBreakdownModel breakdown;
  final List<PayVisitSummaryItemModel> visitSummary;

  factory PayDetailModel.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['visit_summary'] as List<dynamic>? ?? const [];
    return PayDetailModel(
      id: (json['id'] as num).toInt(),
      period: json['period'] as String? ?? '',
      periodKey: json['period_key'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      payDate: json['pay_date'] as String?,
      breakdown: PayBreakdownModel.fromJson(
        json['breakdown'] as Map<String, dynamic>? ?? const {},
      ),
      visitSummary: summaryRaw
          .whereType<Map<String, dynamic>>()
          .map(PayVisitSummaryItemModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'period': period,
        'period_key': periodKey,
        'hours': hours,
        'rate': rate,
        'gross': gross,
        'status': status,
        'pay_date': payDate,
        'breakdown': breakdown.toJson(),
        'visit_summary': visitSummary.map((v) => v.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        period,
        periodKey,
        hours,
        rate,
        gross,
        status,
        payDate,
        breakdown,
        visitSummary,
      ];
}
