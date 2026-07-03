import 'package:equatable/equatable.dart';

import '../../../data/models/home_dashboard_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.infoMessage,
    this.isEndingShift = false,
    this.isClockingOut = false,
  });

  final HomeStatus status;
  final HomeDashboard? dashboard;
  final String? errorMessage;
  final String? infoMessage;
  final bool isEndingShift;
  final bool isClockingOut;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasError => status == HomeStatus.failure;
  bool get isSuccess => status == HomeStatus.success;

  /// Server-reported clocked-in visit, or after a successful clock-in from home.
  bool get showActiveShiftScreen =>
      dashboard?.activeShift?.isInProgress ?? false;

  HomeState copyWith({
    HomeStatus? status,
    HomeDashboard? dashboard,
    String? errorMessage,
    String? infoMessage,
    bool? isEndingShift,
    bool? isClockingOut,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      isEndingShift: isEndingShift ?? this.isEndingShift,
      isClockingOut: isClockingOut ?? this.isClockingOut,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dashboard,
        errorMessage,
        infoMessage,
        isEndingShift,
        isClockingOut,
      ];
}
