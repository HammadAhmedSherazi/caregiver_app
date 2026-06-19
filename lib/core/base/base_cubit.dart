import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/helpers/logger.dart';

abstract class BaseCubit<T> extends Cubit<T> {
  BaseCubit(super.initialState);

  @override
  void emit(T state) {
    if (isClosed) return;
    super.emit(state);
  }

  void logDebug(String message) {
    AppLogger.debug(message, tag: runtimeType.toString());
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(
      message,
      tag: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
