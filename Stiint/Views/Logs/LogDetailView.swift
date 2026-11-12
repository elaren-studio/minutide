import MapKit
import SwiftData
import SwiftUI

struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pauseTracking") private var pauseTracking = false
    @Bindable var log: ActivityLog
    @Query private var activities: [ActivityItem]
    @Query private var organizations: [WorkOrganization]
    @Query private var clients: [WorkClient]
    @Query private var projects: [WorkProject]
    @State private var showDeleteConfirmation = false
    @State private var saveError: String?
    @State private var saving = false
    @State private var resuming = false
    @State private var showResumeConfirmation = false
    @State private var errorTitle = "Unable to save log"
    @State private var refreshAssignment = false
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var activity: ActivityItem?

    init(log: ActivityLog) {
        self.log = log
        _activity = State(initialValue: log.activity)
        let now = Date.now
        _startTime = State(initialValue: Self.validDate(log.startTime) ?? now)
        _endTime = State(initialValue: Self.validDate(log.endTime) ?? now)
    }

    private static func validDate(_ date: Date?) -> Date? {
        guard let date, date.timeIntervalSinceReferenceDate.isFinite else { return nil }
        return date
    }

    private var hasCompleteClosedDates: Bool {
        Self.validDate(log.startTime) != nil && Self.validDate(log.endTime) != nil
    }

    private var canSave: Bool {
        guard hasCompleteClosedDates, log.id != nil, !busy,
              activity != nil || log.activity == nil else { return false }
        let latestEnd = DtoManager.shared.activityDTO?.startTime ?? Date.now
        return endTime > startTime && endTime <= latestEnd
    }

    private var busy: Bool { saving || resuming }

    private var hasUnsavedChanges: Bool {
        startTime != log.startTime || endTime != log.endTime
            || activity?.persistentModelID != log.activity?.persistentModelID || refreshAssignment
    }

    private var canResume: Bool {
        guard hasCompleteClosedDates, log.id != nil, !busy, !pauseTracking,
              !hasUnsavedChanges, let task = log.activity else { return false }
        return WorkHierarchy.isAvailable(task: task, in: modelContext)
    }

    private var resumeExplanation: String {
        if pauseTracking { return "Resume tracking in Settings before starting a timer." }
        if hasUnsavedChanges { return "Save your changes with Done before resuming." }
        if let task = log.activity, WorkHierarchy.isAvailable(task: task, in: modelContext) {
            return "Start a new entry now with this recorded task, assignment, color, and icon. This entry stays unchanged."
        }
        return "This task is archived or unavailable. Restore it, or select an active task and save with Done."
    }

    private var selectableActivities: [ActivityItem] {
        _ = organizations.count + clients.count + projects.count
        return activities.filter {
            $0.persistentModelID == log.activity?.persistentModelID
                || WorkHierarchy.isAvailable(task: $0, in: modelContext)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if hasCompleteClosedDates {
                    Section {
                        Button {
                            if DtoManager.shared.activityDTO != nil {
                                showResumeConfirmation = true
                            } else {
                                resume()
                            }
                        } label: {
                            Label(resuming ? "Resuming…" : "Resume Timer", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .disabled(!canResume)
                        .accessibilityIdentifier("log.resume")
                    } footer: {
                        Text(resumeExplanation)
                    }
                }
                Section("Task") {
                    Picker("Task", selection: $activity) {
                        Text("Choose a task").tag(Optional<ActivityItem>.none)
                        ForEach(selectableActivities) { item in
                            Text(taskLabel(item)).tag(Optional(item))
                        }
                    }
                    .disabled(!hasCompleteClosedDates || busy)
                    if log.activity == nil {
                        Text("This log's activity is unavailable. You can keep its missing assignment or choose an existing activity. The saved log is preserved until you tap Done.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Recorded assignment") {
                    let snapshot = log.workSnapshot
                    LabeledContent("Task", value: snapshot.task?.name ?? "Unavailable task")
                    LabeledContent("Organization", value: snapshot.organization?.name ?? "Unassigned")
                    LabeledContent("Client", value: snapshot.client?.name ?? "No client")
                    LabeledContent("Project", value: snapshot.project?.name ?? "No project")
                    if hasCompleteClosedDates, activity?.id != nil {
                        Toggle("Use task’s current assignment", isOn: $refreshAssignment)
                            .accessibilityIdentifier("log.refreshAssignment")
                            .disabled(busy)
                        Text("Date changes keep the recorded assignment. Changing the task, or enabling this option, captures its current location and appearance when you save.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Time") {
                    if hasCompleteClosedDates {
                        // Validate the pair below instead of constructing a
                        // potentially reversed DatePicker range from saved data.
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        if endTime <= startTime {
                            Text("End time must be after start time.").foregroundStyle(.red)
                        } else if endTime > (DtoManager.shared.activityDTO?.startTime ?? Date.now) {
                            Text("End time must be before the current timer starts, or before now when no timer is running.")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Text(log.endTime == nil
                            ? "Stop this activity before editing its log."
                            : "This log has incomplete or invalid dates. It is preserved and can still be exported.")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(busy)

                if hasCompleteClosedDates, endTime >= startTime {
                    Section("Duration") {
                        Text(Duration.seconds(endTime.timeIntervalSince(startTime)),
                             format: .units(allowed: [.hours, .minutes, .seconds]))
                            .accessibilityIdentifier("log.detail.duration")
                    }
                }

                if let startLatitude = log.startLatitude, let startLongitude = log.startLongitude,
                   let endLatitude = log.endLatitude, let endLongitude = log.endLongitude,
                   CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)),
                   CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)) {
                    let start = CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
                    let end = CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
                    Section("Location") {
                        Text(LocationHandler().formatDistance(startLat: startLatitude, startLon: startLongitude,
                                                              endLat: endLatitude, endLon: endLongitude))
                    }
                    Map {
                        Marker("Start location", coordinate: start).tint(.orange)
                        Marker("End location", coordinate: end).tint(.blue)
                        MapPolyline(coordinates: [start, end]).stroke(.blue, lineWidth: 3)
                    }
                    .listRowInsets(EdgeInsets())
                    .frame(height: 400)
                }

                Section {
                    Button("Delete Log", role: .destructive) { showDeleteConfirmation = true }
                        .disabled(log.endTime == nil || busy)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(busy) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }.disabled(!canSave)
                }
            }
            .alert("Delete Log", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(log)
                    do { try modelContext.save(); dismiss() }
                    catch { modelContext.rollback(); saveError = error.localizedDescription }
                }
            } message: {
                Text("Are you sure you want to delete this log? This action cannot be undone.")
            }
            .confirmationDialog("Resume this task?", isPresented: $showResumeConfirmation, titleVisibility: .visible) {
                Button("Resume Timer") { resume() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("If another timer is running, it will stop. The previous entry stays unchanged.")
            }
            .alert(errorTitle, isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
            .interactiveDismissDisabled(busy)
            .disabled(resuming)
        }
    }

    private func taskLabel(_ item: ActivityItem) -> String {
        let snapshot = try? WorkHierarchy.resolve(task: item, in: modelContext)
        let location = [snapshot?.organization?.name, snapshot?.client?.name, snapshot?.project?.name]
            .compactMap { $0 }.joined(separator: " / ")
        return location.isEmpty ? item.name ?? "Unnamed task" : "\(item.name ?? "Unnamed task") — \(location)"
    }

    private func save() {
        guard canSave, let id = log.id else { return }
        saving = true
        errorTitle = "Unable to save log"
        let selectedActivityId = activity?.id
        let start = startTime
        let end = endTime
        Task {
            defer { saving = false }
            do {
                try await PersistenceManager.shared.activityLogActor.saveCompletedLog(
                    logId: id, activityId: selectedActivityId, startTime: start, endTime: end,
                    refreshAssignment: refreshAssignment
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }

    private func resume() {
        guard canResume, let id = log.id else { return }
        resuming = true
        errorTitle = "Unable to resume timer"
        Task {
            defer { resuming = false }
            do {
                _ = try await RunningManager.shared.resumeCompletedLog(logId: id)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
