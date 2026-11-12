# Organizations, clients, projects, and tasks

Implementation specification for the next internal beta, authorized 2026-11-11.
This document describes the intended behavior; `ACTIVE_CONTEXT.md` records what
has actually been implemented and verified.

## A single location for each task

Organizations contain clients; clients contain projects. Only tasks are timers.
A task's Location is one of Unassigned, an organization, a client, or a project.
Selecting a project derives its client and organization automatically. Selecting
a client derives its organization. No redundant ancestor selectors are required.
Tasks can remain completely unassigned.

The Tasks screen has an All Work / Unassigned / organization switcher and a
Manage Work entry point. Organization scope filters the task list and sets the
default location for a new task. It does not start, stop, or switch a timer.
The one global running timer remains visible, including when it is outside the
selected scope. Starting another task switches the timer through the existing
serialized timer path. The app-wide timer accessory remains available.

Manage Work supports adding, editing, archiving, and restoring each level.
Clients require an organization and projects require a client. Tasks can move
between locations. Archived parents hide descendants from new timer selection
and assignment; their history remains reportable. An already-running timer
remains recoverable and stoppable. Names are required after trimming; duplicate
names in different locations are allowed and shown with breadcrumbs.

## Appearance

Every level can customize its color and SF Symbol independently. An unset
property inherits from the nearest ancestor with that property, then falls back
to the app default. Choosing a custom icon does not force a custom color.
Existing tasks retain their saved appearance. Editors show the effective
appearance in Color and Icon rows that open visual choosers, with a
default/parent reset in each chooser. Independent inheritance is unchanged.

## Manual tracking and contextual task creation

My Day offers Start Timer, with Stop and Switch Task when a timer is running.
Choose an available task or create one without leaving the chooser. Tracking
starts at the current time and brings My Day back to Today. A local scope menu
and search help find work; changing that chooser's scope leaves the timeline's
scope alone. Saving a new task returns to the chooser; tapping the task starts it.

Create Log offers New Task alongside its task picker. Saving creates and selects
that task while preserving the draft log dates; canceling leaves the draft alone.
The new task may be assigned anywhere, including outside the current scope.
Neither inline flow interrupts task creation with the Shortcuts automation prompt.

## History and migration

Preserve the existing `ActivityItem` UUIDs, entity names, relationships, original
`deleted` field mapping, default store location, and all existing records.
New parent references use scalar IDs validated by the hierarchy mutation actor.
No account, team membership, server, or cloud synchronization is added.

Each new time entry captures its task and resolved organization/client/project
IDs, names, and effective appearance. Moving or renaming a task does not rewrite
earlier time. Editing dates or splitting a log preserves its snapshot. Explicit
log reassignment captures the new task's current location; the log editor also
offers an explicit option to use the same task's current assignment.

Legacy entries receive task metadata but no organizational ancestry. A task's
new location cannot establish where old work happened. Backfill is synchronous,
transactional, and idempotent, before actors or UI can use the upgraded store.
Schema migration must be proved against a disk store created with the released
unversioned schema, including archived, orphan, malformed, and running records.
Opening, migration, or backfill failure must never cause a destructive reset.

V1 is frozen in `WorkStore.swift`; V2 describes this beta's current models.
Before a later stored-model change, freeze the shipped V2 definitions and add
an ordered migration stage. Do not change the historical schemas to make a new
model fit. Extend the disk migration fixtures to cover each shipped version.

## Reports

Reports filter by dates, organizations, clients, projects, and tasks. Multiple
selected values at one level are ORed; different levels are ANDed. All includes
missing values, Unassigned matches missing values at that level, and an empty
explicit selection matches nothing. Conflicting filters produce zero results.
Historical entries use their captured assignment, including archived entities.

Grouping by organization, client, project, task, or calendar day rolls matching
time into the selected buckets. Missing levels have explicit buckets; a direct
organization task is not omitted from client/project grouping. Sorting supports
name and tracked time. Group totals sum to the same flat matching total; subtotal
rows and synthetic free time must not inflate it. Group identity uses captured
IDs. When an ID has several captured names/styles, choose the latest metadata
deterministically; detailed entries retain their own captured labels.

Capture one clock value and calendar per report load. Clip valid intervals to
the half-open date window, including a running timer only up to that clock.
Split day groups at local calendar midnights, including daylight saving changes.
Custom date selection includes the selected end date through its next midnight.
Outdated asynchronous loads cannot replace a newer filter result.

All five existing charts remain free and respect the combined filter. Summary
and detailed CSV exports are user initiated. Raw CSV retains its first eight
columns and all supplied rows, including incomplete or orphan records, and adds
captured hierarchy metadata. Report exports distinguish original durations from
clipped report durations. Exports may contain names, times, and optional precise
coordinates; the user selects the destination.

## Acceptance gates

- Disk migration and reopen preserve all existing identities, relationships,
  dates, coordinates, archive flags, and the running timer.
- Hierarchy validation rejects invalid or archived parents; independent style
  inheritance and task moves behave consistently.
- Snapshot capture, edits, splits, explicit reclassification, and archived history
  are covered by meaningful storage tests.
- Report tests cover AND/OR, empty and missing dimensions, grouping conservation,
  fixed-clock running logs, DST, stable metadata/sorting, and CSV escaping.
- Simulator checks cover creation, scope switching while running, appearance,
  combined reports, exports, and the existing free charts.
- Commit and push reviewed source/docs during development. Validate and sign the
  exact release candidate, upload the next build to the existing internal group,
  and verify processing and internal availability separately. Production App
  Store submission and external testers remain outside this authorization.
