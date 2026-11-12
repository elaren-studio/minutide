# Active context

Last updated: 2026-11-11

## Goal

Revive the archived Stiint iOS time tracker as **Minutide**, an independently maintained, fully free, open-source app under Elaren Studio. Keep the original Xcode app target named `Stiint` and retain Liam Wittig's original MIT copyright notice. The user explicitly authorized the Minutide rename and publication under the Elaren GitHub organization on 2026-11-11.

## Current feature milestone — implementation in progress

- The maintainer confirms that TestFlight **0.1.0 (1)** launches on his iPhone.
  This confirms installation and launch, not the remaining physical acceptance matrix.
- Current branch: `feature/workspaces-reporting`, based on delivered-source
  handoff commit `2f5ee39878fef4bca4e9dc378553437733cb4bf8`.
- Authorized work: optional task assignment under organizations → clients →
  projects, independent appearance/inheritance, organization switching, combined
  report filtering/grouping/sorting, tests/docs, remote commits, and the next
  internal TestFlight build. Specification: [WORK_HIERARCHY.md](WORK_HIERARCHY.md).
- Existing UUIDs and history must survive migration. Historical assignment is
  captured per entry; later task moves must not recategorize earlier time.
- Storage/migration, task management UI, and reporting have separate ownership.
  Root owns integration, release checks, Git publication, and internal delivery.
- The SSD disappeared during the initial read-only review. After the user's
  reconnection, its mount and canonical clean repository were verified again.
  Implementation and builds remain on the SSD; no internal fallback is used.
- Feature implementation, disk migration proof, integrated simulator checks,
  and the next TestFlight delivery are pending. The older test results below
  cover the previous build and do not validate these new features.

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

1. Internal delivery is verified. Have the maintainer install the invited TestFlight build and record physical acceptance separately.
2. Use the TestFlight install for physical Shortcuts, GPS permission, reboot/recovery, and minimum-runtime acceptance. Keep these separate from archive signature, IPA upload, and processing evidence.
3. Rerun app tests if any source changes follow the notice additions; the 39-test result predates those acknowledgement/resource changes.
4. Check the live outcome of hosted Actions and any pull-request checks. Actions is enabled and the workflow is active; the older workflow-dispatch run was queued, and no PR check/run was observed for PR #1. The cause is not established.
5. Keep production App Store submission and acceptance of Apple's legal agreement as future gates.
6. Private reporting is verified at the repository's Security tab. Keep personal support addresses and response-time commitments unset unless explicitly chosen.

## Handoff rules

See `AGENTS.md` for repository-specific work boundaries. Append implementation evidence to `WORKLOG.md`; update this file when the current state or next action changes.
