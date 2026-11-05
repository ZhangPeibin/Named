class AppVersionCheck {
  const AppVersionCheck({
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
}
