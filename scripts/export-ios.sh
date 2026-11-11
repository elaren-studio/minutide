#!/bin/bash
set -euo pipefail
set +x

usage() {
  cat <<'USAGE'
Usage: export-ios.sh [--archive-path PATH] [--export-path PATH] [--export-options-plist PATH] [-- XCODEBUILD_ARGS...]

Exports an existing signed archive as an App Store Connect IPA for TestFlight.
Paths that are not absolute are resolved from the repository root. The default
archive is build/Archives/Minutide.xcarchive and the default output directory
is build/Exports/Minutide.

Required environment: MINUTIDE_DEVELOPMENT_TEAM
Optional custom export plist: --export-options-plist PATH (for manual signing)
USAGE
}

fail() {
  printf 'export-ios.sh: %s\n' "$1" >&2
  exit 2
}

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$1" ;;
  esac
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ARCHIVE_PATH='build/Archives/Minutide.xcarchive'
EXPORT_PATH='build/Exports/Minutide'
CUSTOM_OPTIONS_PATH=''

while (($#)); do
  case "$1" in
    --archive-path)
      (($# >= 2)) || fail 'missing value for --archive-path'
      ARCHIVE_PATH="$2"
      shift 2
      ;;
    --export-path)
      (($# >= 2)) || fail 'missing value for --export-path'
      EXPORT_PATH="$2"
      shift 2
      ;;
    --export-options-plist)
      (($# >= 2)) || fail 'missing value for --export-options-plist'
      CUSTOM_OPTIONS_PATH="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1 (put extra xcodebuild arguments after --)"
      ;;
  esac
done

MINUTIDE_DEVELOPMENT_TEAM="${MINUTIDE_DEVELOPMENT_TEAM:-}"
[[ "$MINUTIDE_DEVELOPMENT_TEAM" =~ ^[A-Z0-9]{10}$ ]] || fail 'set MINUTIDE_DEVELOPMENT_TEAM to the 10-character team ID associated with this archive'
command -v xcodebuild >/dev/null 2>&1 || fail 'xcodebuild was not found; install Xcode and select its developer directory'
[[ -d "$(resolve_path "$ARCHIVE_PATH")" ]] || fail "archive does not exist: $(resolve_path "$ARCHIVE_PATH")"

ARCHIVE_PATH="$(resolve_path "$ARCHIVE_PATH")"
EXPORT_PATH="$(resolve_path "$EXPORT_PATH")"
[[ ! -e "$EXPORT_PATH" && ! -L "$EXPORT_PATH" ]] || fail "export path already exists; choose a new path: $EXPORT_PATH"

mkdir -p "$REPO_ROOT/build/logs" "$(dirname "$EXPORT_PATH")"
LOG_PATH="$REPO_ROOT/build/logs/export-ios-$(date -u '+%Y%m%dT%H%M%SZ')-$$.log"
TEMP_OPTIONS_PATH=''
cleanup() {
  if [[ -n "$TEMP_OPTIONS_PATH" ]]; then
    rm -f "$TEMP_OPTIONS_PATH"
  fi
}
trap cleanup EXIT

if [[ -n "$CUSTOM_OPTIONS_PATH" ]]; then
  OPTIONS_PATH="$(resolve_path "$CUSTOM_OPTIONS_PATH")"
  [[ -f "$OPTIONS_PATH" && -r "$OPTIONS_PATH" ]] || fail "custom export options plist is not readable: $OPTIONS_PATH"
else
  TEMP_OPTIONS_PATH="$(mktemp "$REPO_ROOT/build/.MinutideExportOptions.XXXXXX")"
  OPTIONS_PATH="$TEMP_OPTIONS_PATH"
  cat > "$OPTIONS_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${MINUTIDE_DEVELOPMENT_TEAM}</string>
</dict>
</plist>
PLIST
fi

plutil -lint "$OPTIONS_PATH" >/dev/null || fail 'export options are not a valid property list'
if ! OPTIONS_METHOD="$(/usr/libexec/PlistBuddy -c 'Print :method' "$OPTIONS_PATH" 2>/dev/null)"; then
  fail 'export options plist must define method=app-store-connect'
fi
[[ "$OPTIONS_METHOD" == 'app-store-connect' ]] || fail 'export options method must be app-store-connect'
if OPTIONS_DESTINATION="$(/usr/libexec/PlistBuddy -c 'Print :destination' "$OPTIONS_PATH" 2>/dev/null)"; then
  [[ "$OPTIONS_DESTINATION" != 'upload' ]] || fail 'export options destination must be export; upload is a separate explicit step'
fi
if OPTIONS_TEAM="$(/usr/libexec/PlistBuddy -c 'Print :teamID' "$OPTIONS_PATH" 2>/dev/null)"; then
  [[ "$OPTIONS_TEAM" == "$MINUTIDE_DEVELOPMENT_TEAM" ]] || fail 'export options teamID must match MINUTIDE_DEVELOPMENT_TEAM'
fi

printf 'Exporting a local App Store Connect IPA. Xcode output: %s\n' "$LOG_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$OPTIONS_PATH" \
  "$@" 2>&1 | tee "$LOG_PATH"

IPA_COUNT=0
IPA_PATH=''
for candidate in "$EXPORT_PATH"/*.ipa; do
  [[ -f "$candidate" ]] || continue
  [[ -s "$candidate" ]] || fail "Xcode produced an empty IPA: $candidate"
  IPA_COUNT=$((IPA_COUNT + 1))
  IPA_PATH="$candidate"
done
if [[ "$IPA_COUNT" != '1' ]]; then
  fail "expected exactly one nonempty IPA in export directory: $EXPORT_PATH"
fi

printf 'Export produced IPA: %s\n' "$IPA_PATH"
printf 'Review the IPA and export log before using upload-testflight.sh.\n'
