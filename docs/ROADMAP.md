# Roadmap

This roadmap is for the community revival, not a release promise. A milestone is complete only when its evidence is recorded in `ACTIVE_CONTEXT.md` and `WORKLOG.md`.

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

## 4. Prepare a maintainable public release — source publication complete; distribution not ready

- Review the full diff, tests, and CI results for the exact release revision.
- Keep package license text aligned with each resolved revision and include the bundled notices.
- Public source, remotes, issues, and private vulnerability reporting are verified at `elaren-studio/minutide`. Confirm the hosted rerun outcome. Keep personal support details and response-time commitments unset unless explicitly chosen.
- Review privacy wording, accessibility, localization, versioning, screenshots, and release notes.
- Treat TestFlight, App Store submission, and any signed public build as separate actions requiring a review of the concrete release artifact and destination.

The canonical source checkout and fresh simulator validation are on the external SSD; see [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [Local Development](LOCAL_DEVELOPMENT.md). The original internal rollback copies remain intact pending explicit deletion approval after automatic review rejected their removal.
