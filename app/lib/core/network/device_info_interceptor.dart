import 'package:dio/dio.dart';

import '../device/device_info_service.dart';

class DeviceInfoInterceptor extends Interceptor {
  const DeviceInfoInterceptor(this._deviceInfoReader);

  final DeviceInfoReader _deviceInfoReader;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final value = await _deviceInfoReader.headerValue();
      if (value.trim().isNotEmpty) {
        options.headers[DeviceInfoService.headerName] = value;
      }
    } catch (_) {
      // Device metadata must never block API IO.
    }

    handler.next(options);
  }
}
