#!/usr/bin/env bash
set -euo pipefail
: "${APPLE_P12_B64:?}" "${APPLE_P12_PASSWORD:?}" "${APPLE_PROFILE_B64:?}" "${BUNDLE_ID:?}"
umask 077
sign_dir="$(mktemp -d)"
kc="$sign_dir/build.keychain-db"
pw="$(openssl rand -hex 24)"
old_keychains=()
while IFS= read -r line; do old_keychains+=("$(echo "$line" | sed -E 's/^[[:space:]]*"//;s/"[[:space:]]*$//')"); done < <(security list-keychains -d user)
profile_path=""
restore() {
  security list-keychains -d user -s "${old_keychains[@]}"
  security delete-keychain "$kc" 2>/dev/null || true
  if [[ -n "$profile_path" ]]; then
    if [[ -f "$sign_dir/previous" ]]; then cp "$sign_dir/previous" "$profile_path"; else rm -f "$profile_path"; fi
  fi
  rm -rf "$sign_dir"
}
trap restore EXIT
printf '%s' "$APPLE_P12_B64" | base64 -D > "$sign_dir/cert.p12"
printf '%s' "$APPLE_PROFILE_B64" | base64 -D > "$sign_dir/profile"
security create-keychain -p "$pw" "$kc"
security unlock-keychain -p "$pw" "$kc"
security set-keychain-settings -lut 3600 "$kc"
security import "$sign_dir/cert.p12" -k "$kc" -P "$APPLE_P12_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$pw" "$kc" >/dev/null
security list-keychains -d user -s "$kc" "${old_keychains[@]}"
security cms -D -i "$sign_dir/profile" > "$sign_dir/profile.plist"
field() { /usr/libexec/PlistBuddy -c "Print :$1" "$sign_dir/profile.plist"; }
uuid="$(field UUID)"
export APPLE_TEAM_ID="$(field TeamIdentifier:0)"
export PROFILE_NAME="$(field Name)"
[[ "$(field Entitlements:application-identifier)" == *."$BUNDLE_ID" ]] || { echo 'Provisioning profile does not match BUNDLE_ID'; exit 1; }
profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profile_dir"
profile_path="$profile_dir/$uuid.mobileprovision"
if [[ -f "$profile_path" ]]; then cp "$profile_path" "$sign_dir/previous"; fi
cp "$sign_dir/profile" "$profile_path"
ruby tool/native_setup.rb
python3 - "$sign_dir/export.plist" <<'PY'
import os, plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({"method":"app-store-connect","signingStyle":"manual","teamID":os.environ["APPLE_TEAM_ID"],"provisioningProfiles":{os.environ["BUNDLE_ID"]:os.environ["PROFILE_NAME"]}},f)
PY
flutter build ipa --release --build-number="${GITHUB_RUN_NUMBER:-1}" --export-options-plist="$sign_dir/export.plist"
