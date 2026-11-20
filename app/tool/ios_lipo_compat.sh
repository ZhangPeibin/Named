#!/usr/bin/env bash
#
# Re-apply the Xcode 27 `lipo` compatibility patch to the local Flutter SDK.
#
# Xcode 27's `lipo -verify_arch` accepts only one architecture per call, but
# Flutter 3.41.9 passes the whole list at once, so iOS simulator builds fail
# with "does not contain architectures". This patches the SDK's
# `thinFramework` to verify each arch separately and rebuilds the flutter tool
# snapshot. The patch lives in the (out-of-repo) FVM SDK cache, so re-run this
# after `fvm install` / `flutter upgrade`.
#
# Usage: bash tool/ios_lipo_compat.sh   (or: make ios-lipo-compat)
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ios-lipo-compat: skipped (macOS only)."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SDK="${FLUTTER_ROOT:-}"
if [[ -z "$SDK" && -e "$APP_DIR/.fvm/flutter_sdk" ]]; then
  SDK="$(cd "$APP_DIR/.fvm/flutter_sdk" && pwd -P)"
fi
if [[ -z "$SDK" || ! -d "$SDK" ]]; then
  echo "ios-lipo-compat: could not locate the Flutter SDK."
  echo "  Expected app/.fvm/flutter_sdk or FLUTTER_ROOT."
  exit 1
fi

TARGET="$SDK/packages/flutter_tools/lib/src/build_system/targets/darwin.dart"
SNAPSHOT="$SDK/bin/cache/flutter_tools.snapshot"
STAMP="$SDK/bin/cache/flutter_tools.stamp"

if [[ ! -f "$TARGET" ]]; then
  echo "ios-lipo-compat: target not found: $TARGET"
  exit 1
fi

if grep -q "Xcode 27's lipo accepts only one arch" "$TARGET"; then
  echo "ios-lipo-compat: SDK already patched ($SDK)."
  if [[ ! -f "$SNAPSHOT" ]]; then
    echo "ios-lipo-compat: rebuilding flutter tool snapshot..."
    rm -f "$SNAPSHOT" "$STAMP"
    "$SDK/bin/flutter" --version >/dev/null
  fi
  exit 0
fi

python3 - "$TARGET" <<'PY'
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

old = """    final ProcessResult verifyResult = await environment.processManager.run(<String>[
      'lipo',
      frameworkBinaryPath,
      '-verify_arch',
      ...archList,
    ]);

    if (verifyResult.exitCode != 0) {
      throw Exception(
        'Binary $frameworkBinaryPath does not contain architectures "$archs".\\n'
        '\\n'
        'lipo -info:\\n'
        '$lipoInfo',
      );
    }
"""

new = """    // Xcode 27's lipo accepts only one arch per `-verify_arch` invocation, so
    // verify each arch separately instead of passing the whole list at once.
    for (final String arch in archList) {
      final ProcessResult verifyResult = await environment.processManager.run(<String>[
        'lipo',
        frameworkBinaryPath,
        '-verify_arch',
        arch,
      ]);

      if (verifyResult.exitCode != 0) {
        throw Exception(
          'Binary $frameworkBinaryPath does not contain architectures "$archs".\\n'
          '\\n'
          'lipo -info:\\n'
          '$lipoInfo',
        );
      }
    }
"""

if old not in src:
    sys.stderr.write(
        "ios-lipo-compat: expected code block not found in darwin.dart.\n"
        "The Flutter version likely changed; update this script or upgrade Flutter.\n"
    )
    sys.exit(2)

open(path, "w", encoding="utf-8").write(src.replace(old, new, 1))
print("ios-lipo-compat: patched darwin.dart")
PY

echo "ios-lipo-compat: rebuilding flutter tool snapshot (first run may take a minute)..."
rm -f "$SNAPSHOT" "$STAMP"
"$SDK/bin/flutter" --version >/dev/null

if [[ ! -f "$SNAPSHOT" ]]; then
  echo "ios-lipo-compat: snapshot rebuild failed." >&2
  exit 1
fi

echo "ios-lipo-compat: done. iOS builds should work with Xcode 27 now."
