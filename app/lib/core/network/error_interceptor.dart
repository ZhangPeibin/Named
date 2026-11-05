import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_error_localizer.dart';
import '../feedback/app_toast.dart';
import 'api_exception.dart';

/// Surfaces a single global toast for connectivity / server faults instead of
/// one per failed request.
///
/// Strategy — "fault-state lock + unlock on success":
/// - The first matching failure (network / timeout / server) shows a toast and
///   locks that fault type, so repeated failures (home polling, parallel
///   endpoints) stay silent.
/// - Any successful response clears the lock, so the next outage can toast
///   again.
/// - A short minimum interval guards against flapping when some requests
///   succeed while others fail at the same time, which would otherwise unlock
///   and re-toast in quick succession.
class ErrorInterceptor extends Interceptor {
  ApiExceptionType? _activeGlobalErrorType;
  DateTime? _lastToastAt;
  AppToastHandle? _activeGlobalErrorToast;
  static const _minimumInterval = Duration(seconds: 3);

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _activeGlobalErrorType = null;
    _dismissActiveGlobalErrorToast();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiException.fromDioException(err);
    _showToastIfNeeded(apiException);
    handler.next(err.copyWith(error: apiException));
  }

  void _showToastIfNeeded(ApiException exception) {
    final message = switch (exception.type) {
      ApiExceptionType.network ||
      ApiExceptionType.timeout ||
      ApiExceptionType.server => AppErrorLocalizer.messageFromCurrentLocale(
        exception,
      ),
      _ => null,
    };
    if (message == null) {
      return;
    }

    // Already showing this fault type — stay silent until a success unlocks it.
    if (_activeGlobalErrorType == exception.type) {
      return;
    }

    // Anti-flap floor: ignore re-toasts that arrive within the minimum interval
    // (e.g. a stray success unlocked us between two concurrent failures).
    final now = DateTime.now();
    final lastToastAt = _lastToastAt;
    if (lastToastAt != null && now.difference(lastToastAt) < _minimumInterval) {
      _activeGlobalErrorType = exception.type;
      return;
    }

    _activeGlobalErrorType = exception.type;
    _lastToastAt = now;
    _dismissActiveGlobalErrorToast(showRemoveAnimation: false);
    if (!suppressGlobalErrorToastsForTesting) {
      _activeGlobalErrorToast = AppToast.error(message);
    }
  }

  void _dismissActiveGlobalErrorToast({bool showRemoveAnimation = true}) {
    AppToast.dismiss(
      _activeGlobalErrorToast,
      showRemoveAnimation: showRemoveAnimation,
    );
    _activeGlobalErrorToast = null;
  }

  @visibleForTesting
  bool suppressGlobalErrorToastsForTesting = false;

  @visibleForTesting
  ApiExceptionType? get activeGlobalErrorTypeForTesting =>
      _activeGlobalErrorType;
}
