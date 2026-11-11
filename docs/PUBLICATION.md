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

## Source to publish

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

The renamed Minutide source passed **20 tests, 0 failures, 0 skips** at 18:43:10 UTC on iPhone 17 / iOS 26.5. Command: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`; independently verified result bundle: `build/TestResults.xcresult`. The temporary environment setting bypassed a local Xcode build-service stall and was not persisted in the project. Built plists confirm the app and extension display names and identifiers. No public Minutide commit or hosted CI result is claimed by this initial record. Update this section from live evidence after publication.

## Distribution boundaries

This publishes source code. No domain registration, App Store name reservation, Apple identifier registration, signed iPhone build, TestFlight release, or App Store submission is included. Physical-device acceptance remains open. The bundle-identifier change creates a separate app container from earlier local builds; no automatic cross-container migration exists.

No personal maintainer contact address or response-time promise is established. Verify a private security-reporting route on the new repository before documenting it as available.

See [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md), [WORKLOG.md](WORKLOG.md), and [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) for validation snapshots and remaining acceptance work.
