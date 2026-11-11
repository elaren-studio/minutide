# Work log

Append dated entries. Record what changed and what evidence was actually collected; do not rewrite earlier entries.

## 2026-11-11 — Community revival documentation baseline

- Added community README, contributor and security guidance, repository-agent instructions, third-party dependency inventory, roadmap, decisions, current context, device acceptance checklist, and GitHub issue/PR templates.
- Reviewed the starting source, Xcode project settings, `Package.resolved`, existing README, license, and test targets. Confirmed optional location fields in the activity-log model and their presence in CSV export.
- Confirmed the upstream app MIT copyright notice remains in `LICENSE`.
- No build or test was run as part of this documentation pass. Root-reported compilation applies to the original upstream baseline only; it is not evidence for the integrated fork.

## 2026-11-11 — Documentation synced to integration review

- Confirmed the Swift Package Manager checkout revisions match `Package.resolved`; copied the pinned AcknowList MIT and Sankey BSD 2-Clause notices into `THIRD_PARTY_NOTICES.md`.
- Rechecked current Xcode settings: community display name and app/extension/test bundle identifiers are set; the app target minimum is iOS 26.1; SwiftData explicitly disables CloudKit.
- Added a privacy note that the acknowledgements dependency may fetch missing license text from GitHub; no network traffic audit was performed.
- Root reports an integrated-fork Simulator build and run succeeded; exact command and destination are still to be recorded. Tests remain in progress.
- No build or test was run as part of this documentation pass.

## 2026-11-11 — Verified Simulator evidence and pending regression fix

- Corrected the upstream source hash to `a6f10f2d6637e9b3b330c56b818fb537357329b0`; added the community Lock Screen screenshot and CI-equivalent `bash scripts/ci-ios.sh` command to contributor guidance.
- Recorded the warning-free iPhone 17 / iOS 26.5 simulator build and manual timer, Dynamic Island, Lock Screen, stop, and relaunch recovery smoke check in `ACTIVE_CONTEXT.md` and `DEVICE_ACCEPTANCE.md`. Build/run log: `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/logs/build_run_sim_2026-11-11T17-13-19-168Z_pid42173_79d5b3ef.log`.
- Recorded the 19-test pass snapshot (16 unit, 3 UI; 0 failures, 0 skipped) and its result bundle. A later review found archived-history split-tail loss; the fix and 20th regression test are in progress, so the snapshot is not final evidence for the current working tree.
- Recorded the later release Simulator build (0 warnings, 0 errors) as an earlier snapshot, not validation of the pending history fix.
- Updated all target minimums to iOS 26.1, documented the locally bundled dependency license resources and archived-field mapping, and corrected the remote state: `upstream` points to Liam1506/Stiint, with no `origin`. The proposed community repository returned 404 and remains unpublished.
- No build or tests were run by the documentation worker.

## 2026-11-11 — Final local revival validation

- Removed the original subscription manager and paywall UI, unlocked all five charts, added independent community branding, and preserved MIT attribution.
- Fixed database-backed recovery without deleting unfinished history, serialized timer operations, and renamed the archive field with original-name mapping. Regression tests caught and verified the archive flag correction.
- Corrected archived and orphan historical splits to retain both outer segments and commit the split in one save/rollback transaction. Independent review's medium finding is resolved and regression tested.
- CSV export retains completed, unfinished, malformed, and orphan rows with correct escaping and without inventing stop times. Third-party license texts are bundled locally and match the resolved dependency checkouts.
- Ran `bash scripts/ci-ios.sh` against the final source. Exit 0 at 17:27:44 UTC; `build/TestResults.xcresult` independently reports 20 passed, 0 failed, 0 skipped (17 unit, 3 UI) on iPhone 17 / iOS 26.5. Full log: `/private/tmp/stiint-community-final-ci.log`. The UI test target emitted the expected metadata-extraction warning because it has no AppIntents dependency; no app compiler error occurred.
- Rebuilt final Release configuration successfully with 0 warnings/errors in 23.7 seconds at 17:28:30 UTC. Log: `/Users/felixtorres/Library/Developer/XcodeBuildMCP/workspaces/are-there-ios-time-tracking-apps-d9a194e0d7d5/logs/build_sim_2026-11-11T17-28-30-825Z_pid42173_4a3fd94a.log`.
- Confirmed valid plists, unchanged upstream MIT license, exact bundled dependency notices, and clean diff whitespace. Removed 15 inherited Finder metadata files from the community checkout only.
- No physical device was connected. Minimum-runtime, physical-device, long-session hardware checks, hosted CI, and public publication remain separate uncompleted gates. `docs/PUBLICATION.md` records the concrete source publication proposal.

## 2026-11-11 — Publication handoff reconciliation

- Rechecked the active branch and remotes: `feature/community-revival`, original repository as `upstream`, no `origin` and no public community publication observed.
- Synced the roadmap to the final 20-test and Release-build results; removed stale wording that described the historical split fix as still in progress.
- Preserved the pending public name/destination question. An automatic continuation of the goal does not answer that question or authorize publication.

## 2026-11-11 — Minutide candidate-name screen

- The user requested a different name, liked Minutide, and asked for a more thorough check. The previous Stiint Community publication-name question is superseded; no replacement publication destination or external action is implied by the research request.
- Added `NAME_RESEARCH_MINUTIDE.md` with dated primary-source checks, links, observations, and limits. Apple US/UK/Canada catalog searches, Google Play US search, and GitHub public repository/account searches identified no exact Minutide app or project. Direct .com/.app/.org registry RDAP checks returned 404; purchase availability and pricing were not checked.
- Recorded actual similar uses: itide's Minitide logistics portal, Valeport's miniTide water-level recorder, and EG's MinTid workplace scheduling app. Exact Minutide also appears in a generated NameStation name list.
- Independent live USPTO field-tag checks returned no results for `CM:minutide` and `CM:minitide`; a positive control `CM:apple` returned 5,100 results. Several additional phrase/class queries returned no results, but the 1,001-result broad substring search was not fully reviewed. This is a bounded screen, not legal or worldwide clearance.
- Updated current-context and publication-proposal notes to preserve the pending name choice. Product code, display name, bundle identifiers, domains, remotes, and public services were not changed. No build or app test was needed for this documentation-only pass; whitespace validation passed.

## 2026-11-11 — Authorized Minutide rename and source preparation

- The user chose Minutide and explicitly authorized publication under Elaren. Verified CLI account `fdtorres1` and active admin membership in `elaren-studio` (ID 308134048); intended repository `elaren-studio/minutide` returned 404. Original archived public MIT repository still has main at the starting baseline.
- Renamed visible onboarding, instructions, Settings, acknowledgements section, app/extension metadata, logger fallback, and test attachment label. App, extension, and test IDs now use `com.elaren.minutide`. Internal Xcode names and original attribution remain. Updated README, contributor guidance, issue template, security wording, current context, decisions, roadmap, and publication plan. Historical records keep their snapshot names.
- Two ordinary Xcode attempts stalled during compiler discovery; samples showed clang blocked writing to a pipe while the separate SwiftBuild service was idle. The exact compiler command succeeded independently. Both stalled attempts were explicitly canceled without touching unrelated services or stores.
- `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh` succeeded at 18:43:10 UTC. Independently read `build/TestResults.xcresult`: 20 passed, 0 failed, 0 skipped (17 unit, 3 UI), iPhone 17 / iOS 26.5. Built plists confirm names/IDs. Log: `/private/tmp/minutide-inprocess-ci.log`. The workaround applies only to this invocation; no project/system setting was persisted.
- Low disk space subsequently blocked the documentation write. Cleared only this task's regenerable build intermediates, compiler module caches, and indexing caches in `build/DerivedData` and `/private/tmp/stiint-community-build`; kept sources, products, and every result bundle. Free space recovered to about 1.1 GiB. The failed documentation write left no source/document diff and was retried after cleanup.
- Confirmed unchanged original LICENSE, valid project/plist syntax, no old community-name/ID literals in active Swift/project settings, no signing/key/database files in the payload, and no matched common credential patterns. Staged whitespace checks pass. These bounded checks are not an independent security audit.
- Source publication is the next authorized action. No signed app distribution, domain purchase, or App Store reservation is included.

## 2026-11-11 — Public Minutide source publication

- Created the authorized public fork `elaren-studio/minutide` (ID 1454368023), default branch main, parent Liam1506/Stiint; verified owner, visibility, active status, and admin access. The CLI rejected an unsupported --remote flag before any creation; the supported explicit-repository fork command then succeeded.
- Pushed source commit `265a94e657143669e22eb09ce9c12de28a3ff1e8` to main and independently read back the exact SHA. Original upstream history and LICENSE remain intact. Origin now points to Minutide and upstream remains the original repository. Local feature/community-revival tracks origin/main.
- Set the project description and enabled issues. Enabled private vulnerability reporting and read back enabled=true; updated SECURITY.md to the verified GitHub flow without publishing personal contact details or support commitments.
- Workflow iOS is active. Dispatched hosted run 43081500718 on the tested source commit; it is queued as last checked on 2026-11-11. No hosted pass, hardware acceptance, or signed distribution is claimed.
- Local disk space again fell to about 100 MiB after task-cache cleanup. Final publication documentation was prepared from the exact published files and committed via GitHub API with [skip ci]; this avoids source/test/workflow changes and redundant testing. Verify local synchronization with origin/main before further work.

## 2026-11-11 — SSD migration and development handoff

- The canonical checkout is now `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide` on the verified external APFS volume. Local branch `feature/community-revival` is at `607d5b3164545177777ed22f45bed8187d9887a9`, tracks `origin/main`, and retains the original `upstream` remote.
- Migration verification retained all 788 project, build, and result files (74,358,536 bytes) with matching SHA-256 hashes. The SSD Git object store is independent, has no alternates, and its refs passed validation from portable bundle `build/history/pre-ssd/git-state.bundle` (SHA-256 `259dea147df577983bef1c8d37ad52788162d29ad259ff67bc9b17504a3e6580`). Receipt: `build/history/pre-ssd/migration-verification.json`.
- Historical preview artifacts and the old DerivedData snapshot are retained under `build/history/pre-ssd/`. The 25 GB regenerable compiler CAS was excluded from copying and is rebuilt fresh. The original internal source copy has not yet been retired.
- Xcode GUI's local ignored workspace settings resolve build/intermediate paths, module caches, and Swift package checkouts under `build/DerivedData`; `CACHE_ROOT` remains in the system-managed `/var/folders/...` area. The CLI CI script uses the same repository-local DerivedData root with a different subfolder layout. See `LOCAL_DEVELOPMENT.md`.
- Fresh SSD simulator validation is in progress: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh`, log `build/minutide-ssd-ci.log`. Result is pending; no SSD test pass is recorded here. Root should append the exact outcome after checking the result bundle.
- Hosted run 43081500718 failed before any job step because hosted macOS ARM64 capacity was unavailable. An unchanged rerun was requested at 22:13 UTC and was queued as last observed. No hosted pass is claimed.
- This handoff updates documentation only; no application, test, project, workflow, or license source was changed.

## 2026-11-11 — Fresh SSD simulator validation

- Root completed `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh` on the canonical SSD checkout from 22:29:46.904 to 22:32:30.882 UTC; exit code 0.
- `build/TestResults.xcresult` independently reports 20 passed (17 unit, 3 UI), 0 failed, 0 skipped on iPhone 17 / iOS 26.5. Full log: `build/minutide-ssd-ci.log`.
- Built app and Live Activity extension plists confirm Minutide display names and the `com.elaren.minutide` identifiers. This confirms the fresh SSD simulator run; iOS 26.1 minimum-runtime and physical-device acceptance remain open.
- The original internal source copy remains pending guarded retirement. Hosted run 43081500718's unchanged rerun was still queued as last observed; no hosted pass is claimed.

## 2026-11-11 — Internal rollback copies retained

- The final retention audit revalidated all 788 retained files, original source blobs in SSD Git, the portable all-refs bundle, and original results after archival/renaming; the fresh SSD result passed 20 tests with no failures/skips. Receipt: `build/history/pre-ssd/internal-retirement.json`.
- Automatic approval review rejected the requested removal of the internal linked worktree, shared upstream Git directory, and preview artifacts because migration authorization did not explicitly cover irreversible deletion. The deletion command did not run. All originals remain intact; explicit deletion approval is the remaining cleanup gate. Continue development from the verified SSD checkout.

## 2026-11-11 — Explicitly approved internal-copy cleanup

- The user selected **Delete verified internal copies**, explicitly approving removal of the internal `stiint-community`, `stiint-upstream`, and `artifacts` folders while retaining the verified SSD repository and Git backup.
- Re-ran the guarded retention audit: actual SSD mount, independent Git object store, clean original checkouts, no stashes or unexpected linked worktrees, all 788 retained file hashes and the complete retained-file set, original source blobs/results, preview artifacts, portable Git bundle, and the fresh SSD test pass were verified before deletion.
- Cleanup completed at 22:56:37.889 UTC. `build/history/pre-ssd/internal-retirement.json` records `internal_retired: true`. The three approved internal directories are absent; no other workspace folders were removed.
- Rechecked SSD `git fsck --full` (exit 0) and the complete-history Git bundle after removal. The SSD worktree remained clean. Saved products/results and the 20-test SSD result remain intact. These documentation-only updates do not require rerunning unchanged application tests.
- Internal disk free space was reported as about 13 GiB afterward; no exact amount of physically reclaimed storage is claimed.

## 2026-11-11 — Internal TestFlight tooling prepared

- Added self-contained archive, local App Store Connect export, and explicit IPA validate/upload scripts. They default outputs and logs under `build/`, quote paths, refuse existing archive/export destinations, do not change version numbers or make commits, and keep credentials as local inputs.
- Documented the free/open-source self-build goal, first internal TestFlight milestone, eventual free App Store intent, Apple setup prerequisites, processing/readback boundary, and the pending release gates. Expanded the device-acceptance checklist for edit persistence, malformed records, overnight intervals, and archived-activity Shortcuts enumeration.
- Preparation is not release evidence: no application build/tests, signed archive, IPA, upload, Apple processing, or tester availability was performed by this tooling/docs pass. The prior SSD 20-test result remains baseline evidence only for the reviewed release changes.

## 2026-11-11 — TestFlight preparation status refresh

- The app and Live Activity bundle identifiers are registered and read back in the verified paid developer team. The App Store Connect app record is still absent; website sign-in is pending while the exact credential item title is located. No credential value was retrieved or recorded.
- Analytics, project settings, privacy, and Shortcuts changes are integrated on `feature/minutide-testflight`. The app/extension bundle-base override was read back with `com.example.minutide` and `com.example.minutide.liveactivity`; source signing team remains blank and the current target family is iPhone-only.
- Initial compile fixes are applied. The first expanded simulator run reached tests: manual/location-10 and Shortcuts passed, while numeric optional-value assertions failed. Assertion fixes and rerun remain pending; no overall expanded-suite pass is claimed.
- The manual-edit location-metadata race guard and actual running-log query regression remain in progress. No signed archive, IPA, upload, Apple processing, internal tester availability, or physical-device acceptance is verified. Physical acceptance is intended to follow the first internal TestFlight availability; public release readiness remains a later gate.

## 2026-11-11 — Manual/location regression runtime update

- The manual-edit location-metadata race guard and actual running-log query regression are now integrated. All 10 related manual/location cases passed at runtime.
- The first expanded simulator run exposed numeric optional-value assertion failures. A full expanded rerun remains pending; no overall suite pass is claimed.
- The first internal TestFlight build is intended to provide the maintainer's physical-test device. Physical Shortcuts, GPS, reboot/recovery, and minimum-runtime acceptance remain open for after processing and internal availability.

## 2026-11-11 — Integrated stability suite and Apple app record

- Implemented atomic manual-log creation/editing, delayed-location boundary/identity/policy validation, running-log analytics queries, finite clipped intervals with calendar-day/DST splitting, midnight timeline overlap queries, and archived/malformed activity exclusion in Shortcuts. Added 19 regressions to the prior 20-test suite.
- Fixed the query's required zero-argument initializer and clarified expected `Double` values in Swift Testing assertions after compiler/assertion failures. The first runtime run had 35 passes and 2 failures; its result is retained as `build/TestResults-assertions.xcresult`. Its automatic simulator diagnostic collector was explicitly stopped after tests completed so Xcode could finalize that failed result.
- The corrected suite ran from 23:36:30.672 to 23:38:59.771 UTC and passed **39 tests: 36 unit, 3 UI; 0 failures, 0 skips**. `xcresulttool get test-results summary --path build/TestResults.xcresult` independently verified counts. Log: `build/minutide-testflight-ci.log`. Invocation: `env SWIFTBUILD_LAUNCH_IN_PROCESS=1 xcodebuild test -project Stiint.xcodeproj -scheme Stiint -destination 'platform=iOS Simulator,id=A0FC95C9-60F0-46AB-BBCC-CD2FBA540215' -derivedDataPath build/DerivedData -resultBundlePath build/TestResults.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO`.
- Manually created a synthetic one-hour log through My Day; it appeared immediately in the timeline and Raw Data with saved timestamps and `3600.0s`. Physical acceptance remains separate.
- Registered/read back app and Live Activity identifiers. After the maintainer signed in directly, Apple rejected the bare Minutide name. Created and API-verified **Minutide: Time Tracker**, app 6833697250, bundle `com.elaren.minutide`, SKU `minutide-ios`, locale `en-US`, Limited Access. The installed display name remains Minutide. No legal agreement was accepted.
- Added one configurable bundle-ID base for self-builds, restricted the extension to the host's iOS/iPhone platforms, and included the app-only UserDefaults privacy reason. Signing team remains blank in source. Archive/export/upload and processing are still pending at this entry.
