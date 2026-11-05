import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/error_interceptor.dart';

final errorInterceptorProvider = Provider<ErrorInterceptor>((ref) {
  return ErrorInterceptor();
});
