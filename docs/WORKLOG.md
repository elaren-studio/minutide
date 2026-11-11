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
