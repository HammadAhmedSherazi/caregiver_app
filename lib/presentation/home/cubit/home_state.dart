import 'package:equatable/equatable.dart';

import '../../../data/models/care_recipient_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.recipients = const [],
    this.errorMessage,
  });

  final HomeStatus status;
  final List<CareRecipientModel> recipients;
  final String? errorMessage;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasError => status == HomeStatus.failure;
  bool get isSuccess => status == HomeStatus.success;

  HomeState copyWith({
    HomeStatus? status,
    List<CareRecipientModel>? recipients,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      recipients: recipients ?? this.recipients,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, recipients, errorMessage];
}
