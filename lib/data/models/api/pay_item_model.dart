import '../base_model.dart';

class PayItemModel extends BaseModel {
  const PayItemModel({
    required this.id,
    required this.period,
    required this.periodKey,
    required this.hours,
    required this.rate,
    required this.gross,
    required this.status,
    required this.program,
    this.paidDate,
    this.clientName,
    required this.stubAvailable,
    this.stubUrl,
  });

  final int id;
  final String period;
  final String periodKey;
  final double hours;
  final double rate;
  final double gross;
  final String status;
  final String program;
  final String? paidDate;
  final String? clientName;
  final bool stubAvailable;
  final String? stubUrl;

  factory PayItemModel.fromJson(Map<String, dynamic> json) {
    return PayItemModel(
      id: (json['id'] as num).toInt(),
      period: json['period'] as String? ?? '',
      periodKey: json['period_key'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      program: json['program'] as String? ?? '',
      paidDate: json['paid_date'] as String?,
      clientName: json['client_name'] as String?,
      stubAvailable: json['stub_available'] as bool? ?? false,
      stubUrl: json['stub_url'] as String?,
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
        'program': program,
        if (paidDate != null) 'paid_date': paidDate,
        if (clientName != null) 'client_name': clientName,
        'stub_available': stubAvailable,
        if (stubUrl != null) 'stub_url': stubUrl,
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
        program,
        paidDate,
        clientName,
        stubAvailable,
        stubUrl,
      ];
}
