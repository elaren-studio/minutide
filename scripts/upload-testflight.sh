#!/bin/bash
set -euo pipefail
set +x

usage() {
  cat <<'USAGE'
Usage: upload-testflight.sh PATH_TO_IPA

Validates the explicit IPA with App Store Connect, then uploads it for
TestFlight processing. It does not add testers or submit an App Store release.

Required environment: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
ASC_KEY_PATH must point to an existing private key file outside this repository.
USAGE
}

fail() {
  printf 'upload-testflight.sh: %s\n' "$1" >&2
  exit 2
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
if (($# == 1)) && { [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; }; then
  usage
  exit 0
fi
[[ $# == 1 ]] || { usage >&2; fail 'provide exactly one IPA path'; }
IPA_PATH="$1"
case "$IPA_PATH" in
  /*) ;;
  *) IPA_PATH="$REPO_ROOT/$IPA_PATH" ;;
esac
[[ "$IPA_PATH" == *.ipa ]] || fail 'the input path must end in .ipa'
[[ -f "$IPA_PATH" && -r "$IPA_PATH" ]] || fail "IPA is not a readable file: $IPA_PATH"

ASC_KEY_ID="${ASC_KEY_ID:-}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"
ASC_KEY_PATH="${ASC_KEY_PATH:-}"
[[ -n "$ASC_KEY_ID" ]] || fail 'set ASC_KEY_ID in the local environment'
[[ -n "$ASC_ISSUER_ID" ]] || fail 'set ASC_ISSUER_ID in the local environment'
[[ -n "$ASC_KEY_PATH" ]] || fail 'set ASC_KEY_PATH to the local App Store Connect .p8 file'
[[ -f "$ASC_KEY_PATH" && -r "$ASC_KEY_PATH" ]] || fail 'ASC_KEY_PATH must point to a readable private key file'
command -v python3 >/dev/null 2>&1 || fail 'python3 is required to verify that ASC_KEY_PATH is outside this repository'
if ! python3 - "$REPO_ROOT" "$ASC_KEY_PATH" <<'PY'
import os
import sys

repo_root = os.path.realpath(sys.argv[1])
key_path = os.path.realpath(sys.argv[2])
try:
    shared = os.path.commonpath((repo_root, key_path))
    inside_repository = os.path.samefile(shared, repo_root)
except (OSError, ValueError):
    inside_repository = False
sys.exit(1 if inside_repository else 0)
PY
then
  fail 'ASC_KEY_PATH must resolve to a file outside this repository'
fi
command -v xcrun >/dev/null 2>&1 || fail 'xcrun was not found; install Xcode and select its developer directory'

mkdir -p "$REPO_ROOT/build/logs"
LOG_PATH="$REPO_ROOT/build/logs/upload-testflight-$(date -u '+%Y%m%dT%H%M%SZ')-$$.log"
printf 'Validating the selected IPA. App Store Connect output: %s\n' "$LOG_PATH"
xcrun altool --validate-app "$IPA_PATH" \
  --api-key "$ASC_KEY_ID" \
  --api-issuer "$ASC_ISSUER_ID" \
  --p8-file-path "$ASC_KEY_PATH" 2>&1 | tee "$LOG_PATH"

printf 'Validation succeeded; uploading the same IPA for TestFlight processing.\n'
xcrun altool --upload-package "$IPA_PATH" \
  --api-key "$ASC_KEY_ID" \
  --api-issuer "$ASC_ISSUER_ID" \
  --p8-file-path "$ASC_KEY_PATH" 2>&1 | tee -a "$LOG_PATH"

printf 'Upload command completed. Confirm Apple processing and internal TestFlight availability in App Store Connect.\n'
