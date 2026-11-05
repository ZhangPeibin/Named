import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/feedback/app_toast.dart';
import '../../../i18n/strings.g.dart';
import '../domain/app_version_check.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppVersionCheck version,
}) async {
  if (!version.updateAvailable) {
    AppToast.info(context.t.appUpdate.upToDate);
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: !version.forceUpdate,
    builder: (dialogContext) {
      final t = dialogContext.t.appUpdate;
      final latestVersion = _latestVersionLabel(version);
      return PopScope(
        canPop: !version.forceUpdate,
        child: AlertDialog(
          title: Text(
            version.forceUpdate ? t.forceUpdateTitle : t.updateAvailableTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.updateAvailableDescription(version: latestVersion)),
              if (version.releaseNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(version.releaseNotes.trim()),
              ],
            ],
          ),
          actions: [
            if (!version.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.later),
              ),
            TextButton(
              onPressed: () => _openStore(dialogContext, version.storeUrl),
              child: Text(t.updateNow),
            ),
          ],
        ),
      );
    },
  );
}

String _latestVersionLabel(AppVersionCheck version) {
  final latestVersion = version.latestVersion.trim();
  if (latestVersion.isNotEmpty) {
    return latestVersion;
  }
  final latestBuild = version.latestBuild;
  return latestBuild > 0 ? latestBuild.toString() : '';
}

Future<bool> _openStore(BuildContext context, String storeUrl) async {
  final storeUnavailableMessage = context.t.appUpdate.storeUnavailable;
  final normalized = storeUrl.trim();
  if (normalized.isEmpty) {
    AppToast.info(storeUnavailableMessage);
    return false;
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    AppToast.info(storeUnavailableMessage);
    return false;
  }

  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }

  AppToast.info(storeUnavailableMessage);
  return false;
}
