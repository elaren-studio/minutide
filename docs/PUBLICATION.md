# Minutide source publication

Prepared 2026-11-11. The user explicitly authorized renaming the app to Minutide and putting it under the Elaren GitHub organization. Implementation and external evidence are recorded separately below.

## Destination and scope

- Authenticated GitHub CLI profile: `fdtorres1` (ID 163592391).
- Verified organization: `elaren-studio` (ID 308134048), with active admin membership for `fdtorres1`.
- Authorized public repository: `elaren-studio/minutide`. It returned 404 before creation.
- Product name: **Minutide**. This supersedes the older Stiint Community name and personal-namespace publication proposal.
- Description: Free, open-source iOS time tracking with Live Activities, Shortcuts, timelines, charts, and CSV export. An independent continuation of Stiint.
- Public branch: `main`. Preserve original Git history and Liam Wittig's MIT copyright, with the original repository as `upstream` and Minutide as `origin`.
- Source bundle identifiers use `com.elaren.minutide`; internal Xcode project and scheme remain `Stiint`.

## Published source

The reviewed `feature/community-revival` worktree contains:

- Subscription/purchase code removed and all charts accessible.
- Minutide branding in onboarding, Settings, instructions, app metadata, and Live Activity extension metadata.
- Distinct app, extension, and test bundle identifiers, without an inherited signing team.
- Database-backed timer recovery and regression coverage.
- Adaptive Live Activity layout and system activity recovery.
- CSV export that preserves orphan and unfinished records.
- Bundled third-party license notices.
- Contributor, issue, PR, security, and handoff documentation.
- Simulator CI workflow, with unsupported runtimes failing visibly.

## Verification and publication record

The renamed Minutide source passed **20 tests, 0 failures, 0 skips** at 18:43:10 UTC on iPhone 17 / iOS 26.5. Command: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`; independently verified result bundle: `build/TestResults.xcresult`. The temporary environment setting bypassed a local Xcode build-service stall and was not persisted in the project. Built plists confirm the app and extension display names and identifiers. Source publication is verified:

- Public repository: [elaren-studio/minutide](https://github.com/elaren-studio/minutide), ID 1454368023, active and public, default branch `main`, fork parent `Liam1506/Stiint`.
- Published source commit: [`265a94e657143669e22eb09ce9c12de28a3ff1e8`](https://github.com/elaren-studio/minutide/commit/265a94e657143669e22eb09ce9c12de28a3ff1e8), read back from the public main ref after push. It preserves the original history and MIT notice.
- `origin` is `https://github.com/elaren-studio/minutide.git`; `upstream` remains `https://github.com/Liam1506/Stiint.git`. At source publication, local branch `feature/community-revival` tracked `origin/main`.
- Project description and issue tracker are configured; private vulnerability reporting is enabled and read back as true.
- [First hosted CI run](https://github.com/elaren-studio/minutide/actions/runs/43081500718), workflow_dispatch on the published source commit, failed before any job step because hosted macOS ARM64 capacity was unavailable. An unchanged rerun was requested at 22:13 UTC and was queued as last observed. Neither state is a hosted test pass; check the live rerun outcome.

The SSD migration validation used the self-contained checkout at `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide` on branch `feature/community-revival` at source revision `607d5b3164545177777ed22f45bed8187d9887a9`. Its object store had no alternates; retained-file hashes and the portable Git bundle were verified during migration. The fresh SSD CI run passed 20 tests (17 unit, 3 UI; 0 failures, 0 skips) on iPhone 17 / iOS 26.5; see [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md). The user explicitly approved deleting the three verified internal rollback folders; cleanup is complete and the SSD backup remains verified.

## Distribution boundaries

This publishes source code. No domain registration, App Store name reservation, Apple identifier registration, signed iPhone build, TestFlight release, or App Store submission is included. Physical-device acceptance remains open. The bundle-identifier change creates a separate app container from earlier local builds; no automatic cross-container migration exists.

No personal maintainer contact address or response-time promise is established. GitHub's private vulnerability-reporting flow is verified at the repository's Security tab; see `SECURITY.md`.

See [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md), [WORKLOG.md](WORKLOG.md), and [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) for validation snapshots and remaining acceptance work.

## Subsequent internal TestFlight goal — preparation only

The user later set the goal of an entirely free, open-source app that can be self-built from the public source, an eventual free App Store release, and a first processed internal TestFlight build for the maintainer. The stability changes passed all 39 simulator tests (36 unit, 3 UI), with no failures or skips, at 23:38:59.771 UTC on 2026-11-11. The app and Live Activity identifiers are registered, and App Store Connect record 6833697250 is verified as **Minutide: Time Tracker** / `com.elaren.minutide`; the bare name was unavailable. No signed archive, IPA, upload, Apple processing, or internal TestFlight availability is yet verified. This does not change the source publication record above or claim an App Store release. See [TESTFLIGHT.md](TESTFLIGHT.md).
