import '../base_model.dart';

class EarningsYtdModel extends BaseModel {
  const EarningsYtdModel({
    required this.gross,
    required this.hours,
    required this.paystubCount,
  });

  final double gross;
  final double hours;
  final int paystubCount;

  factory EarningsYtdModel.fromJson(Map<String, dynamic> json) {
    return EarningsYtdModel(
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      paystubCount: json['paystub_count'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'gross': gross,
        'hours': hours,
        'paystub_count': paystubCount,
      };

  @override
  List<Object?> get props => [gross, hours, paystubCount];
}

class IntegrationStatusModel extends BaseModel {
  const IntegrationStatusModel({
    required this.label,
    this.connected,
    this.ready,
  });

  final String label;
  final bool? connected;
  final bool? ready;

  factory IntegrationStatusModel.fromJson(Map<String, dynamic> json) {
    return IntegrationStatusModel(
      label: json['label'] as String? ?? '',
      connected: json['connected'] as bool?,
      ready: json['ready'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'connected': connected,
        'ready': ready,
      };

  @override
  List<Object?> get props => [label, connected, ready];
}

class EarningsPeriodModel extends BaseModel {
  const EarningsPeriodModel({
    required this.period,
    required this.periodKey,
    required this.gross,
    required this.hours,
    required this.status,
    this.paidDate,
  });

  final String period;
  final String periodKey;
  final double gross;
  final double hours;
  final String status;
  final String? paidDate;

  factory EarningsPeriodModel.fromJson(Map<String, dynamic> json) {
    return EarningsPeriodModel(
      period: json['period'] as String? ?? '',
      periodKey: json['period_key'] as String? ?? '',
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      paidDate: json['paid_date'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'period': period,
        'period_key': periodKey,
        'gross': gross,
        'hours': hours,
        'status': status,
        'paid_date': paidDate,
      };

  @override
  List<Object?> get props => [period, periodKey, gross, hours, status, paidDate];
}

class HoursWeekModel extends BaseModel {
  const HoursWeekModel({
    required this.weekStart,
    required this.weekEnd,
    required this.label,
    required this.hours,
  });

  final String weekStart;
  final String weekEnd;
  final String label;
  final double hours;

  factory HoursWeekModel.fromJson(Map<String, dynamic> json) {
    return HoursWeekModel(
      weekStart: json['week_start'] as String? ?? '',
      weekEnd: json['week_end'] as String? ?? '',
      label: json['label'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'week_start': weekStart,
        'week_end': weekEnd,
        'label': label,
        'hours': hours,
      };

  @override
  List<Object?> get props => [weekStart, weekEnd, label, hours];
}

class EarningsSummaryModel extends BaseModel {
  const EarningsSummaryModel({
    required this.year,
    required this.yearToDate,
    required this.quickbooks,
    required this.gusto,
    required this.earningsSeries,
    required this.hoursSeries,
  });

  final int year;
  final EarningsYtdModel yearToDate;
  final IntegrationStatusModel quickbooks;
  final IntegrationStatusModel gusto;
  final List<EarningsPeriodModel> earningsSeries;
  final List<HoursWeekModel> hoursSeries;

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    final integrations =
        json['integrations'] as Map<String, dynamic>? ?? const {};
    final earningsRaw = json['earnings_series'] as List<dynamic>? ?? const [];
    final hoursRaw = json['hours_series'] as List<dynamic>? ?? const [];

    return EarningsSummaryModel(
      year: json['year'] as int? ?? DateTime.now().year,
      yearToDate: EarningsYtdModel.fromJson(
        json['year_to_date'] as Map<String, dynamic>? ?? const {},
      ),
      quickbooks: IntegrationStatusModel.fromJson(
        integrations['quickbooks'] as Map<String, dynamic>? ?? const {},
      ),
      gusto: IntegrationStatusModel.fromJson(
        integrations['gusto'] as Map<String, dynamic>? ?? const {},
      ),
      earningsSeries: earningsRaw
          .whereType<Map<String, dynamic>>()
          .map(EarningsPeriodModel.fromJson)
          .toList(),
      hoursSeries: hoursRaw
          .whereType<Map<String, dynamic>>()
          .map(HoursWeekModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'year': year,
        'year_to_date': yearToDate.toJson(),
        'integrations': {
          'quickbooks': quickbooks.toJson(),
          'gusto': gusto.toJson(),
        },
        'earnings_series': earningsSeries.map((e) => e.toJson()).toList(),
        'hours_series': hoursSeries.map((h) => h.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [year, yearToDate, quickbooks, gusto, earningsSeries, hoursSeries];
}
