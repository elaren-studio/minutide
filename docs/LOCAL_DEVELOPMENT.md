# Local Development and Build Storage

On Felix's workstation, the canonical checkout is `/Volumes/Felix-SSD-1/Cursor Projects/Elaren/products/minutide`, on the external APFS volume. This path is host-specific; use the repository root for the commands below. Confirm the volume is mounted before opening the project.

## Xcode GUI DerivedData

The GUI uses project-relative DerivedData without changing global Xcode preferences. Xcode's local, ignored workspace settings are at:

`Stiint.xcodeproj/project.xcworkspace/xcuserdata/<macOS-user>.xcuserdatad/WorkspaceSettings.xcsettings`

The active setting values are:

```text
BuildLocationStyle = UseAppPreferences
CustomBuildLocationType = RelativeToDerivedData
DerivedDataLocationStyle = WorkspaceRelativePath
DerivedDataCustomLocation = build/DerivedData
```

`xcodebuild -showBuildSettings -project Stiint.xcodeproj -scheme Stiint` resolved the GUI build and intermediate roots beneath `build/DerivedData/Stiint/Build`. `MODULE_CACHE_DIR` and `COMPILATION_CACHE_CAS_PATH` also resolve under `build/DerivedData`. GUI package checkouts are under `build/DerivedData/Stiint/SourcePackages/checkouts`; CLI package checkouts are under `build/DerivedData/SourcePackages/checkouts`.

XcodeBuildMCP's local ignored configuration is `.xcodebuildmcp/config.yaml`; it points to this SSD project and `build/DerivedData`. It does not change global Xcode preferences.

This does not move every Xcode or macOS cache. `CACHE_ROOT` remains in the system-managed `/var/folders/...` area. Do not describe that system cache as SSD-local.

## Command-line builds

The CI script independently passes `-derivedDataPath build/DerivedData`, so its products and intermediates are rooted at `build/DerivedData/Build`; this subfolder layout differs from the GUI's `build/DerivedData/Stiint/Build` while staying on the same SSD and inside the repository.

The fresh SSD CI run on 2026-11-11 completed successfully: 20 tests passed (17 unit, 3 UI), 0 failed, 0 skipped, on iPhone 17 / iOS 26.5. The result bundle is `build/TestResults.xcresult`; the log is `build/minutide-ssd-ci.log`.

Run the CI-equivalent simulator build and tests from the repository root:

```sh
bash scripts/ci-ios.sh
```

On this Mac, Xcode's separate build service previously stalled while reading compiler output. The successful fresh SSD run used this per-command workaround, which does not change project, workflow, or global Xcode settings:

```sh
env SWIFTBUILD_LAUNCH_IN_PROCESS=1 bash scripts/ci-ios.sh
```

The script writes build output beneath `build/DerivedData` and test results to `build/TestResults.xcresult`. Inspect the effective GUI paths without starting a build with:

```sh
xcodebuild -showBuildSettings -project Stiint.xcodeproj -scheme Stiint
```

An archive is separate from routine simulator work. The authorized initial internal TestFlight objective is not evidence that an archive or signed distribution exists. When the stability and Apple-account gates are ready, use the self-contained [TestFlight scripts](TESTFLIGHT.md); default archives, exports, and logs stay under `build/`.

## Migration evidence

The pre-SSD internal source, shared Git directory, and preview copies were removed after the user explicitly approved deletion and the guarded retention audit passed again. All active development and new builds use the SSD. The migration receipt is `build/history/pre-ssd/migration-verification.json`; `internal-retirement.json` in the same folder records the completed cleanup. The portable Git bundle and archived preview artifacts remain under `build/history/pre-ssd/`. The old DerivedData snapshot is archived at `build/history/pre-ssd/DerivedData`; it is historical evidence, not the active cache. A regenerable compiler CAS was excluded from the source copy and is recreated by fresh builds.
