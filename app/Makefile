.PHONY: bootstrap run-dev run-staging run-prod \
        build-apk build-appbundle build-apk-local build-ios \
        preflight-prod preflight-android preflight-ios \
        check fix format-check generated-check architecture-check \
        analyze test integration-test coverage doctor doctor-ci \
        gen clean get hooks icons splash new-feature

# ── Environment bootstrap ─────────────────────────────────────────────────────

bootstrap:
	@if [ ! -f config/prod.json ]; then \
		cp config/prod.example.json config/prod.json; \
		echo "Created config/prod.json from config/prod.example.json"; \
	else \
		echo "config/prod.json already exists, skipping"; \
	fi

# ── Run ───────────────────────────────────────────────────────────────────────

run-dev:
	flutter run --flavor dev --dart-define-from-file=config/dev.json

run-staging:
	flutter run --flavor staging --dart-define-from-file=config/staging.json

run-prod: preflight-prod
	flutter run --flavor prod --release --dart-define-from-file=config/prod.json

preflight-prod: bootstrap
	dart run tool/release_preflight.dart \
		--config=config/prod.json \
		--platform=common

preflight-android: bootstrap
	dart run tool/release_preflight.dart \
		--config=config/prod.json \
		--platform=android

preflight-ios: bootstrap
	dart run tool/release_preflight.dart \
		--config=config/prod.json \
		--platform=ios

# ── Build (release + obfuscation + symbol archiving) ─────────────────────────
#
# Symbols are saved to build/symbols/<version>/ for crash symbolication.
# Keep them alongside your release — you'll need them to decode stack traces.
#
# Android signing: set these env vars before running build-apk:
#   ANDROID_KEYSTORE_PATH   absolute path to your .jks / .keystore file
#   ANDROID_KEYSTORE_PASS   keystore password
#   ANDROID_KEY_ALIAS       key alias inside the keystore
#   ANDROID_KEY_PASS        key password
#
# Example:
#   ANDROID_KEYSTORE_PATH=~/keys/release.jks \
#   ANDROID_KEYSTORE_PASS=secret \
#   ANDROID_KEY_ALIAS=upload \
#   ANDROID_KEY_PASS=secret \
#   make build-apk

VERSION := $(shell grep "^version:" pubspec.yaml | awk '{print $$2}')
SYMBOLS_DIR := build/symbols/$(VERSION)

build-apk: preflight-android
	flutter build apk \
		--flavor prod \
		--release \
		--obfuscate \
		--split-debug-info=build/symbols/tmp \
		--dart-define-from-file=config/prod.json
	mkdir -p $(SYMBOLS_DIR)
	cp -r build/symbols/tmp/. $(SYMBOLS_DIR)/
	rm -rf build/symbols/tmp
	@echo "✅ APK built. Symbols saved to $(SYMBOLS_DIR)/"

build-appbundle: preflight-android
	flutter build appbundle \
		--flavor prod \
		--release \
		--obfuscate \
		--split-debug-info=build/symbols/tmp \
		--dart-define-from-file=config/prod.json
	mkdir -p $(SYMBOLS_DIR)
	cp -r build/symbols/tmp/. $(SYMBOLS_DIR)/
	rm -rf build/symbols/tmp
	@echo "AAB built. Symbols saved to $(SYMBOLS_DIR)/"

build-apk-local:
	flutter build apk \
		--flavor dev \
		--release \
		--dart-define-from-file=config/dev.json

build-ios: preflight-ios
	flutter build ipa \
		--flavor prod \
		--release \
		--obfuscate \
		--split-debug-info=build/symbols/tmp \
		--dart-define-from-file=config/prod.json
	mkdir -p $(SYMBOLS_DIR)
	cp -r build/symbols/tmp/. $(SYMBOLS_DIR)/
	rm -rf build/symbols/tmp
	@echo "✅ IPA built. Symbols saved to $(SYMBOLS_DIR)/"

# ── Code generation ───────────────────────────────────────────────────────────

gen:
	dart run slang

# ── Quality ───────────────────────────────────────────────────────────────────

check: format-check generated-check architecture-check doctor-ci analyze test

fix:
	dart fix --apply
	dart format .
	dart run slang

format-check:
	dart format --output=none --set-exit-if-changed .

generated-check:
	dart run tool/generated_code_check.dart

architecture-check:
	dart run tool/architecture_check.dart

analyze:
	flutter analyze

test:
	flutter test $(TEST_ARGS)

integration-test:
	@test -n "$(DEVICE)" || (echo "Usage: make integration-test DEVICE=<device-id>" && exit 64)
	flutter test integration_test --flavor dev -d $(DEVICE) \
		--dart-define-from-file=config/dev.json

coverage:
	flutter test --coverage
	@echo "Coverage report written to coverage/lcov.info"
	@echo "Run 'genhtml coverage/lcov.info -o coverage/html' to generate HTML report"

doctor:
	dart run tool/doctor.dart

doctor-ci:
	dart run tool/doctor.dart

# ── Assets ───────────────────────────────────────────────────────────────────

icons:
	dart run flutter_launcher_icons

splash:
	dart run flutter_native_splash:create

# ── Scaffolding ──────────────────────────────────────────────────────────────

# Scaffold a new feature under lib/features/<name>/ (see docs/agent/agent-playbook.md).
# Usage: make new-feature name=my_feature [ui_only=1]
new-feature:
	@test -n "$(name)" || (echo "Usage: make new-feature name=<feature_name> [ui_only=1]" && exit 64)
	dart run tool/new_feature.dart $(name) $(if $(ui_only),--ui-only,)

# ── Setup ────────────────────────────────────────────────────────────────────

get:
	flutter pub get

hooks:
	lefthook install

clean:
	flutter clean
