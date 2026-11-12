# Device acceptance checklist

Use a disposable Simulator or a dedicated test device with synthetic activity names and locations. Do not use a personal tracking history for acceptance. Record the device, iOS version, app revision, tester, date, result, and any issue for every run. A blank result means **not run**, not passed.

The project currently targets iOS 26.1. Simulator checks help with layout and core state; Shortcuts automation, location behavior, Live Activities, and lifecycle recovery also need real-device coverage where noted.

The first internal TestFlight build is intended to support the maintainer's physical-device acceptance run. Record those results separately from Apple processing and tester availability; physical acceptance is a gate for stable public release readiness.

## Current TestFlight delivery status — 2026-11-11

- The signed 0.1.0 build 1 archive and manual-export IPA are verified; the artifact receipt is `build/Verification/minutide-0.1.0-1.json`.
- Validation and upload succeeded without errors. Apple processing is `VALID` for **0.1.0 (1)**, build/delivery `591b8c17-694a-41ce-80bd-39c16a27e4a6`; internal state is `IN_BETA_TESTING`. The build is assigned to `Minutide Internal`, whose sole intended tester is `INVITED`. The website independently shows this version/build, group, and one invitation. Expiry: 2027-02-09. Installation and email delivery are not claimed.
- The maintainer confirms that 0.1.0 (1) is installed and launches on his iPhone.
  Device model and OS were not supplied. Shortcuts, location permission,
  reboot/recovery, accessibility, upgrade, and minimum-runtime checks remain open.

## Work hierarchy beta acceptance — pending

The next beta must preserve the existing on-device store. Automated disk-store
migration and simulator results will be recorded here after execution. Physical
upgrade acceptance remains a separate maintainer check after delivery:

1. Install the update without deleting the app. Verify existing tasks and time
   entries remain, and an existing running timer retains its start time.
2. Create two organizations, clients, projects, and both assigned and unassigned
   tasks. Switch scope while timing and verify the current timer continues.
3. Customize color and icon independently; verify inheritance and custom values.
4. Move or rename a task. Old entries should keep their recorded assignment;
   new entries should use the current one. Reclassify an old entry explicitly.
5. Combine filters across levels, group by each level, and compare totals.
   Export summary, detail, and raw CSV to a chosen destination.
6. Verify Shortcuts disambiguate repeated task names, and archived ancestors
   block new starts while keeping old time available in reports.

| Check | Simulator | Physical iPhone | Expected result | Status / evidence |
|---|---:|---:|---|---|
| Fresh launch and first-run setup | Yes | Yes | App opens; setup completes without requiring a purchase or sign-in. | Partial in Simulator: app launched and onboarding was skipped; no sign-in or purchase was required. Full setup flow not checked. |
| Create, rename, and remove an activity | Yes | Yes | Name, color, icon, and optional weekday rules behave as shown; removal does not corrupt other records. | Partial in Simulator: created synthetic `Community Build Review`; rename/removal not run. |
| Edit existing time records repeatedly | Yes | Yes | Each confirmed edit persists as one coherent update; relaunch does not restore stale values or lose a neighboring record. | Automated manual-edit regressions passed in the 39-test simulator suite before notice additions; manual UI and physical checks remain open. |
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
| Malformed timeline and analytics records | Yes | Yes | Missing, invalid, or incomplete fields are handled safely without a crash or force-unwrap failure; valid neighboring records remain usable. | Automated malformed-interval and running-log query regressions passed in the 39-test simulator suite before notice additions; physical checks remain open. |
| Overnight interval and date-boundary display | Yes | Yes | An interval spanning midnight is represented consistently on both dates and in aggregate duration, without clipping or losing elapsed time. | Automated midnight and 23/25-hour DST regressions passed in the 39-test simulator suite before notice additions; physical checks remain open. |
| Archived activity in Shortcuts enumeration | Limited | Required | Archived activities are not offered for new Shortcut actions; their saved historical records remain available in history. | Automated Shortcuts enumeration regression passed in the 39-test simulator suite before notice additions; a real Shortcuts app check remains open. |
| Analytics filters and diagrams | Yes | Yes | Date/activity filters apply consistently; charts render with empty, small, and larger synthetic datasets. | Not run |
| Live Activity / lock screen | Limited | Required | Active activity and elapsed time appear and update; stopping tracking removes or ends the Live Activity. | Passed in Simulator: Dynamic Island showed icon/time; Lock Screen showed name/time after Allow prompt; stop removed Lock Screen activity. See screenshot below. |
| Location disabled | Yes | Yes | No coordinates are added to a log when location storage is off. | Not run |
| Location enabled and denied | Simulated | Required | Granting permission stores start/end coordinates for the selected activity; denied permission fails safely and does not block ordinary tracking. | Not run |
| CSV export | Yes | Yes | Export contains the documented fields, valid CSV escaping, and coordinates only when saved; the user can choose where to send the file. | Not run |
| Fresh install and upgrade | Yes | Required | Fresh install starts clean; upgrade preserves existing activity/log records and recovers active tracking safely. | Not run |
| Accessibility and appearance | Yes | Yes | Text scales, contrast, VoiceOver labels, light/dark appearance, and supported orientations remain usable. | Not run |

## Run record

### 2026-11-11 — Simulator timer and Live Activity smoke check

- App revision: historical smoke-check snapshot on `feature/community-revival`; the current development branch is `feature/minutide-testflight`.
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

- Migration validation snapshot: the canonical checkout at `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide` was on branch `feature/community-revival` at `607d5b3164545177777ed22f45bed8187d9887a9`; the current development branch is `feature/minutide-testflight`.
- Fresh SSD CI invocation: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`, exit 0 from 22:29:46.904 to 22:32:30.882 UTC; output log `build/minutide-ssd-ci.log`.
- Result: **20 passed, 0 failed, 0 skipped** (17 unit and 3 UI) on iPhone 17 / iOS 26.5. Result bundle `build/TestResults.xcresult` was independently checked. Built app and extension plists confirm Minutide display names and bundle identifiers.
- Migration integrity is documented in `build/history/pre-ssd/migration-verification.json`; it is separate from app acceptance. No physical-device or minimum-runtime check is completed by the migration.

All other rows remain not run unless explicitly marked partial or passed above. Do not generalize simulator regressions to untested features or physical-device behavior.

### 2026-11-11 — Expanded simulator regression evidence for TestFlight candidate

- At 23:38:59.771 UTC, the expanded suite passed **39 tests (36 unit, 3 UI), 0 failures, 0 skips** on iPhone 17 / iOS 26.5. Independently verified with `xcresulttool`; result `build/TestResults.xcresult`, log `build/minutide-testflight-ci.log`.
- New coverage includes atomic manual creation/editing, archived/orphan history, rejected mutations, persisted running-timer overlap checks, delayed-location boundary/policy changes, warmed actor reads, actual running-log analytics queries, Shortcuts enumeration, malformed intervals, midnight boundaries, and 23/25-hour DST days.
- Targeted manual Simulator check: created a one-hour synthetic log through My Day → Add → Create. It appeared immediately in the timeline; Raw Data showed the saved start/end timestamps and `3600.0s` duration. This verifies creation and UI refresh; manual UI editing remains pending.
- The command used the same scheme/destination/DerivedData as CI, with per-invocation `SWIFTBUILD_LAUNCH_IN_PROCESS=1` and `-collect-test-diagnostics never`. Earlier compiler/assertion failures and the failed result are retained separately. No global Xcode setting changed.
- This run precedes bundled-notice additions. Physical iPhone, iOS 26.1 runtime, actual Shortcuts/GPS, restart, accessibility, and upgrade acceptance remain open. Automated assertions do not close the physical checklist rows.
