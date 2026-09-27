import 'api_exception.dart';
import '../i18n/tr.dart';

/// User-facing text for an API failure, using the server's message and the
/// contract's `422 errors` / `429 retry_after` details when present.
String apiErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is RequestValidationException) return tr(error.message);
  if (error is ValidationException) {
    final first = error.errors.values.expand((e) => e).firstOrNull;
    return first ?? error.message;
  }
  if (error is TooManyRequestsException) {
    final wait = error.retryAfter;
    if (wait == null) return tr('Too many tries. Please wait a moment and try again.');
    final seconds = wait.inSeconds;
    return seconds < 90
        ? tr('Too many tries. Try again in {0} seconds.', [seconds])
        : tr('Too many tries. Try again in {0} minutes.', [(seconds / 60).ceil()]);
  }
  if (error is ApiException && error.message.isNotEmpty) return error.message;
  return tr(fallback);
}
