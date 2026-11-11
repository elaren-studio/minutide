# Device acceptance checklist

Use a disposable Simulator or a dedicated test device with synthetic activity names and locations. Do not use a personal tracking history for acceptance. Record the device, iOS version, app revision, tester, date, result, and any issue for every run. A blank result means **not run**, not passed.

The project currently targets iOS 26.1. Simulator checks help with layout and core state; Shortcuts automation, location behavior, Live Activities, and lifecycle recovery also need real-device coverage where noted.

| Check | Simulator | Physical iPhone | Expected result | Status / evidence |
|---|---:|---:|---|---|
| Fresh launch and first-run setup | Yes | Yes | App opens; setup completes without requiring a purchase or sign-in. | Partial in Simulator: app launched and onboarding was skipped; no sign-in or purchase was required. Full setup flow not checked. |
| Create, rename, and remove an activity | Yes | Yes | Name, color, icon, and optional weekday rules behave as shown; removal does not corrupt other records. | Partial in Simulator: created synthetic `Community Build Review`; rename/removal not run. |
| Start, stop, and inspect a log | Yes | Yes | One activity becomes active; stopping it records one valid time interval in the timeline. | Partial in Simulator: timer start/stop succeeded and returned to the activity list; timeline/log detail was not inspected. |
| Pause tracking | Yes | Yes | Shortcuts start actions respect the pause setting; the UI communicates the paused state. | Not run |
| Weekday rule | Yes | Yes | An allowed-day start succeeds and a disallowed-day start is ignored. | Not run |
| Stop specific activity | Yes | Yes | Only the requested activity is stopped. | Not run |
| Stop and resume previous activity | Yes | Yes | The stopped interval closes and the previous activity resumes once, without overlapping open logs. | Not run |
| Relaunch recovery | Yes | Yes | Relaunching while an activity is active restores exactly one active state and a coherent timeline. | Passed in Simulator: terminated/relaunched app; the same timer recovered and elapsed time advanced. |
| Background / suspension recovery | Limited | Required | Returning from suspension does not lose, duplicate, or overlap the active interval. | Not run |
| Device restart recovery | No | Required | After reboot and launch, the app reconciles persisted state without inventing a second active interval. | Not run |
| Shortcuts App Intents | Limited | Required | Each exposed start, stop, query, resume, and CSV action returns the expected result. | Not run |
| Timeline edit and date navigation | Yes | Yes | Date navigation and manual log edits update the displayed data and persisted record. | Not run |
| Analytics filters and diagrams | Yes | Yes | Date/activity filters apply consistently; charts render with empty, small, and larger synthetic datasets. | Not run |
| Live Activity / lock screen | Limited | Required | Active activity and elapsed time appear and update; stopping tracking removes or ends the Live Activity. | Passed in Simulator: Dynamic Island showed icon/time; Lock Screen showed name/time after Allow prompt; stop removed Lock Screen activity. See screenshot below. |
| Location disabled | Yes | Yes | No coordinates are added to a log when location storage is off. | Not run |
| Location enabled and denied | Simulated | Required | Granting permission stores start/end coordinates for the selected activity; denied permission fails safely and does not block ordinary tracking. | Not run |
| CSV export | Yes | Yes | Export contains the documented fields, valid CSV escaping, and coordinates only when saved; the user can choose where to send the file. | Not run |
| Fresh install and upgrade | Yes | Required | Fresh install starts clean; upgrade preserves existing activity/log records and recovers active tracking safely. | Not run |
| Accessibility and appearance | Yes | Yes | Text scales, contrast, VoiceOver labels, light/dark appearance, and supported orientations remain usable. | Not run |

## Run record

### 2026-11-11 — Simulator timer and Live Activity smoke check

- App revision: integrated, uncommitted working tree on `feature/community-revival`.
- Xcode: 26.6 (17F113).
- Destination: iPhone 17 simulator, iOS 26.5, UUID `A0FC95C9-60F0-46AB-BBCC-CD2FBA540215`.
- Build command: `xcodebuild build -project Stiint.xcodeproj -scheme Stiint -destination 'platform=iOS Simulator,id=A0FC95C9-60F0-46AB-BBCC-CD2FBA540215' CODE_SIGNING_ALLOWED=NO`.
- Result: build/run succeeded without warnings, per root's XcodeBuildMCP log at `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/logs/build_run_sim_2026-11-11T17-13-19-168Z_pid42173_79d5b3ef.log`.
- Manual flow: skipped onboarding, created `Community Build Review`, started timer, observed Dynamic Island and Lock Screen state, terminated/relaunched and confirmed recovery, then stopped and confirmed the Lock Screen activity disappeared.
- Screenshot: [`community-lock-screen.jpg`](images/community-lock-screen.jpg).
- Physical device: `xcrun devicectl list devices` returned no devices at 2026-11-11 17:13 UTC; physical-device checks remain open.
- Automated tests: 19 tests passed (16 unit and 3 UI) at 17:15:42 UTC on an earlier snapshot. Review later found an archived-history split-tail issue; its fix and a 20th regression test are in progress. A rerun is required before claiming the current revision passes.

### 2026-11-11 — Final automated source check

- Command: `bash scripts/ci-ios.sh`.
- Result: exit 0 at 17:27:44 UTC. Result bundle `build/TestResults.xcresult` reports **20 passed, 0 failed, 0 skipped** on iPhone 17 / iOS 26.5.
- The 17 unit tests cover timer transitions, missing/stale preferences, duplicate/orphan history, simultaneous starts/switches, archived targets, historical splits, safe detail initialization, and CSV edge cases. Three UI tests cover launch, activity creation/start/stop/export visibility, access to all charts, and timer recovery after relaunch.
- Final Release Simulator build passed at 17:28:30 UTC with 0 warnings/errors.
- This is local Simulator evidence. It does not prove physical Shortcuts triggers, actual GPS behavior, reboot recovery, one-hour layout on hardware, or minimum-runtime compatibility.

### 2026-11-11 — Minutide renamed-source validation

- Built plists confirm Minutide / `com.elaren.minutide` and Minutide Live Activity / `com.elaren.minutide.liveactivity`. Internal project and scheme remain `Stiint`; minimum remains iOS 26.1.
- `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh` exited 0 at 18:43:10 UTC: 20 passed, 0 failed, 0 skipped, on iPhone 17 / iOS 26.5. Independently confirmed in `build/TestResults.xcresult` with `xcresulttool`.
- Earlier ordinary shell/MCP attempts stalled in a separate build-service output reader and were canceled. The successful per-command environment workaround did not change project or system settings.
- The earlier manual screenshot predates the rename. This verifies automated flows under the new app identity, not hardware acceptance or cross-container migration.

### 2026-11-11 — SSD checkout validation

- Canonical checkout: `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide`, branch `feature/community-revival` at `607d5b3164545177777ed22f45bed8187d9887a9`.
- Fresh SSD CI invocation: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`, exit 0 from 22:29:46.904 to 22:32:30.882 UTC; output log `build/minutide-ssd-ci.log`.
- Result: **20 passed, 0 failed, 0 skipped** (17 unit and 3 UI) on iPhone 17 / iOS 26.5. Result bundle `build/TestResults.xcresult` was independently checked. Built app and extension plists confirm Minutide display names and bundle identifiers.
- Migration integrity is documented in `build/history/pre-ssd/migration-verification.json`; it is separate from app acceptance. No physical-device or minimum-runtime check is completed by the migration.

All other rows remain not run unless explicitly marked partial or passed above. Do not generalize this smoke check to untested features or physical-device behavior.
