# Minutide self-build and internal TestFlight

Last reviewed: 2026-11-11. These procedures prepare an internal TestFlight build; they do not announce a current build or submit a public App Store release.

## Current state

- The product goal is a fully free, open-source app that contributors can self-build from the public source, an eventual free App Store release, and an initial processed internal TestFlight build for the maintainer.
- The public source is available at [elaren-studio/minutide](https://github.com/elaren-studio/minutide). A Simulator self-build needs Xcode and the pinned Swift packages; it does not require Apple signing.
- Analytics, project settings, privacy, and Shortcuts changes are integrated on the current branch. The manual-edit location-metadata race guard and actual running-log query regression are integrated; all 10 relevant manual/location cases passed at runtime.
- The bundle-base override was read back for the app and Live Activity identifiers using `com.example.minutide` and `com.example.minutide.liveactivity`; the signing team remains blank in source and the current target family is iPhone-only.
- The expanded simulator suite passed **39 tests (36 unit, 3 UI), 0 failures, 0 skips**, at 23:38:59.771 UTC; `xcresulttool` independently confirmed `build/TestResults.xcresult`. This covers the stability changes before bundled-notice packaging additions. Physical-device acceptance follows internal TestFlight availability.
- The app and Live Activity identifiers are registered. [App Store Connect record 6833697250](https://appstoreconnect.apple.com/apps/6833697250) is verified as **Minutide: Time Tracker**, bundle `com.elaren.minutide`, SKU `minutide-ios`, language `en-US`. The bare Minutide name was unavailable; the installed app display name remains Minutide.
- The maintainer completed Apple sign-in directly. No login secret is stored in the project. An updated Apple Developer Program agreement notice is visible; no agreement was accepted by this workflow.
- No signed archive, IPA, upload, Apple processing result, or internal TestFlight availability has been verified. Follow [ACTIVE_CONTEXT.md](ACTIVE_CONTEXT.md) and [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) for live gates.

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

Export an existing signed archive locally. The default export method is `app-store-connect` with destination `export`, so the script produces an IPA without uploading it. Export output defaults to `build/Exports/Minutide`; an existing output directory is never removed or overwritten.

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

After upload, verify the selected app/build in App Store Connect. Wait for processing to finish, resolve any validation issue, then add the intended maintainer to the approved internal tester group and read back that the build is available to that tester. A successful script exit is not proof of processing, group membership, or installability. Use the first TestFlight install for physical acceptance of Shortcuts, location permission, reboot/recovery, and the supported minimum runtime; these remain untested in the current source snapshot.

The initial milestone is internal TestFlight for the maintainer. It does not include external testers, public App Store submission, a public download, paid features, or an automatic version/build-number change. The eventual public App Store release is intended to remain free and will require its own release review and evidence.

## Release checklist

- [ ] Review the integrated manual-edit race guard and running-log query regression.
- [ ] Rerun the full expanded simulator suite after numeric optional-value assertion fixes, and complete targeted simulator checks in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md).
- [ ] Confirm the app version/build and bundle identifier settings on the exact candidate revision.
- [ ] Create and inspect a signed archive; retain the Xcode log under `build/logs/`.
- [ ] Export and inspect the IPA; retain the export log under `build/logs/`.
- [ ] Complete Apple website/account setup and create the App Store Connect app record for the registered app and Live Activity identifiers before upload.
- [ ] Validate and upload that explicit IPA; retain the upload log under `build/logs/`.
- [ ] Read back Apple processing status and internal tester availability in App Store Connect.
- [ ] Install the first TestFlight build and record physical Shortcuts, GPS, reboot/recovery, and minimum-runtime acceptance separately from processing and availability.
