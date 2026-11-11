#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

xcodebuild -version
# Select an available runtime instead of assuming a particular iPhone/OS pair.
stiint_simulator_id="$(python3 - <<'PY'
import json, re, subprocess, sys
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
candidates = []
for runtime, devices in data["devices"].items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = tuple(map(int, match.groups()))
    if version < (26, 1):
        continue
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            candidates.append((device.get("state") == "Booted", version, device["name"], device["udid"]))
if not candidates:
    sys.exit("No available iPhone simulator with iOS 26.1 or later. Install a runtime in Xcode Settings.")
print(sorted(candidates, reverse=True)[0][-1])
PY
)"

mkdir -p build
# Xcode requires a new result path. Preserve the previous run rather than deleting it.
if [[ -e build/TestResults.xcresult ]]; then
  mv build/TestResults.xcresult "build/TestResults-$(date +%Y%m%d-%H%M%S).xcresult"
fi
xcodebuild test \
  -project Stiint.xcodeproj \
  -scheme Stiint \
  -destination "platform=iOS Simulator,id=$stiint_simulator_id" \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/TestResults.xcresult \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
