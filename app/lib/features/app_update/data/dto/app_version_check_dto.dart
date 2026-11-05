import '../../domain/app_version_check.dart';

class AppVersionCheckDto {
  const AppVersionCheckDto({
    required this.platform,
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedVersion,
    required this.minSupportedBuild,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.storeUrl,
    required this.releaseNotes,
  });

  final String platform;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final String minSupportedVersion;
  final int minSupportedBuild;
  final bool updateAvailable;
  final bool forceUpdate;
  final String storeUrl;
  final String releaseNotes;

  factory AppVersionCheckDto.fromJson(Map<String, dynamic> json) {
    return AppVersionCheckDto(
      platform: json['platform']?.toString() ?? '',
      currentVersion: json['current_version']?.toString() ?? '',
      currentBuild: _intValue(json['current_build']),
      latestVersion: json['latest_version']?.toString() ?? '',
      latestBuild: _intValue(json['latest_build']),
      minSupportedVersion: json['min_supported_version']?.toString() ?? '',
      minSupportedBuild: _intValue(json['min_supported_build']),
      updateAvailable: json['update_available'] == true,
      forceUpdate: json['force_update'] == true,
      storeUrl: json['store_url']?.toString() ?? '',
      releaseNotes: json['release_notes']?.toString() ?? '',
    );
  }

  AppVersionCheck toDomain() {
    return AppVersionCheck(
      platform: platform,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: latestVersion,
      latestBuild: latestBuild,
      minSupportedVersion: minSupportedVersion,
      minSupportedBuild: minSupportedBuild,
      updateAvailable: updateAvailable,
      forceUpdate: forceUpdate,
      storeUrl: storeUrl,
      releaseNotes: releaseNotes,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
