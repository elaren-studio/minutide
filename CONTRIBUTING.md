# Contributing

Thanks for helping maintain Minutide at [elaren-studio/minutide](https://github.com/elaren-studio/minutide). The goal is a dependable, free iOS time tracker with understandable behavior and user-controlled data.

## Before changing code

- Check the current [roadmap](docs/ROADMAP.md), [decisions](docs/DECISIONS.md), and [active context](docs/ACTIVE_CONTEXT.md).
- For a larger change, open or find an issue first so the scope and expected behavior are clear.
- Keep changes focused. Avoid unrelated formatting and generated-file churn.
- Do not include personal activity histories, real locations, credentials, signing material, or private provisioning files in issues, pull requests, screenshots, or test fixtures.
- If a change alters what data is collected, where it is stored, or how it leaves the device, explain that in the proposal and update the privacy notes.

## Build and test

Use Xcode with an iOS 26.1 SDK or newer. Open `Stiint.xcodeproj`, select the `Stiint` scheme and an iOS Simulator, then use **Product → Test**. No signing team is needed for Simulator builds.

The project and scheme retain their upstream internal names. The public app name is Minutide; bundle identifiers use the `com.elaren.minutide` prefix. For personal signed builds, choose identifiers available to your own team consistently across the app, extension, and tests.

For command-line checks, use `xcodebuild -showdestinations` to select a simulator available on your Mac, then run:

```sh
xcodebuild -resolvePackageDependencies -project Stiint.xcodeproj
xcodebuild test -project Stiint.xcodeproj -scheme Stiint \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' CODE_SIGNING_ALLOWED=NO
```

Replace `SIMULATOR_ID` with an identifier from `-showdestinations`. The CI-equivalent command selects an available iPhone simulator on iOS 26.1 or later and runs the test suite:

```sh
bash scripts/ci-ios.sh
```

If you cannot run a check, say what you did run and include the relevant error without personal data. Do not describe a test as passing unless it ran successfully on the proposed revision. Physical-device behavior is tracked separately in [Device Acceptance](docs/DEVICE_ACCEPTANCE.md).

## Data and persistence changes

Activity logs can contain precise location coordinates. Treat names, timestamps, coordinates, and exported CSV files as sensitive. Keep tests synthetic and local. Changes to SwiftData models should include a migration or compatibility plan where needed and tests for both new records and existing records. Do not silently change the fields or destination of CSV export.

Shortcuts actions and timer recovery are user-facing behavior. When changing them, describe the trigger, expected state transition, and how you checked pause, weekday, interruption, and relaunch cases that apply.

## Pull requests

Use the repository pull request template. Include:

- the user-visible behavior changed and why;
- the files or targets affected;
- the build/test command and result, or the reason it could not be run;
- manual device checks performed and the device/iOS version;
- any privacy, migration, localization, accessibility, or license impact.

Keep screenshots free of personal activity data. Do not publish builds, submit to the App Store, change signing ownership, or push to a remote until the target repository and authorization have been explicitly established.

## Licensing

The original Stiint source remains MIT-licensed with Liam Wittig's copyright notice intact. Contributions to the app source are intended to remain MIT-licensed under the repository's existing license. Dependencies have their own terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and keep those notices aligned with the package pins.
