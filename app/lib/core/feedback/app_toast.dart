import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

typedef AppToastHandle = ToastificationItem;

/// App-wide lightweight toast facade.
///
/// Business code should call this class instead of importing toastification
/// directly so the underlying SDK can be swapped later.
class AppToast {
  const AppToast._();

  static AppToastHandle success(String message) {
    return _show(
      message: message,
      type: ToastificationType.success,
      duration: const Duration(seconds: 3),
    );
  }

  static AppToastHandle error(String message) {
    return _show(
      message: message,
      type: ToastificationType.error,
      duration: const Duration(seconds: 4),
    );
  }

  static AppToastHandle info(String message) {
    return _show(
      message: message,
      type: ToastificationType.info,
      duration: const Duration(seconds: 3),
    );
  }

  static void dismiss(
    AppToastHandle? toast, {
    bool showRemoveAnimation = true,
  }) {
    if (toast == null) {
      return;
    }
    toastification.dismiss(toast, showRemoveAnimation: showRemoveAnimation);
  }

  static AppToastHandle _show({
    required String message,
    required ToastificationType type,
    required Duration duration,
  }) {
    return toastification.show(
      type: type,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: duration,
      title: Text(message),
      showProgressBar: false,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    );
  }
}
