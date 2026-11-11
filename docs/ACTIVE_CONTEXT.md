# Active context

Last updated: 2026-11-11

## Goal

Revive the archived Stiint iOS time tracker as **Minutide**, an independently maintained, fully free, open-source app under Elaren Studio. Keep the original Xcode app target named `Stiint` and retain Liam Wittig's original MIT copyright notice. The user explicitly authorized the Minutide rename and publication under the Elaren GitHub organization on 2026-11-11.

## Verified orientation

- Working checkout: `stiint-community`, branch `feature/community-revival`.
- Starting source: upstream commit `a6f10f2d6637e9b3b330c56b818fb537357329b0` from `Liam1506/Stiint`.
- Current remote state before publication: `upstream` points to the original repository; there is no `origin` remote. The authorized destination is `elaren-studio/minutide`; verify the live destination before any push.
- App, Live Activity extension, and test targets use iOS 26.1. The internal app target is `Stiint`; display name is `Minutide` and extension display name is `Minutide Live Activity`.
- Bundle identifiers are `com.elaren.minutide`, `com.elaren.minutide.liveactivity`, `com.elaren.minutide.tests`, and `com.elaren.minutide.uitests`. Apple registration and signing are not part of source publication. The new identifier uses a separate container from prior local community builds; no cross-container migration is implemented.
- SwiftData explicitly uses `cloudKitDatabase: .none`. Activity logs can hold optional precise start/end coordinates; CSV export can contain them.
- The activity model renames `deleted` to `archived` in Swift while preserving the on-disk field mapping with `@Attribute(originalName: "deleted")`.
- `Package.resolved` pins AcknowList 3.4.0 and Sankey 2.0.0. Their checkout revisions and complete license notices are verified, recorded in `THIRD_PARTY_NOTICES.md`, bundled in the app, and displayed from local resources.

## Evidence and status

### Simulator build and manual smoke check

- At 2026-11-11 17:13:19 UTC, XcodeBuildMCP reported a warning-free build and run with Xcode 26.6 (17F113), iPhone 17 simulator, iOS 26.5, destination UUID `A0FC95C9-60F0-46AB-BBCC-CD2FBA540215`.
- Command: `xcodebuild build -project Stiint.xcodeproj -scheme Stiint -destination 'platform=iOS Simulator,id=A0FC95C9-60F0-46AB-BBCC-CD2FBA540215' CODE_SIGNING_ALLOWED=NO`.
- Build/run log: `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/logs/build_run_sim_2026-11-11T17-13-19-168Z_pid42173_79d5b3ef.log`.
- Manual flow: skipped onboarding, created synthetic activity `Community Build Review`, started its timer, saw its icon and elapsed time in the Dynamic Island and its name/time in the Lock Screen Live Activity after allowing the system prompt, terminated and relaunched the app and saw the same timer continue, then stopped it and saw the Lock Screen activity disappear. Screenshot: `docs/images/community-lock-screen.jpg`. See `DEVICE_ACCEPTANCE.md` for the bounded result.

### Automated checks

- At 2026-11-11 17:15:42 UTC, a test snapshot reported 19 passed, 0 failed, 0 skipped in 128.5 seconds: 16 unit and 3 UI tests. Result bundle: `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/result-bundles/test_sim_2026-11-11T17-15-42-834Z_pid42173_1bd0f8f5.xcresult`.
- Independent review found a historical split-tail loss for archived activity history. The fix now stages both outer segments and covered-row removal in one transaction, including orphan relationships, with rollback on failure. A regression covers this case.
- Final validation: `bash scripts/ci-ios.sh` exited 0 on 2026-11-11 at 17:27:44 UTC. The script rebuilt the final source and ran **20 tests: 17 unit, 3 UI; 0 failures, 0 skips** on the iPhone 17 / iOS 26.5 simulator. `xcrun xcresulttool get test-results summary --path build/TestResults.xcresult` independently confirmed counts. The run emitted one test-target App Intents metadata warning (the UI test runner does not import AppIntents), with no app compiler errors. Result bundle: `build/TestResults.xcresult`; full build/test log: `/private/tmp/stiint-community-final-ci.log`.
- The final Release Simulator build also passed with 0 warnings and 0 errors in 23.7 seconds, after the history fix, at 2026-11-11 17:28:30 UTC. Log: `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/logs/build_sim_2026-11-11T17-28-30-825Z_pid42173_4a3fd94a.log`.
- At 17:13 UTC, `xcrun devicectl list devices` returned no physical devices. Physical-device acceptance is still open.
- Renamed-source validation passed at 18:43:10 UTC: **20 passed, 0 failed, 0 skipped** (17 unit and 3 UI), iPhone 17 / iOS 26.5. Command: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`; result bundle `build/TestResults.xcresult` independently verified with `xcresulttool`. Log: `/private/tmp/minutide-inprocess-ci.log`. Two ordinary shell/MCP attempts stalled before compilation in a build-service output-reader issue and were explicitly canceled; they are not passes. The environment workaround applied to this invocation only. Built plists confirm both Minutide display names and identifiers. Only this task's regenerable compiler/index/intermediate caches were cleared after low disk space blocked a documentation write; sources, products, and all result bundles remain intact.
- No hosted CI result, App Store release, or public Minutide repository is verified yet. GitHub CLI account `fdtorres1` and active admin membership in `elaren-studio` (ID 308134048) were verified; `elaren-studio/minutide` returned 404 before creation. The connector exposed no organization memberships, so the authenticated CLI supplies organization and publication evidence. See [PUBLICATION.md](PUBLICATION.md).

## Next work

1. Renamed-source checks pass. Publish the authorized public fork at `elaren-studio/minutide`, keeping original history and MIT attribution; record exact commit, remote, visibility, and CI evidence after publication. The old public-name/destination question is superseded by the user's explicit instruction.
2. Validate on the iOS 26.1 minimum runtime and perform the remaining Simulator and physical-device checks in `DEVICE_ACCEPTANCE.md`.
3. Establish and verify the private security-reporting route on the new repository. Do not infer a personal support address or promise a response time.

## Handoff rules

See `AGENTS.md` for repository-specific work boundaries. Append implementation evidence to `WORKLOG.md`; update this file when the current state or next action changes.
