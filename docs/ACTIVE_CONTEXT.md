# Active context

Last updated: 2026-11-11

## Goal

Revive the archived Stiint iOS time tracker as **Minutide**, an independently maintained, fully free, open-source app under Elaren Studio. Keep the original Xcode app target named `Stiint` and retain Liam Wittig's original MIT copyright notice. The user explicitly authorized the Minutide rename and publication under the Elaren GitHub organization on 2026-11-11.

## Current feature milestone — 0.2.0 (2) available in internal TestFlight

### Follow-up UI corrections — 0.2.1 (3) in validation

- The maintainer supplied screenshots of the appearance editor, Tasks scope
  menu, and Create Log, requesting simpler styling, removal of the nested scope
  capsule, inline task creation, and manual timer start from My Day. Screenshots
  are user observations, not a completed physical acceptance matrix.
- Implemented Color/Icon rows with visual choosers and separate parent/default
  resets, one native scope surface, New Task in Create Log with UUID selection
  and preserved dates, and My Day Start Timer / Switch Task / Stop controls.
  Inline creation returns without the automation prompt. Tracking starts now
  and returns to Today; the manual chooser has a local scope and search.
- No stored model or schema changes. Version/build is 0.2.1 (3); the app and
  extension IDs and iOS 26.1 minimum are unchanged.
- XcodeBuildMCP build/run succeeded without warnings at 03:10 UTC on
  2026-11-12 (iPhone 17 / iOS 26.5). The My Day screenshot shows the Start Timer
  control above the timeline. Regression tests and delivery are still pending;
  0.2.0 (2) remains the latest verified internal beta below.

- The maintainer confirms TestFlight **0.1.0 (1)** installs and launches on his
  iPhone. Its remaining physical acceptance matrix is separate.
- Current branch: `feature/workspaces-reporting`. The hierarchy/migration and
  work-management milestone is published as `a107f6d`; reporting is now integrated.
- Implemented local organizations → clients → projects with optional task
  locations, independent color/icon inheritance, archive/restore, and scope
  switching. The global running timer and Stop control stay above the task list.
- Entries capture immutable hierarchy IDs/names/styles. Legacy history is
  migrated without inventing ancestry; date edits/splits preserve snapshots,
  while explicit reclassification uses the task's current assignment.
- Reports combine OR-within/AND-across work filters, roll up one or more levels
  or day, sort, and export summary/detail CSV. All five charts remain free.
  Date and work filter sheets apply local drafts only on confirmation.
- Validation covers **65 unit + 5 UI regression cases**. The complete run
  `build/WorkReportsFullResults-3.xcresult` passed 69/70 with one native-search
  toolbar failure; the corrected combined hierarchy/report case passed in
  `build/WorkReportsCombinedUIResults-2.xcresult` at 02:14:29 UTC on 2026-11-12.
  The sole app-source delta after that complete run is `WorkReportView.swift`;
  the focused rerun verifies it. No known test failure remains. This is not a
  claim that the earlier complete result bundle itself is green.
- The on-disk V1 migration/reopen, history invariants, combined filters, DST,
  CSV, timer recovery, all free charts, date cancellation, and pinned timer
  behavior have executed evidence. The candidate-5 SHA-256 manifest matches all
  132 source files. Original MIT notice and dependency pins are unchanged.
- Delivered **0.2.0 (2)** from source `edf830598a033136028d690a2c0e167d14289a86`,
  published on the feature branch and [PR #2](https://github.com/elaren-studio/minutide/pull/2)
  (ready for review, stacked on initial-source PR #1). No merge is performed.
- Signed archive `build/Archives/Minutide-0.2.0-2.xcarchive` and manual-export IPA
  `build/Exports/Minutide-0.2.0-2-manual/Stiint.ipa` are verified: 6,869,853 bytes,
  SHA-256 `8f67daa55ec475e563ad02e04012d4332784af7e6e50fa66a69c60b4eef179c6`. Both distribution signatures,
  identifiers/version/minimum OS, non-debug entitlements, four notices, and
  privacy reason `CA92.1` were checked. No new certificate or access grant.
- Apple validation/upload succeeded without errors. Build/delivery `0cbd1652-c1a3-41ba-b704-82901d5e4c5d`
  is `VALID` and `IN_BETA_TESTING`, assigned to `Minutide Internal`; fresh API
  readback verified availability at **2026-11-12 02:43:11 UTC**. The group still
  has only the intended maintainer, no public link, and Mac/Vision disabled.
  English beta notes are verified. No build-2 installation or email delivery is claimed.
- Receipt: `build/Verification/minutide-0.2.0-2.json`. Hosted [run 43141785036](https://github.com/elaren-studio/minutide/actions/runs/43141785036)
  **passed all 70 tests (65 unit, five UI), zero failures/skips**, on the exact
  shipped source with Xcode 26.6. The clean hosted run supersedes the local
  complete-plus-focused validation as the final full-suite result. Log/metadata
  are retained under `build/logs/` and `build/Verification/`.
- Physical 0.2 upgrade/features and minimum-runtime acceptance remain separate
  from internal delivery. The maintainer has not yet reported those results.
- Public App Store submission, external testers, and new legal agreements are
  outside this authorization. See [WORK_HIERARCHY.md](WORK_HIERARCHY.md).

## Verified orientation

- Working checkout: `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide`. The SSD baseline test run used source revision `607d5b3164545177777ed22f45bed8187d9887a9`; later release-readiness changes are in progress and are not covered by that baseline result.
- Starting source: upstream commit `a6f10f2d6637e9b3b330c56b818fb537357329b0` from `Liam1506/Stiint`.
- Verified remote state: `upstream` points to `https://github.com/Liam1506/Stiint.git`; `origin` points to `https://github.com/elaren-studio/minutide.git`. Current development branch: `feature/workspaces-reporting`.
- The canonical checkout is on the verified external APFS volume. Migration receipt: `build/history/pre-ssd/migration-verification.json`. All 788 retained project, build, and result files (74,358,536 bytes) matched their SHA-256 manifest. The copied Git object store has no alternates; refs were validated from `build/history/pre-ssd/git-state.bundle` (SHA-256 `259dea147df577983bef1c8d37ad52788162d29ad259ff67bc9b17504a3e6580`).
- App, Live Activity extension, and test targets use iOS 26.1. The internal app target is `Stiint`; display name is `Minutide` and extension display name is `Minutide Live Activity`.
- Bundle identifiers are `com.elaren.minutide`, `com.elaren.minutide.liveactivity`, `com.elaren.minutide.tests`, and `com.elaren.minutide.uitests`. Apple registration and signing are not part of source publication. The new identifier uses a separate container from prior local community builds; no cross-container migration is implemented.
- SwiftData explicitly uses `cloudKitDatabase: .none`. Activity logs can hold optional precise start/end coordinates; CSV export can contain them.
- The activity model renames `deleted` to `archived` in Swift while preserving the on-disk field mapping with `@Attribute(originalName: "deleted")`.
- `Package.resolved` pins AcknowList 3.4.0 and Sankey 2.0.0. Their checkout revisions and complete license notices are verified, recorded in `THIRD_PARTY_NOTICES.md`, bundled in the app, and displayed from local resources.

## Initial internal TestFlight milestone — TestFlight available

- The user's goal remains a fully free, open-source self-build, an eventual free App Store release, and an initial processed internal TestFlight build for the maintainer's physical testing.
- Current branch: `feature/minutide-testflight`. Candidate source commit `dec1e884cdd4561c32210e1365359c97558a00c5` is published on the branch; [pull request #1](https://github.com/elaren-studio/minutide/pull/1) is ready for review.
- App Store Connect record **6833697250**, **Minutide: Time Tracker**, bundle `com.elaren.minutide`, is verified. The app and Live Activity identifiers are registered. No Apple legal agreement was accepted, and no public App Store release is in scope.
- The expanded simulator suite passed at 23:38:59.771 UTC: **39 tests (36 unit, 3 UI), 0 failures, 0 skips**. This run preceded the notice-only acknowledgement additions; no post-notice app test run is claimed. The final source has the four bundled notices (AcknowList, Sankey, D3, d3-sankey), and the original MIT notice is unchanged.
- Signed Release archive `build/Archives/Minutide-0.1.0-1.xcarchive` succeeded. Both signature checks, privacy reason `CA92.1`, and all four notices were verified; receipt: `build/Verification/minutide-0.1.0-1.json`.
- Automatic export failed with Cloud Signing permission and missing-profile errors. Manual App Store export succeeded using the existing local distribution certificate and explicit App Store profiles; no new certificate or access grant was created. IPA: `build/Exports/Minutide-0.1.0-1-manual/Stiint.ipa`, 6,047,504 bytes, SHA-256 `0e960dc15940d35d5cb094178fd045ed1ce457e6d8d969def12a1f2551626327`. It is version `0.1.0` build `1`, has `get-task-allow=false`, beta reports active, and the app/Live Activity bundle identifiers were verified.
- Validation and upload succeeded without errors. Apple processing is `VALID` for **0.1.0 (1)**, build/delivery `591b8c17-694a-41ce-80bd-39c16a27e4a6`; internal state is `IN_BETA_TESTING`. The build is assigned to `Minutide Internal`, whose sole intended tester is `INVITED`. The website independently shows this version/build, group, and one invitation. Expiry: 2027-02-09. Installation and email delivery are not claimed.
- Internal group `Minutide Internal` contains only the intended maintainer, marked `INVITED`, and build 0.1.0 (1). No public link is active; Mac and Vision availability are disabled.
- The export helper now sets and requires `manageAppVersionAndBuildNumber=false` so export preserves the reviewed version/build. Public source and self-build procedures do not include signing credentials, private keys, team IDs, or App Store Connect API secrets. See [TESTFLIGHT.md](TESTFLIGHT.md).

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
- Published and read back [elaren-studio/minutide](https://github.com/elaren-studio/minutide), repository ID 1454368023, public, active, default branch `main`, fork parent `Liam1506/Stiint`. Source commit `265a94e657143669e22eb09ce9c12de28a3ff1e8` contains the renamed, locally tested app. The original MIT notice and upstream history remain intact. Issues and private vulnerability reporting are enabled and verified. GitHub account `fdtorres1` has active admin membership in `elaren-studio` (ID 308134048).
- The first [hosted CI run](https://github.com/elaren-studio/minutide/actions/runs/43081500718) was manually dispatched on that source commit and failed before any job step because hosted macOS ARM64 capacity was unavailable. An unchanged retry was requested at 22:13 UTC and was queued as last observed. No hosted pass is claimed. At that earlier publication checkpoint, no signed iPhone distribution or App Store release had been recorded; the later TestFlight archive, export, and upload status is documented above. See [PUBLICATION.md](PUBLICATION.md).

### SSD migration and build storage

- The local GUI workspace settings resolve build/intermediate paths under `build/DerivedData/Stiint/Build`; `MODULE_CACHE_DIR` and `COMPILATION_CACHE_CAS_PATH` are under `build/DerivedData`. GUI package checkouts are at `build/DerivedData/Stiint/SourcePackages/checkouts`; CLI checkouts are at `build/DerivedData/SourcePackages/checkouts`. The system `CACHE_ROOT` remains under `/var/folders/...`. See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md).
- The fresh SSD CI run completed at 22:32:30.882 UTC on 2026-11-11: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh` exited 0. `build/TestResults.xcresult` independently reports 20 passed (17 unit, 3 UI), 0 failed, 0 skipped on iPhone 17 / iOS 26.5. Log: `build/minutide-ssd-ci.log`. The built app and extension plists confirm the Minutide names and identifiers.
- The archived `build/history/pre-ssd/DerivedData` is retained for history. Its regenerable compiler CAS was excluded from copying. After explicit user approval to delete the verified internal copies, the guarded cleanup revalidated all 788 retained files, original source blobs/results, the Git bundle, and the fresh SSD test pass. It removed only the internal `stiint-community`, `stiint-upstream`, and `artifacts` folders at 22:56:37.889 UTC. Receipt: `build/history/pre-ssd/internal-retirement.json` has `internal_retired: true`. SSD Git integrity and the complete-history bundle were verified again afterward.
- Hosted run 43081500718 failed before any job step because hosted macOS ARM64 capacity was unavailable. An unchanged rerun was requested at 22:13 UTC and was queued as last observed. This is not a hosted test pass.

## Next work

1. Update the existing TestFlight install to 0.2.0 (2) without deleting it. Record physical upgrade/history/running-timer acceptance separately.
2. Exercise organizations, appearance, combined reports/exports, physical Shortcuts, GPS permission, reboot/recovery, and minimum-runtime behavior using `DEVICE_ACCEPTANCE.md`.
3. Review the stacked source PRs #1 and #2. The complete shipped source passed hosted CI; no merge has been performed.
4. Before a later stored-model change, freeze the shipped V2 schema and extend the ordered migration/disk fixtures.
5. Keep production App Store submission and acceptance of Apple's legal agreement as future gates.
6. Keep private vulnerability reporting and the canonical SSD source/build paths; do not invent support-address or response-time commitments.

## Handoff rules

See `AGENTS.md` for repository-specific work boundaries. Append implementation evidence to `WORKLOG.md`; update this file when the current state or next action changes.
