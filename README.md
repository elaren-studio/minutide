# Minutide

Minutide is a free, open-source iPhone time tracker maintained by [Elaren Studio](https://github.com/elaren-studio), continued from Liam Wittig's archived Stiint project. Track tasks across organizations, clients, and projects, keep unassigned work, use iOS Shortcuts and Live Activities, and combine time in reports.

This is an early beta with public source for development and self-building. Internal TestFlight availability is recorded below; a public App Store release is a later milestone. The fork is independent and is not affiliated with or endorsed by the original author.

## What it does

- Organize tasks under organizations, clients, and projects, or leave them unassigned.
- Give each level its own color and icon, or inherit each property independently.
- Switch organization scope while one global timer keeps running.
- Create named tasks with optional weekday rules and location recording.
- Start, stop, query, and resume activities from the app or Shortcuts actions.
- Review and edit logged activity on a daily timeline.
- Combine organization, client, project, and task filters; group and sort matching time.
- Explore free Sankey, pie, bar, line, and area charts using the matching records.
- Show the current activity in an iOS Live Activity.
- Export grouped summaries, report details, or complete raw logs as CSV.
- Optionally record start and end location for selected activities.
- Use all app features without a subscription or paid tier.

The project uses SwiftUI, SwiftData, App Intents, and Swift Package Manager. The current app deployment target is iOS 26.1. Check the Xcode project settings if you work from a later revision.

## Organize and report on work

Open **Tasks → Manage Work** to add an organization, then clients inside it and
projects inside a client. A task has one **Location** picker: Unassigned, an
organization, a client, or a project. Selecting a project fills in its ancestors.
Tap **Color** or **Icon** to choose a style, or use the default/parent style.
Each can follow its parent independently; existing task appearance is kept.

Use the organization menu to switch between All Work, Unassigned, and an
organization. The running timer stays available while you switch scope, and
choosing another task switches the timer. Archive and restore items from Manage
Work; archived work remains in history.

In **My Day**, tap **Start Timer** and choose a task, or create one there.
Tracking starts now and returns to Today even when you were viewing an older
day. Use **Switch Task** or **Stop** on the running timer. To add past time,
tap **+** for **Create Log**; **New Task** creates and selects a task without
leaving your log or changing its dates.

In **Reports**, select dates and combine work filters. Selecting two clients
includes either client; adding a project filter narrows that set further.
Choose a grouping and sort order to combine matching time, then export a summary
or detailed CSV. Missing client/project levels keep their own buckets so direct
organization work is included.

Moving or renaming a task affects new time entries. Earlier entries keep their
recorded location and appearance. To reclassify an older entry, edit its task or
enable **Use task’s current assignment** in its log editor. Entries from the
first beta retain their task but start without an organization, client, or
project; the upgrade never guesses a past assignment. Install updates without
deleting the app to preserve its local store.

## Screenshot

![Live Activity on the iPhone lock screen during the community revival](docs/images/community-lock-screen.jpg)

This screenshot predates the Minutide rename. The original Stiint screenshots used in the Shortcuts setup guide also retain their original branding.

## Build and run in the iOS Simulator

You need Xcode with an iOS 26.1 SDK or newer. No Apple signing account is needed to build and run in the Simulator.

1. Open `Stiint.xcodeproj` in Xcode.
2. Allow Xcode to resolve the Swift packages listed in `Package.resolved`.
3. Select the `Stiint` scheme and an iOS Simulator destination.
4. Choose **Product → Run**.

The internal project, target, and scheme retain the name `Stiint` for source continuity. The installed app is **Minutide**, with bundle identifier `com.elaren.minutide` and Live Activity extension identifier `com.elaren.minutide.liveactivity`. The repository is [elaren-studio/minutide](https://github.com/elaren-studio/minutide). No signing team or Apple identifier registration is included in the source publication.

For a terminal build, first list available simulator destinations and then choose one by its identifier:

```sh
xcodebuild -resolvePackageDependencies -project Stiint.xcodeproj
xcodebuild -showdestinations -project Stiint.xcodeproj -scheme Stiint
xcodebuild build -project Stiint.xcodeproj -scheme Stiint \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

To run the test scheme on a simulator, replace `SIMULATOR_ID` with an identifier printed by `-showdestinations`:

```sh
xcodebuild test -project Stiint.xcodeproj -scheme Stiint \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' CODE_SIGNING_ALLOWED=NO
```

The same dynamic simulator selection and test command used by CI is available locally:

```sh
bash scripts/ci-ios.sh
```

For the canonical SSD checkout, project-local Xcode GUI DerivedData, and the difference between GUI and CLI build subfolders, see [Local Development](docs/LOCAL_DEVELOPMENT.md).

All features remain free and open source. The maintainer confirms that **0.1.0 (1)** installs and launches on his iPhone. The **0.2.0 (2)** hierarchy/reporting update is processed and available in the existing internal TestFlight group. Update without deleting the app to preserve its local store. Hosted CI passed all 70 tests for this build. Physical feature/upgrade acceptance and a free public App Store release remain later steps. See [TestFlight build and upload](docs/TESTFLIGHT.md) for verified status and repeatable self-build commands. Signing details stay local; the scripts never submit a public App Store release.

These are contributor instructions, not a claim that the current revision's final test run or hosted CI has passed. See [Device Acceptance](docs/DEVICE_ACCEPTANCE.md) for the manual checks and their current evidence.

### Install on your own iPhone

Physical-device installation requires signing with an Apple Developer team you control. In Xcode, choose your own Team under **Signing & Capabilities** for both the app and Live Activity targets. At the project level, set the user-defined build setting `MINUTIDE_BUNDLE_ID_BASE` to a unique identifier registered to your team, such as `com.example.minutide`; the extension and test identifiers follow automatically. Simulator use does not require signing. For a signed archive, follow [TestFlight build and upload](docs/TESTFLIGHT.md). Do not use another person's signing credentials or provisioning profile.

Keep personal provisioning profiles and signing keys out of the repository; they remain local to your signing team.

## Privacy and data

Task and work hierarchy names, appearance, and time entries are stored in the
app's on-device SwiftData store. Each entry captures its assignment so later
task changes preserve historical reports. Location is optional per task; when
enabled, the app can save precise start/end latitude and longitude. CSV exports
can include names, hierarchy IDs, timestamps, duration, appearance, and saved
coordinates. Treat exported files as sensitive and choose their destination
deliberately. Organizations are local work contexts; they do not add team
accounts or shared access.

The app stores records in an on-device SwiftData store with CloudKit disabled and has no project account or server-sync service. The acknowledgements screen loads the pinned dependency licenses bundled with the app; it does not need to fetch those notices from GitHub. App network traffic has not been independently audited. Shortcuts, iOS Location Services, and system share/export flows are controlled by Apple and by the choices you make on your device. This description summarizes the app source; it is not an independent privacy or security audit. See [SECURITY.md](SECURITY.md) for reporting guidance.

## Contributing and project status

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a change. The current priorities and unfinished validation gates are in [docs/ROADMAP.md](docs/ROADMAP.md), with live handoff status in [docs/ACTIVE_CONTEXT.md](docs/ACTIVE_CONTEXT.md).

## Origin and license

This fork continues [Liam1506/Stiint](https://github.com/Liam1506/Stiint), based on upstream commit `a6f10f2d6637e9b3b330c56b818fb537357329b0`. The original app source remains under the MIT License; the copyright notice for Liam Wittig is preserved in [LICENSE](LICENSE). Third-party package details and bundled license resources are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
