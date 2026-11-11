# Repository working instructions

## Source of truth

- Confirm the repository root, branch, remote URLs, and dirty files before substantial work. Preserve other workers' and contributors' changes.
- On Felix's workstation, the canonical checkout is `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide`. The external volume must be mounted before working there. See `docs/LOCAL_DEVELOPMENT.md` for the project-local Xcode workspace settings and build paths; do not change global Xcode preferences for this project.
- Read `docs/ACTIVE_CONTEXT.md`, `docs/ROADMAP.md`, and relevant entries in `docs/DECISIONS.md` before implementation. Keep `ACTIVE_CONTEXT` current after a substantial handoff and append outcomes to `WORKLOG`; do not rewrite old worklog entries.
- Inspect the project settings, `Package.resolved`, and relevant source before describing behavior. Mark plans, source observations, build results, simulator checks, physical-device checks, and releases as distinct evidence states.
- The project is an Xcode iOS app using SwiftUI, SwiftData, App Intents, and pinned Swift Package Manager dependencies. Use the `Stiint` scheme and an iOS Simulator for routine checks. Consult `CONTRIBUTING.md` for the documented commands.

## Scope and safety

- The independent fork is named **Minutide**, maintained under GitHub organization `elaren-studio`; the authorized public repository is `elaren-studio/minutide`. The internal Xcode app target remains **Stiint**. Current project bundle identifiers are `com.elaren.minutide`, `com.elaren.minutide.liveactivity`, `com.elaren.minutide.tests`, and `com.elaren.minutide.uitests`; verify the live settings before signing a release.
- The verified `upstream` remote points to `Liam1506/Stiint`; `origin` points to `https://github.com/elaren-studio/minutide.git`. Verify every remote before pushing; never assume `upstream` is the community fork.
- Preserve the original MIT notice, exactly as it appears in `LICENSE`, including Liam Wittig's copyright. Keep upstream attribution clear and do not imply endorsement or affiliation.
- The fork's product direction is fully free and open source. Do not restore subscriptions, paid feature gates, tracking SDKs, or account/server sync without an explicit decision recorded in `docs/DECISIONS.md`.
- Treat activity names, timestamps, location coordinates, exports, credentials, and signing material as sensitive. Use synthetic test data and do not commit personal records or secrets.
- Do not claim a build, test, physical acceptance, CI run, App Store release, or public repository publication without current evidence for that exact state.
- Do not commit, push, sign a release, publish, or submit an App Store build as an incidental implementation step. These actions require their own explicit authorization and target check.

## Documentation discipline

- Keep durable product choices in `docs/DECISIONS.md`, planned work in `docs/ROADMAP.md`, current state and gates in `docs/ACTIVE_CONTEXT.md`, and dated implementation evidence in append-only `docs/WORKLOG.md`.
- Update user-facing setup and privacy instructions when behavior changes. `THIRD_PARTY_NOTICES.md` must identify exact resolved package versions and license evidence; do not guess missing copyright lines.
- Use the issue and pull request templates. Avoid screenshots and logs that expose a person's routine or coordinates.
