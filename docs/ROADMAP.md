# Roadmap

The goal is a free, open-source self-build, an eventual free App Store release, and an initial processed internal TestFlight build for the maintainer. A milestone is complete only when its evidence is recorded in `ACTIVE_CONTEXT.md` and `WORKLOG.md`.

## Current priority: work hierarchy and combined reporting — internal beta delivered

Follow-up 0.2.3 (5) is in validation: Resume Timer from completed entries and a
new Minutide logo/app icon. Resume preserves the recorded work details in a
separate interval; no stored-model change. Build 4 remains the latest verified
internal beta until build-5 delivery is read back.

Follow-up **0.2.2 (4)** is processed and available in the existing internal group:
bottom tracking/Stop, richer Live Activity, brief-entry visibility, My Day
Timeline/List modes, and adaptive Reports cards/sorting. Final exact-source
hosted run 43157603328 passed **86 tests (76 unit, ten UI), zero failures/skips**;
larger-text My Day and Reports checks also passed. No stored-schema change.
Physical acceptance remains open; see `ACTIVE_CONTEXT.md` and `DEVICE_ACCEPTANCE.md`.

Follow-up **0.2.1 (3)** is processed and available to the existing internal group:
simpler appearance choosers, one native scope surface, inline task creation in
Create Log, and manual tracking from My Day. Final hosted run 43148292343 passed
all **73 tests (65 unit, eight UI), zero failures/skips**, on the released source.
Physical acceptance is the next product gate.

The maintainer confirms the first TestFlight build launches on his iPhone. The
next authorized internal beta adds organizations, clients, projects, optional
task locations, independent appearance/inheritance, organization scope, and
combined report filtering/grouping/sorting. Preserve the existing store and
prove its migration on disk. See [WORK_HIERARCHY.md](WORK_HIERARCHY.md) for the
behavior and acceptance contract. The source implementation and 65 unit plus
five UI regression cases are validated, with the final search fix verified in a
focused rerun. Source `edf8305` is published in ready-for-review PR #2; signed **0.2.0 (2)**
is processed and available to the existing internal maintainer group. Physical
upgrade/features and minimum-runtime acceptance remain open. Hosted CI for the
exact shipped source passed all **70 tests (65 unit, five UI), zero failures/skips**;
run 43141785036 is the final complete-suite evidence.

## 1. Establish a clear, free community fork — source published; hosted check pending

- Subscription and paywall source paths are removed in the current worktree; verify the integrated diff and test behavior.
- The user chose Minutide under Elaren Studio. Project settings use the Minutide display name and `com.elaren.minutide` app, extension, and test bundle identifiers; all targets currently use iOS 26.1. The internal app target remains `Stiint`. The renamed source passed all 20 tests before and after SSD migration and is published at `elaren-studio/minutide`. The hosted run failed before job steps for runner capacity, and its unchanged rerun is queued as last observed.
- The original MIT copyright is preserved. Exact pinned dependency notices are recorded and bundled in the app.
- Upstream purchase and support links have been removed; confirm final visible copy in review.
- Keep this work separate from an App Store release or an unverified public repository target.

## 2. Make tracking dependable — in progress

- Ensure an activity that was running before suspension or relaunch recovers consistently, with no duplicate or overlapping open logs.
- The expanded stability suite passes 39 tests with 0 failures and 0 skips, including timer recovery, manual-edit integrity, delayed-location safeguards, archived/orphan history, CSV, Shortcuts queries, midnight boundaries, and DST analytics. The result is recorded in `ACTIVE_CONTEXT.md`.
- Document behavior for force quit, normal backgrounding, device restart, and interrupted location access.

## 3. Complete acceptance on supported devices — in progress

- A warning-free build/run and timer/Live Activity/relaunch checks succeeded on an iPhone 17 simulator with iOS 26.5; the detailed run is in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md). The later 39-test stability run and signed Release archive also passed. Validation on the iOS 26.1 minimum and physical-device acceptance remain open.
- Exercise the main activity, timeline, analytics, CSV, App Intents, and Live Activity paths.
- Validate location opt-in and denied-permission behavior using synthetic data.
- Run the physical-device matrix in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md), recording device and OS evidence.

## 4. Deliver the first internal TestFlight build — internal TestFlight available

- Current source candidate `dec1e884cdd4561c32210e1365359c97558a00c5` is published on `feature/minutide-testflight`; [pull request #1](https://github.com/elaren-studio/minutide/pull/1) is ready for review.
- The 39-test simulator suite passed (36 unit, 3 UI; 0 failures, 0 skips) before notice-only acknowledgement additions. The final source includes all four notices and retains the original MIT notice; no post-notice test run is claimed.
- App and Live Activity identifiers are registered. App Store Connect record 6833697250 is verified as **Minutide: Time Tracker** / `com.elaren.minutide`.
- Signed Release archive `build/Archives/Minutide-0.1.0-1.xcarchive` and manual IPA `build/Exports/Minutide-0.1.0-1-manual/Stiint.ipa` (0.1.0 build 1, 6,047,504 bytes) are verified. Both signature checks, privacy reason `CA92.1`, all four notices, bundle identifiers, `get-task-allow=false`, and beta reports active were read back. Receipt: `build/Verification/minutide-0.1.0-1.json`.
- Automatic export failed with Cloud Signing permission and missing-profile errors. Manual export used the existing local distribution certificate and explicit App Store profiles, without creating a new certificate or access grant. Export options preserve the reviewed version/build with `manageAppVersionAndBuildNumber=false`.
- Validation and upload succeeded without errors. Apple processing is `VALID` for **0.1.0 (1)**, build/delivery `591b8c17-694a-41ce-80bd-39c16a27e4a6`; internal state is `IN_BETA_TESTING`. The build is assigned to `Minutide Internal`, whose sole intended tester is `INVITED`. The website independently shows this version/build, group, and one invitation. Expiry: 2027-02-09. Installation and email delivery are not claimed.
- Internal group `Minutide Internal` contains only the intended maintainer, marked `INVITED`, and build 0.1.0 (1). No public link is active; Mac and Vision availability are disabled.
- Use the first TestFlight install for physical Shortcuts, location, reboot/recovery, and minimum-runtime acceptance. These tests are pending and gate stable public release readiness.
- The Apple legal agreement remains unaccepted. No public App Store submission or production release is in scope.

## 5. Maintain the public source and prepare an eventual free App Store release

- Review the full diff, tests, and CI results for the exact release revision.
- Keep package license text aligned with each resolved revision and include the bundled notices.
- Public source, remotes, issues, and private vulnerability reporting are verified at `elaren-studio/minutide`. Confirm the hosted rerun outcome. Keep personal support details and response-time commitments unset unless explicitly chosen.
- Review privacy wording, accessibility, localization, versioning, screenshots, and release notes.
- Treat public App Store submission as a separate later action requiring review of the concrete release artifact and destination. Do not infer it from internal TestFlight distribution.

The canonical source checkout and fresh simulator validation are on the external SSD; see [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [Local Development](LOCAL_DEVELOPMENT.md). The user explicitly approved removing the verified internal rollback copies, and that guarded cleanup is complete. The SSD Git backup and historical validation artifacts remain intact.
