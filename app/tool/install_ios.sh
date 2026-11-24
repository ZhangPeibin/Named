#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-config/dev-remote.json}"
MODE="${MODE:-profile}"
FLAVOR="${FLAVOR:-dev}"
DEVICE="${DEVICE:-}"
BUNDLE_ID="${BUNDLE_ID:-com.named.app.dev}"

if [[ "$MODE" != "profile" && "$MODE" != "release" ]]; then
  echo "MODE must be profile or release (got: $MODE)." >&2
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Config not found: $CONFIG" >&2
  echo "Create it from config/dev-ios.json or pass CONFIG=<path>." >&2
  exit 1
fi

if grep -Eq '"API_BASE_URL"[[:space:]]*:[[:space:]]*"https?://(localhost|127\.0\.0\.1|10\.0\.2\.2)([:/"]|$)' "$CONFIG"; then
  echo "warning: $CONFIG points at a host a physical iPhone cannot reach." >&2
  echo "warning: use a LAN IP or a public API URL." >&2
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Install Xcode command line tools first." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found; it is required to parse the device list." >&2
  exit 1
fi

FLUTTER_BIN="${FLUTTER_BIN:-}"
if [[ -z "$FLUTTER_BIN" ]]; then
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="flutter"
  elif [[ -x ".fvm/flutter_sdk/bin/flutter" ]]; then
    FLUTTER_BIN=".fvm/flutter_sdk/bin/flutter"
  else
    echo "Flutter not found. Run through 'make install-ios' or put Flutter on PATH." >&2
    exit 1
  fi
fi

if [[ -z "$DEVICE" ]]; then
  DEVICE_FILE="$(mktemp)"
  trap 'rm -f "$DEVICE_FILE"' EXIT
  "$FLUTTER_BIN" devices --machine >"$DEVICE_FILE"
  if ! DEVICE="$(python3 - "$DEVICE_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    devices = json.load(handle)

physical = [
    device
    for device in devices
    if device.get("targetPlatform") == "ios" and not device.get("emulator")
]

if not physical:
    print(
        "No physical iOS device found. Connect and unlock your iPhone, then try again.",
        file=sys.stderr,
    )
    sys.exit(1)
if len(physical) > 1:
    print(
        "Multiple physical iOS devices found. Pass DEVICE=<udid>:",
        file=sys.stderr,
    )
    for device in physical:
        print(f"  {device.get('id')}  {device.get('name', '')}", file=sys.stderr)
    sys.exit(1)
print(physical[0]["id"])
PY
  )"; then
    exit 1
  fi
fi

echo "Building $MODE ($FLAVOR) with $CONFIG..."
"$FLUTTER_BIN" build ios "--$MODE" --flavor "$FLAVOR" \
  --dart-define-from-file="$CONFIG"

APP_PATH="build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build finished but $APP_PATH was not found." >&2
  exit 1
fi

echo "Installing on $DEVICE..."
if ! xcrun devicectl device install app --device "$DEVICE" "$APP_PATH"; then
  echo "Install failed. Check that the iPhone is unlocked, Developer Mode is on," >&2
  echo "the computer is trusted, and the development team is valid." >&2
  exit 1
fi

echo "Launching $BUNDLE_ID..."
if ! xcrun devicectl device process launch --terminate-existing \
  --device "$DEVICE" "$BUNDLE_ID"; then
  echo "Launch failed. Open the app manually on the iPhone to inspect the error." >&2
  exit 1
fi

echo "Installed and launched $BUNDLE_ID on $DEVICE."
