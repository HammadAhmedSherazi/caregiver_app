import 'package:equatable/equatable.dart';

abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends BaseState {
  const LoadingState();
}

class ErrorState extends BaseState {
  const ErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
