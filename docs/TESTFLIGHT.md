# Minutide self-build and internal TestFlight

Last reviewed: 2026-11-11 local time / 2026-11-12 UTC. This records the verified first internal beta and repeatable self-build procedures. Public App Store release remains a separate step.

## Current state

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

## Apple processing and internal availability

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
