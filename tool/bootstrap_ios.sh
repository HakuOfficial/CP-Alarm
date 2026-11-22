#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -d ios/Runner.xcodeproj ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  flutter create --no-pub --platforms=ios --org com.kuda --project-name cp_alarm "$tmp/host"
  cp -R "$tmp/host/ios" ios
  cp "$tmp/host/.metadata" .metadata
fi
ruby tool/native_setup.rb
flutter pub get
