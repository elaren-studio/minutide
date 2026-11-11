#!/bin/bash
set -euo pipefail
set +x

usage() {
  cat <<'USAGE'
Usage: archive-ios.sh [--archive-path PATH] [--derived-data-path PATH] [-- XCODEBUILD_ARGS...]

Creates a signed Release archive with the Stiint scheme. Paths that are not
absolute are resolved from the repository root. The default archive path is
build/Archives/Minutide.xcarchive.

Required environment: MINUTIDE_DEVELOPMENT_TEAM
Optional environment: MINUTIDE_BUNDLE_ID_BASE (default: com.elaren.minutide)
USAGE
}

fail() {
  printf 'archive-ios.sh: %s\n' "$1" >&2
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
DERIVED_DATA_PATH='build/DerivedData'

while (($#)); do
  case "$1" in
    --archive-path)
      (($# >= 2)) || fail 'missing value for --archive-path'
      ARCHIVE_PATH="$2"
      shift 2
      ;;
    --derived-data-path)
      (($# >= 2)) || fail 'missing value for --derived-data-path'
      DERIVED_DATA_PATH="$2"
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
[[ "$MINUTIDE_DEVELOPMENT_TEAM" =~ ^[A-Z0-9]{10}$ ]] || fail 'set MINUTIDE_DEVELOPMENT_TEAM to the 10-character team ID that will sign this build'
MINUTIDE_BUNDLE_ID_BASE="${MINUTIDE_BUNDLE_ID_BASE:-com.elaren.minutide}"
[[ "$MINUTIDE_BUNDLE_ID_BASE" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || fail 'MINUTIDE_BUNDLE_ID_BASE must be a dotted bundle identifier prefix'
command -v xcodebuild >/dev/null 2>&1 || fail 'xcodebuild was not found; install Xcode and select its developer directory'

ARCHIVE_PATH="$(resolve_path "$ARCHIVE_PATH")"
DERIVED_DATA_PATH="$(resolve_path "$DERIVED_DATA_PATH")"
[[ ! -e "$ARCHIVE_PATH" && ! -L "$ARCHIVE_PATH" ]] || fail "archive path already exists; choose a new path: $ARCHIVE_PATH"

mkdir -p "$REPO_ROOT/build/logs" "$(dirname "$ARCHIVE_PATH")" "$DERIVED_DATA_PATH"
LOG_PATH="$REPO_ROOT/build/logs/archive-ios-$(date -u '+%Y%m%dT%H%M%SZ')-$$.log"
printf 'Archiving the Stiint scheme. Xcode output: %s\n' "$LOG_PATH"

xcodebuild archive \
  -project "$REPO_ROOT/Stiint.xcodeproj" \
  -scheme Stiint \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$MINUTIDE_DEVELOPMENT_TEAM" \
  MINUTIDE_BUNDLE_ID_BASE="$MINUTIDE_BUNDLE_ID_BASE" \
  "$@" 2>&1 | tee "$LOG_PATH"

[[ -d "$ARCHIVE_PATH" ]] || fail "xcodebuild returned success but the archive is missing: $ARCHIVE_PATH"
printf 'Archive created: %s\n' "$ARCHIVE_PATH"
