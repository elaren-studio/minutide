# Roadmap

The goal is a free, open-source self-build, an eventual free App Store release, and an initial processed internal TestFlight build for the maintainer. A milestone is complete only when its evidence is recorded in `ACTIVE_CONTEXT.md` and `WORKLOG.md`.

## 1. Establish a clear, free community fork — source published; hosted check pending

- Subscription and paywall source paths are removed in the current worktree; verify the integrated diff and test behavior.
- The user chose Minutide under Elaren Studio. Project settings use the Minutide display name and `com.elaren.minutide` app, extension, and test bundle identifiers; all targets currently use iOS 26.1. The internal app target remains `Stiint`. The renamed source passed all 20 tests before and after SSD migration and is published at `elaren-studio/minutide`. The hosted run failed before job steps for runner capacity, and its unchanged rerun is queued as last observed.
- The original MIT copyright is preserved. Exact pinned dependency notices are recorded and bundled in the app.
- Upstream purchase and support links have been removed; confirm final visible copy in review.
- Keep this work separate from an App Store release or an unverified public repository target.

## 2. Make tracking dependable — in progress

- Ensure an activity that was running before suspension or relaunch recovers consistently, with no duplicate or overlapping open logs.
- The final local suite passes 20 tests with 0 failures and 0 skips, including timer recovery, state transitions, archive handling, CSV export, and the historical split-tail regression. The result is recorded in `ACTIVE_CONTEXT.md`.
- Document behavior for force quit, normal backgrounding, device restart, and interrupted location access.

## 3. Complete acceptance on supported devices — in progress

- A warning-free build/run and timer/Live Activity/relaunch checks succeeded on an iPhone 17 simulator with iOS 26.5; the detailed run is in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md). The final 20-test run and final Release build also passed. Validation on the iOS 26.1 minimum and physical-device acceptance remain open.
- Exercise the main activity, timeline, analytics, CSV, App Intents, and Live Activity paths.
- Validate location opt-in and denied-permission behavior using synthetic data.
- Run the physical-device matrix in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md), recording device and OS evidence.

## 4. Prepare and deliver the first internal TestFlight build — in progress; not release-ready

- The manual-edit transaction, delayed-location guard, malformed timeline/analytics handling, overnight/DST clipping, midnight query boundaries, and archived-activity Shortcuts enumeration are implemented. The expanded simulator suite passed all 39 tests (36 unit, 3 UI), with no failures or skips.
- Complete remaining targeted simulator checks and packaging review, including embedded JavaScript notices. Keep physical-device and minimum-runtime acceptance separate.
- App and Live Activity identifiers are registered. App Store Connect record 6833697250 is verified as **Minutide: Time Tracker** / `com.elaren.minutide`; installed display name remains Minutide.
- After simulator gates pass, prepare and inspect a signed archive and exported IPA. Upload remains gated on the App Store Connect app record.
- Validate and upload the explicit IPA to the verified app record, then read back Apple's processing result and internal tester availability.
- Use the processed TestFlight build for physical Shortcuts, location permission, reboot/recovery, and minimum-runtime checks. Physical acceptance gates a stable public release.
- Keep this first milestone limited to internal TestFlight. No external tester rollout or public App Store submission is included.

## 5. Maintain the public source and prepare an eventual free App Store release

- Review the full diff, tests, and CI results for the exact release revision.
- Keep package license text aligned with each resolved revision and include the bundled notices.
- Public source, remotes, issues, and private vulnerability reporting are verified at `elaren-studio/minutide`. Confirm the hosted rerun outcome. Keep personal support details and response-time commitments unset unless explicitly chosen.
- Review privacy wording, accessibility, localization, versioning, screenshots, and release notes.
- Treat public App Store submission as a separate later action requiring review of the concrete release artifact and destination. Do not infer it from internal TestFlight distribution.

The canonical source checkout and fresh simulator validation are on the external SSD; see [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [Local Development](LOCAL_DEVELOPMENT.md). The user explicitly approved removing the verified internal rollback copies, and that guarded cleanup is complete. The SSD Git backup and historical validation artifacts remain intact.
