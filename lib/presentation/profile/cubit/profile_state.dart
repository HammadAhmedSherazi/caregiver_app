import 'package:equatable/equatable.dart';

import '../../../data/models/profile_page_model.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.errorMessage,
  });

  final ProfileStatus status;
  final ProfilePageData? data;
  final String? errorMessage;

  bool get isLoading => status == ProfileStatus.loading;
  bool get hasError => status == ProfileStatus.failure;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfilePageData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
