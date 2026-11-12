# Minutide self-build and internal TestFlight

Last reviewed: 2026-11-12 local time and UTC. This records verified internal betas and repeatable self-build procedures. Public App Store release remains a separate step.

## Current internal beta — 0.2.3 (5)

- Resume Timer at the top of completed-entry details creates a new interval
  with recorded task/assignment/style, preserving the old entry and gap. It
  handles one global timer, current availability/location opt-in, paused tracking,
  and unsaved edits. New Minutide app/welcome icon; no stored-model change.
- Source `c8def1d4c7fbc3a6ba03b6538330a09d9b50d2e9` is published in PR #2.
  Final focused run passed **87 unit tests plus one UI case**, zero failures/
  skips, at accessibility-medium text size. Normal Resume UI also passed.
  Final exact-source
  [hosted run 43162400317](https://github.com/elaren-studio/minutide/actions/runs/43162400317)
  passed **98 tests (87 unit, 11 UI), zero failures/skips**, with `TEST SUCCEEDED`
  at **2026-11-12 06:01:55 UTC**. This is the final complete-suite evidence.
  All 141 candidate hashes (125 product files) match Git and the signed build.
- Archive `build/Archives/Minutide-0.2.3-5.xcarchive` and IPA
  `build/Exports/Minutide-0.2.3-5-manual/Stiint.ipa` are verified. IPA:
  **4,153,776 bytes**, SHA-256
  `ce8ca72139c6f16c16df8f91ef81bc59eea946f2f62fafee48583b432378c7ec`.
  Both signatures/profiles/entitlements, IDs/version/build, iOS 26.1, four
  notices, `CA92.1`, and `MinutideIcon` primary-icon metadata passed.
- Apple validation/upload succeeded without errors. Delivery/build
  `cd4ad8e6-1f70-4763-b599-3e6238277e7d` is `VALID` / `IN_BETA_TESTING` in
  the existing internal group, independently verified at **2026-11-12 05:41:51 UTC**.
  Assignment/English notes were read back; the same sole maintainer, disabled
  public link, and disabled Mac/Vision availability are verified. Receipt:
  `build/Verification/minutide-0.2.3-5.json`.
- Physical build-5 acceptance and email delivery remain unverified. Update
  without deleting the app. Public release, external testers, new signing/access
  grants and legal-agreement acceptance remain outside this internal delivery.

## Previous internal beta — 0.2.2 (4), historical

- Bottom Start/running controls with independent Stop, My Day Timeline/List and
  brief-entry seconds, captured-context Live Activity details, and adaptive
  Reports cards, legends, exports, and sorting controls. No stored-model change.
- Final source `59a1f12f498f4befb28d7bb764300694ca846d22` is published in PR #2.
  Earlier source `00def43` passed all 86 local and hosted tests (76 unit, ten UI),
  zero failures/skips. Final accessibility-size Reports checks passed after a
  screenshot-driven sorting correction. Final exact-source
  [hosted run 43157603328](https://github.com/elaren-studio/minutide/actions/runs/43157603328)
  passed **86 tests (76 unit, ten UI), zero failures/skips**, with `TEST SUCCEEDED`
  at **2026-11-12 05:16:14 UTC**. My Day's larger-text flow passed separately.
- Archive `build/Archives/Minutide-0.2.2-4.xcarchive` and IPA
  `build/Exports/Minutide-0.2.2-4-manual/Stiint.ipa` are verified. IPA size:
  **7,125,052 bytes**; SHA-256
  `a0513d810cced28aae554633e09abfe323334d67e3b847e1385f89f585b7fc97`.
  Both signatures, distribution profiles/entitlements, IDs/version/build,
  minimum iOS 26.1, four notices, and `CA92.1` passed. The superseded first
  signed candidate was retained separately and never uploaded.
- Apple validation/upload succeeded without errors. Delivery/build
  `9717a731-94ea-43e5-9cd2-c1c0c7a1db0f` is `VALID` / `IN_BETA_TESTING` in
  `Minutide Internal`; assignment and English notes were read back independently.
  Availability verified at **2026-11-12 04:59:17 UTC**. The group still contains
  only the intended maintainer, public link disabled, Mac/Vision disabled.
  Receipt: `build/Verification/minutide-0.2.2-4.json`.
- Physical build-4 acceptance and email delivery are unverified. Update without
  deleting the app. Public submission, external testers, new certificates/access
  grants, and acceptance of Apple's legal agreement remain outside this delivery.

## Previous internal beta — 0.2.1 (3), historical

- Simplified Color/Icon rows and visual choosers with independent resets; one
  native scope surface; inline task creation and selection in Create Log; and
  My Day Start Timer, Switch Task, and Stop. Inline task creation preserves log
  dates and skips the automation prompt. The chooser keeps new tasks first.
- Source `a6e629a26faca5b0dd4834b02bd192ca15508aba` is published in PR #2.
  No stored model, dependency, identifier, minimum-runtime, or notice changes.
  The full local dark-mode run passed 70/73; all three corrected UI cases then
  passed. Final hosted [run 43148292343](https://github.com/elaren-studio/minutide/actions/runs/43148292343)
  passed all **73 tests (65 unit, eight UI), zero failures/skips**, on that exact
  released source with Xcode 26.6. The clean hosted run is the final full-suite
  evidence; the earlier local complete bundle retains its recorded failures.
- Archive `build/Archives/Minutide-0.2.1-3.xcarchive` and IPA
  `build/Exports/Minutide-0.2.1-3-manual/Stiint.ipa` are verified. IPA size:
  **6,992,929 bytes**; SHA-256
  `7ddd1cefe419a1d9a273167037df1ff7229cbda2b3311f79441f79b840fa0572`.
  Both signatures, distribution profiles/entitlements, IDs/version/build,
  iOS 26.1, four notices, and `CA92.1` passed; existing signing assets were reused.
- Apple validation/upload succeeded without errors. Delivery/build
  `cb6b3643-c3b3-4996-a24d-845d319fed13` is `VALID` / `IN_BETA_TESTING` in
  `Minutide Internal`; assignment and English beta notes were read back twice.
  Availability was independently verified at **2026-11-12 03:38:49 UTC**.
- The sole intended maintainer remains the only tester; public link, Mac, and
  Vision availability remain disabled. No external tester, public App Store
  submission, new certificate/access grant, or legal-agreement acceptance.
  Receipt: `build/Verification/minutide-0.2.1-3.json`. Physical build-3 acceptance
  and email delivery are unverified. Update without deleting the app.

## Previous internal beta — 0.2.0 (2), historical

- Branch `feature/workspaces-reporting` implements local organization/client/
  project/task management, independent inherited appearance, immutable entry
  assignment, and combined reporting/CSV. See `WORK_HIERARCHY.md`.
- Local validation covers 65 unit and five UI cases, including real disk-store
  migration. The complete run passed 69/70; the final search-toolbar case passed
  in a focused rerun. Exact evidence and bounded claims are in `ACTIVE_CONTEXT`.
- Source `edf830598a033136028d690a2c0e167d14289a86` is published on the feature branch;
  [PR #2](https://github.com/elaren-studio/minutide/pull/2) is ready for review, stacked on #1.
- Signed archive `build/Archives/Minutide-0.2.0-2.xcarchive` and IPA
  `build/Exports/Minutide-0.2.0-2-manual/Stiint.ipa` are verified. IPA size:
  6,869,853 bytes; SHA-256 `8f67daa55ec475e563ad02e04012d4332784af7e6e50fa66a69c60b4eef179c6`.
  App and extension signatures, distribution profiles, version/build, IDs,
  minimum iOS 26.1, non-debug/beta entitlements, four notices, and `CA92.1` passed.
- Validation/upload succeeded without errors. Apple build/delivery `0cbd1652-c1a3-41ba-b704-82901d5e4c5d`
  is `VALID`, with internal state `IN_BETA_TESTING`. Group assignment and English
  beta notes were read back; availability was independently rechecked at
  **2026-11-12 02:43:11 UTC**. Expiry: `2027-02-09T18:34:37-08:00`.
- `Minutide Internal` still contains only the intended maintainer; no public link
  is enabled and Mac/Vision availability is disabled. No new tester, production
  submission, certificate/access grant, or legal-agreement acceptance occurred.
  Receipt: `build/Verification/minutide-0.2.0-2.json`.
- Hosted [run 43141785036](https://github.com/elaren-studio/minutide/actions/runs/43141785036)
  passed all **70 tests (65 unit, five UI), zero failures/skips**, on the exact
  shipped source with Xcode 26.6. This is the final clean full-suite result.
  Metadata/logs are retained in the local receipt; physical acceptance is separate.
- The maintainer confirms build 0.1.0 (1) installs and launches on his iPhone.
  Build-2 installation, email delivery, and physical upgrade/feature acceptance are not claimed. Update through TestFlight without deleting the app to preserve its local store.

## First beta record — 0.1.0 (1), historical

- The product goal is a fully free, open-source app that contributors can self-build from the public source, an eventual free App Store release, and an initial processed internal TestFlight build for the maintainer.
- The public source is available at [elaren-studio/minutide](https://github.com/elaren-studio/minutide). A Simulator self-build needs Xcode and the pinned Swift packages; it does not require Apple signing.
- The current branch is `feature/minutide-testflight`, source commit `dec1e884cdd4561c32210e1365359c97558a00c5` is published there, and [pull request #1](https://github.com/elaren-studio/minutide/pull/1) is ready for review.
- Analytics, project settings, privacy, and Shortcuts changes are integrated on the current branch. The manual-edit location-metadata race guard and actual running-log query regression are integrated; all 10 relevant manual/location cases passed at runtime.
- The bundle-base override was read back for the app and Live Activity identifiers using `com.example.minutide` and `com.example.minutide.liveactivity`; the signing team remains blank in source and the current target family is iPhone-only.
- The expanded simulator suite passed **39 tests (36 unit, 3 UI), 0 failures, 0 skips**, at 23:38:59.771 UTC; `xcresulttool` independently confirmed `build/TestResults.xcresult`. This run preceded the notice-only acknowledgement additions; no post-notice app test run is claimed.
- The final source contains full AcknowList, Sankey, D3, and d3-sankey notices. The original MIT notice is unchanged. The first TestFlight build is intended to support the maintainer's physical-device acceptance run.
- The app and Live Activity identifiers are registered. [App Store Connect record 6833697250](https://appstoreconnect.apple.com/apps/6833697250) is verified as **Minutide: Time Tracker**, bundle `com.elaren.minutide`, SKU `minutide-ios`, language `en-US`. The bare Minutide name was unavailable; the installed app display name remains Minutide.
- The maintainer completed Apple sign-in directly. No login secret is stored in the project. An updated Apple Developer Program agreement notice is visible; no agreement was accepted by this workflow.
- Signed Release archive `build/Archives/Minutide-0.1.0-1.xcarchive` succeeded. Both signature checks, privacy reason `CA92.1`, and all four bundled notices were verified. Receipt: `build/Verification/minutide-0.1.0-1.json`.
- Automatic export failed with Cloud Signing permission and missing-profile errors. Manual App Store export succeeded using the existing local distribution certificate and explicit App Store profiles; no new certificate or access grant was created. IPA: `build/Exports/Minutide-0.1.0-1-manual/Stiint.ipa`, 6,047,504 bytes, SHA-256 `0e960dc15940d35d5cb094178fd045ed1ce457e6d8d969def12a1f2551626327`. It is version `0.1.0` build `1`; `get-task-allow=false`, beta reports are active, and app/Live Activity bundle identifiers were verified.
- Validation and upload succeeded without errors. Apple processing is `VALID` for **0.1.0 (1)**, build/delivery `591b8c17-694a-41ce-80bd-39c16a27e4a6`; internal state is `IN_BETA_TESTING`. The build is assigned to `Minutide Internal`, whose sole intended tester is `INVITED`. The website independently shows this version/build, group, and one invitation. Expiry: 2027-02-09. Installation and email delivery are not claimed.
- Internal group `Minutide Internal` contains only the intended maintainer, marked `INVITED`, and build 0.1.0 (1). No public link is active; Mac and Vision availability are disabled.
- GitHub Actions is enabled and the iOS workflow is active. The older workflow-dispatch run was queued at last read; no check/run was created for PR #1 at the last API read. The cause is not established.
- No public App Store release has occurred. Apple’s legal agreement notice remains unaccepted. Follow [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) for the remaining gates.

## Self-build and signed archive

The project and scheme retain the internal name `Stiint`. The project minimum is iOS 26.1. `MINUTIDE_BUNDLE_ID_BASE` defaults to `com.elaren.minutide`; use a prefix registered to your own team if that identifier is unavailable. The project applies that base to the app, Live Activity extension, and test identifiers.

Simulator builds do not need a signing team. For a signed archive, set your own 10-character team ID in the local environment. The archive script uses `Release`, `generic/platform=iOS`, the `Stiint` scheme, and automatic signing. By default, DerivedData, the archive, and the log stay under `build/`. The script refuses to reuse an existing archive path and never deletes prior build products.

```sh
MINUTIDE_DEVELOPMENT_TEAM='YOUR_TEAM_ID' \
MINUTIDE_BUNDLE_ID_BASE='com.example.minutide' \
bash scripts/archive-ios.sh \
  --archive-path build/Archives/Minutide.xcarchive \
  --derived-data-path build/DerivedData \
  -- -allowProvisioningUpdates
```

Replace the placeholders with values from your own Apple team. `-allowProvisioningUpdates` lets Xcode contact Apple's developer services and create or update signing assets as needed. Only pass Apple authentication flags when you intend to authorize that account action; Xcode's flags and local key path are command arguments, so never put a private key's contents or credentials in the command, repository, or logs. You can pass additional `xcodebuild` arguments after `--`.

The archive script accepts `--archive-path` and `--derived-data-path`. Relative paths resolve from the repository root. It records Xcode output in `build/logs/archive-ios-*.log`. It does not change the version/build number, make a Git commit, export an IPA, upload a build, or submit an App Store release.

## Export an IPA for App Store Connect

Export an existing signed archive locally. The default export method is `app-store-connect` with destination `export`, so the script produces an IPA without uploading it. The default options set `manageAppVersionAndBuildNumber=false` so export preserves the reviewed version and build number. Export output defaults to `build/Exports/Minutide`; an existing output directory is never removed or overwritten.

```sh
MINUTIDE_DEVELOPMENT_TEAM='YOUR_TEAM_ID' \
bash scripts/export-ios.sh \
  --archive-path build/Archives/Minutide.xcarchive \
  --export-path build/Exports/Minutide
```

For a manually signed archive, supply your own Xcode export options plist:

```sh
MINUTIDE_DEVELOPMENT_TEAM='YOUR_TEAM_ID' \
bash scripts/export-ios.sh \
  --archive-path build/Archives/Minutide.xcarchive \
  --export-path build/Exports/Minutide \
  --export-options-plist /local/path/ExportOptions.plist
```

The custom plist must select `method=app-store-connect` and must not request `destination=upload`; a specified `teamID` must match `MINUTIDE_DEVELOPMENT_TEAM`. For manual signing, include the exact `provisioningProfiles` mapping required by the archive. Keep the plist and profiles local when they contain team-specific information. Xcode output is written to `build/logs/export-ios-*.log`.

Every custom export plist must also include `manageAppVersionAndBuildNumber` set to `false`; otherwise Xcode may change the version/build reviewed for the IPA. A generic manual-signing template is:

```xml
<key>destination</key><string>export</string>
<key>method</key><string>app-store-connect</string>
<key>manageAppVersionAndBuildNumber</key><false/>
<key>signingStyle</key><string>manual</string>
<key>teamID</key><string>YOUR_TEAM_ID</string>
<key>provisioningProfiles</key>
<dict>
  <key>com.elaren.minutide</key><string>YOUR_APP_PROFILE_NAME_OR_UUID</string>
  <key>com.elaren.minutide.liveactivity</key><string>YOUR_EXTENSION_PROFILE_NAME_OR_UUID</string>
</dict>
```

Insert those keys into a complete plist. Replace every placeholder using your own account's signing setup; never copy the actual team, certificate, or profile identifiers into repository docs.

Before upload, inspect the exported IPA and the export log, and verify that the archive has the intended version, build number, bundle identifiers, entitlements, and signing team. The scripts do not increment version/build values automatically. Apple must have the app record and bundle identifiers set up before the upload can be accepted.

## Validate and upload the explicit IPA

The upload script takes one IPA path and requires App Store Connect API credentials through local environment variables. `ASC_KEY_PATH` must resolve to an existing `.p8` private key outside the repository; the script checks the canonical path, including symlinks. It reads the key only through Apple's command-line tool and never copies, displays, or stores the key contents. The key ID and issuer ID are identifiers, not the private key; do not commit them either.

```sh
ASC_KEY_ID='YOUR_KEY_ID' \
ASC_ISSUER_ID='YOUR_ISSUER_ID' \
ASC_KEY_PATH='/local/secure/path/AuthKey.p8' \
bash scripts/upload-testflight.sh build/Exports/Minutide/Minutide.ipa
```

If Xcode chose another IPA filename, provide that exact path. The export script verifies that Xcode produced exactly one nonempty IPA in the output directory. The upload script first runs Apple's `altool --validate-app`, then uploads the same IPA with the same credentials using `altool --upload-package`. Its log is under `build/logs/upload-testflight-*.log`. Upload success means Apple's upload command accepted the package; it does not mean processing finished or testers can install it.

## Apple processing and internal availability — first beta history

Apple processing is `VALID` for **0.1.0 (1)**, build/delivery `591b8c17-694a-41ce-80bd-39c16a27e4a6`; internal state is `IN_BETA_TESTING`. The build is assigned to `Minutide Internal`, whose sole intended tester is `INVITED`. The website independently shows this version/build, group, and one invitation. Expiry: 2027-02-09. Installation and email delivery are not claimed. Use the invited build for physical acceptance of Shortcuts, location, restart, accessibility, upgrade, and minimum-runtime behavior.

The initial milestone is internal TestFlight for the maintainer. It does not include external testers, public App Store submission, a public download, paid features, or an automatic version/build-number change. The eventual public App Store release is intended to remain free and will require its own release review and evidence.

## Release checklist

- [x] Review the integrated manual-edit race guard and running-log query regression.
- [x] Run the expanded 39-test simulator suite (36 unit, 3 UI; 0 failures/skips) before the notice-only acknowledgement additions. Retest after those source additions if they change again.
- [x] Confirm candidate version/build and bundle identifiers from the signed archive and IPA.
- [x] Create and verify the signed archive, signatures, privacy reason, and four bundled notices; receipt is `build/Verification/minutide-0.1.0-1.json`.
- [x] Export and inspect the IPA; the reviewed artifact is `build/Exports/Minutide-0.1.0-1-manual/Stiint.ipa`.
- [x] Create and verify App Store Connect record 6833697250 for the registered app identifier.
- [x] Validate and upload the explicit IPA; Apple returned success without errors.
- [x] Processing, build/group assignment, internal state `IN_BETA_TESTING`, tester `INVITED`, and website invite count 1 are independently verified.
- [ ] Install the first TestFlight build and record physical Shortcuts, GPS, reboot/recovery, and minimum-runtime acceptance separately from processing and availability.
- [ ] Keep public App Store submission as a later release gate; no Apple legal agreement was accepted and no production release occurred.
