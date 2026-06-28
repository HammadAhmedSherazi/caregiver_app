import 'package:equatable/equatable.dart';

import '../../../data/models/home_dashboard_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.isEndingShift = false,
  });

  final HomeStatus status;
  final HomeDashboard? dashboard;
  final String? errorMessage;
  final bool isEndingShift;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasError => status == HomeStatus.failure;
  bool get isSuccess => status == HomeStatus.success;

  HomeState copyWith({
    HomeStatus? status,
    HomeDashboard? dashboard,
    String? errorMessage,
    bool? isEndingShift,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isEndingShift: isEndingShift ?? this.isEndingShift,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, errorMessage, isEndingShift];
}
