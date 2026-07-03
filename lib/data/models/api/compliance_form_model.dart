import '../base_model.dart';

class ComplianceQuestionModel extends BaseModel {
  const ComplianceQuestionModel({
    required this.key,
    required this.text,
  });

  final String key;
  final String text;

  factory ComplianceQuestionModel.fromJson(Map<String, dynamic> json) {
    return ComplianceQuestionModel(
      key: json['key'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {'key': key, 'text': text};

  @override
  List<Object?> get props => [key, text];
}

class ComplianceFormListItemModel extends BaseModel {
  const ComplianceFormListItemModel({
    required this.id,
    required this.period,
    required this.periodLabel,
    required this.status,
    required this.submitted,
    required this.isOverdue,
  });

  final int id;
  final String period;
  final String periodLabel;
  final String status;
  final bool submitted;
  final bool isOverdue;

  factory ComplianceFormListItemModel.fromJson(Map<String, dynamic> json) {
    return ComplianceFormListItemModel(
      id: json['id'] as int,
      period: json['period'] as String? ?? '',
      periodLabel: json['period_label'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submitted: json['submitted'] as bool? ?? false,
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'period': period,
        'period_label': periodLabel,
        'status': status,
        'submitted': submitted,
        'is_overdue': isOverdue,
      };

  @override
  List<Object?> get props =>
      [id, period, periodLabel, status, submitted, isOverdue];
}

class ComplianceFormDetailModel extends BaseModel {
  const ComplianceFormDetailModel({
    required this.id,
    required this.periodLabel,
    required this.status,
    required this.submitted,
    required this.questions,
  });

  final int id;
  final String periodLabel;
  final String status;
  final bool submitted;
  final List<ComplianceQuestionModel> questions;

  factory ComplianceFormDetailModel.fromJson(Map<String, dynamic> json) {
    final questionsRaw = json['questions'] as List<dynamic>? ?? const [];
    return ComplianceFormDetailModel(
      id: json['id'] as int,
      periodLabel: json['period_label'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submitted: json['submitted'] as bool? ?? false,
      questions: questionsRaw
          .whereType<Map<String, dynamic>>()
          .map(ComplianceQuestionModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'period_label': periodLabel,
        'status': status,
        'submitted': submitted,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, periodLabel, status, submitted, questions];
}

class ComplianceHistorySummaryModel extends BaseModel {
  const ComplianceHistorySummaryModel({
    required this.submitted,
    required this.overdue,
    required this.onTimePct,
  });

  final int submitted;
  final int overdue;
  final int onTimePct;

  factory ComplianceHistorySummaryModel.fromJson(Map<String, dynamic> json) {
    return ComplianceHistorySummaryModel(
      submitted: json['submitted'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      onTimePct: json['on_time_pct'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'submitted': submitted,
        'overdue': overdue,
        'on_time_pct': onTimePct,
      };

  @override
  List<Object?> get props => [submitted, overdue, onTimePct];
}

class ComplianceHistoryRecordModel extends BaseModel {
  const ComplianceHistoryRecordModel({
    required this.id,
    required this.periodLabel,
    required this.status,
    this.submittedAt,
  });

  final int id;
  final String periodLabel;
  final String status;
  final DateTime? submittedAt;

  factory ComplianceHistoryRecordModel.fromJson(Map<String, dynamic> json) {
    return ComplianceHistoryRecordModel(
      id: json['id'] as int,
      periodLabel: json['period_label'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'period_label': periodLabel,
        'status': status,
        'submitted_at': submittedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, periodLabel, status, submittedAt];
}

class ComplianceHistoryModel extends BaseModel {
  const ComplianceHistoryModel({
    required this.summary,
    required this.records,
  });

  final ComplianceHistorySummaryModel summary;
  final List<ComplianceHistoryRecordModel> records;

  factory ComplianceHistoryModel.fromJson(Map<String, dynamic> json) {
    final recordsRaw = json['records'] as List<dynamic>? ?? const [];
    return ComplianceHistoryModel(
      summary: ComplianceHistorySummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      records: recordsRaw
          .whereType<Map<String, dynamic>>()
          .map(ComplianceHistoryRecordModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'records': records.map((r) => r.toJson()).toList(),
      };

  @override
  List<Object?> get props => [summary, records];
}
