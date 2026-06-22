import 'package:equatable/equatable.dart';

import '../../../data/models/schedule_page_model.dart';

enum ScheduleStatus { initial, loading, success, failure }

class ScheduleState extends Equatable {
  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.data,
    this.errorMessage,
  });

  final ScheduleStatus status;
  final SchedulePageData? data;
  final String? errorMessage;

  bool get isLoading => status == ScheduleStatus.loading;
  bool get hasError => status == ScheduleStatus.failure;

  ScheduleState copyWith({
    ScheduleStatus? status,
    SchedulePageData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
