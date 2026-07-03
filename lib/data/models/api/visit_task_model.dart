import '../base_model.dart';

class VisitTaskModel extends BaseModel {
  const VisitTaskModel({
    required this.id,
    required this.scheduleId,
    required this.label,
    required this.category,
    required this.sortOrder,
    required this.isCompleted,
    this.completedAt,
  });

  final int id;
  final int scheduleId;
  final String label;
  final String category;
  final int sortOrder;
  final bool isCompleted;
  final DateTime? completedAt;

  factory VisitTaskModel.fromJson(Map<String, dynamic> json) {
    return VisitTaskModel(
      id: json['id'] as int,
      scheduleId: json['schedule_id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      category: json['category'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  VisitTaskModel copyWith({bool? isCompleted, DateTime? completedAt}) {
    return VisitTaskModel(
      id: id,
      scheduleId: scheduleId,
      label: label,
      category: category,
      sortOrder: sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_id': scheduleId,
        'label': label,
        'category': category,
        'sort_order': sortOrder,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, scheduleId, label, category, sortOrder, isCompleted, completedAt];
}
