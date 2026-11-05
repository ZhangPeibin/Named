import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/flutter_secure_storage_adapter.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageAdapter();
});
