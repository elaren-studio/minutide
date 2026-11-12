# Decisions

Durable choices for Minutide, the independent Stiint continuation. Add a dated entry when a decision changes; keep implementation status in `ACTIVE_CONTEXT.md` and `WORKLOG.md`.

## 2026-11-11 — Manual tracking and contextual task creation

- My Day offers a visible Start Timer action, plus Switch Task and Stop while
  tracking. Starting always records the current time and returns to Today;
  Create Log remains the separate action for past time.
- Create Log and the manual timer chooser can create tasks in place. Saving
  returns to the originating flow without an automation prompt. A new task is
  selected in Create Log; the timer chooser requires an explicit task tap to
  start. Canceling task creation leaves the original log dates and task intact.
- Appearance uses labeled Color and Icon rows with visual choosers and an
  independent default/parent reset for each property. Preserve inheritance and
  saved history; no store schema change is needed.
- Use the system toolbar surface for work scope; do not nest a material capsule
  inside the native toolbar's glass background.

## 2026-11-11 — Local work hierarchy and immutable entry assignment

- Organizations contain clients, and clients contain projects. Only tasks are
  startable timers. A task chooses one optional parent (organization, client,
  project, or none); derive ancestors rather than store conflicting selections.
- Organization switching scopes work; it leaves the one global timer running.
  These are local work contexts, without accounts, teammates, or cloud sync.
- Color and icon inherit independently from the nearest configured ancestor.
  Preserve existing task styles and identities.
- Capture hierarchy IDs, names, and effective appearance on each new entry.
  Task edits affect future entries. Date-only edits and splits preserve history;
  explicit entry reclassification is user initiated. Legacy entries receive no
  invented historical organization/client/project assignment.
- Report filters use OR within a dimension and AND across dimensions. Group
  matching time without double counting, retain missing-level buckets, and keep
  synthetic free time outside tracked totals. See `WORK_HIERARCHY.md`.
- The user authorized tests/docs, remote commits during development, and the
  next internal TestFlight build for the existing maintainer group. External
  testers, public App Store submission, and new legal agreements remain separate.

## 2026-11-11 — Independent community fork (initial name and identifiers)

- Initial working product name: **Stiint Community**. This name and the identifiers below were superseded by the later Minutide decision.
- Keep the Xcode app target name `Stiint` for internal project continuity.
- At that time, project bundle identifiers were `com.fdtorres.stiintcommunity`, `com.fdtorres.stiintcommunity.liveactivity`, `com.fdtorres.stiintcommunity.tests`, and `com.fdtorres.stiintcommunity.uitests`.
- The fork is independent and must not imply affiliation with or endorsement by Liam Wittig.
- Upstream provenance is `Liam1506/Stiint` at commit `a6f10f2d6637e9b3b330c56b818fb537357329b0`. The upstream archive reason is unknown.

## 2026-11-11 — Free and open source

- Keep the community app fully free, with no subscription, paywall, or paid-only feature gate.
- Preserve the original MIT license and Liam Wittig's copyright notice exactly in `LICENSE`.
- Keep third-party license notices separate and tied to the exact pins in `Package.resolved`.

## 2026-11-11 — Self-builds and free distribution

- Keep all Minutide app features free and the source available for contributors to self-build. The eventual public App Store listing is intended to be free of charge.
- Prioritize a first processed internal TestFlight build for the maintainer's physical-device acceptance. Simulator stability and signed-artifact checks precede upload; physical acceptance is completed on TestFlight and gates a stable public release.
- Keep source publication, self-builds, Apple signing, TestFlight processing/internal access, and public App Store submission as separate evidence states. This internal beta goal does not authorize external testers or a public App Store submission.

## 2026-11-11 — User data stays local by design

- Store activity data in the on-device SwiftData store; do not add an account or server-sync service.
- Bundle the exact pinned AcknowList and Sankey license text and pass those local resources to the acknowledgements screen. This removes the need for AcknowList to fetch those missing notices from GitHub; it is not a full network traffic audit.
- Location collection remains optional per activity. If enabled, the data model can hold precise start/end coordinates.
- Make CSV export user initiated and explain that it can include location coordinates. A user-selected share or export destination can move that file outside the app.
- Revisit this decision before adding analytics, remote services, cloud sync, or additional sensitive data collection.

## 2026-11-11 — Release evidence is explicit

- A source change, local compile, passing tests, Simulator run, physical-device acceptance, CI result, and published release are separate states.
- Do not describe the fork as released or available in the App Store until that exact external release is verified.
- At the time of this entry, the community repository was not yet verified and no `origin` remote existed. The later Minutide decision below records the verified public repository and remotes.

## 2026-11-11 — Preserve archived activity history

- The activity model's `deleted` field is renamed to `archived` in Swift code while retaining `@Attribute(originalName: "deleted")` so SwiftData can map the existing stored field. Keep old activities and their logs; archive an activity instead of deleting its history.

## 2026-11-11 — Minutide and Elaren Studio

- The user chose **Minutide** and explicitly authorized renaming the app and putting it under the Elaren GitHub organization. This supersedes the earlier Stiint Community public name and `fdtorres1/stiint-community` proposal.
- Verified organization: `elaren-studio` (GitHub ID 308134048). Authenticated user `fdtorres1` has active admin membership. The authorized source destination is public repository `elaren-studio/minutide`, preserving upstream history as a GitHub fork.
- Use **Minutide** for the app display name and **Minutide Live Activity** for the extension display name. Use `com.elaren.minutide`, `.liveactivity`, `.tests`, and `.uitests` for source bundle identifiers. These settings do not claim Apple identifier registration or distribution readiness.
- Keep the internal Xcode project, target, module, folders, and scheme names to minimize unrelated churn. Keep Liam Wittig's attribution and original MIT notice intact.
- Changing the bundle identifier creates a separate app container from prior local Stiint Community installs; no automatic cross-container data migration is implemented or claimed. The community build has not been publicly distributed.
- The bounded name screen in `NAME_RESEARCH_MINUTIDE.md` is evidence for choosing the name, not comprehensive trademark clearance. Domain registration, App Store name reservation, signed builds, TestFlight, and App Store submission are separate actions.

## 2026-11-11 — Initial store-record title

- App Store Connect rejected the bare Minutide name as already in use. Use **Minutide: Time Tracker** for the initial store record, verified as app 6833697250 with `com.elaren.minutide`; keep Minutide as the installed display name.
- This descriptive title can be reviewed before public release. It does not establish trademark clearance or an App Store release. The app record uses Limited Access; existing account-holder access remains.

## 2026-11-11 — Repository reporting route

- Use GitHub private vulnerability reporting for Minutide. It was enabled and verified on the public Elaren repository; no personal email address or response-time promise is established.

## 2026-11-11 — Project-local SSD development paths

- On Felix's workstation, use `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide` as the canonical checkout while the external APFS volume is mounted.
- Keep Xcode's GUI DerivedData project-relative using the local ignored workspace settings file. The verified values are `DerivedDataLocationStyle=WorkspaceRelativePath` and `DerivedDataCustomLocation=build/DerivedData`, with `BuildLocationStyle=UseAppPreferences` and `CustomBuildLocationType=RelativeToDerivedData`. Do not change global Xcode preferences.
- GUI build/intermediate outputs, module caches, and Swift package checkouts resolve beneath the repository's `build/DerivedData`; `CACHE_ROOT` remains system-managed under `/var/folders/...`.
- `scripts/ci-ios.sh` independently supplies `-derivedDataPath build/DerivedData`. GUI and CLI use that repository-local root with different build subfolder layouts. Keep optional archives under `build/Archives` only when a separate archive is authorized.
- Retain pre-SSD migration evidence under `build/history/pre-ssd/`. The old DerivedData snapshot is historical; do not use it as the active cache. The user subsequently explicitly approved deleting the verified internal copies. Their guarded removal is complete; keep the SSD Git backup and archived validation artifacts.
