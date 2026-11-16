import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/key_value_storage_provider.dart';

const readerSpeedStorageKey = 'daily.readerSpeed';
const readerSpeedMin = 0.5;
const readerSpeedMax = 1.5;
const readerSpeedDefault = 1.0;

final readerSpeedProvider =
    AsyncNotifierProvider<ReaderSpeedController, double>(
      ReaderSpeedController.new,
    );

class ReaderSpeedController extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final saved = await ref
        .read(keyValueStorageProvider)
        .getInt('${readerSpeedStorageKey}Percent');
    if (saved == null) {
      return readerSpeedDefault;
    }
    return (saved / 100).clamp(readerSpeedMin, readerSpeedMax);
  }

  Future<void> setRate(double rate) async {
    final clamped = rate.clamp(readerSpeedMin, readerSpeedMax);
    state = AsyncData(clamped);
    await ref
        .read(keyValueStorageProvider)
        .setInt('${readerSpeedStorageKey}Percent', (clamped * 100).round());
  }
}
