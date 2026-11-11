import MapKit
import SwiftData
import SwiftUI

struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var log: ActivityLog
    @Query private var activities: [ActivityItem]
    @State private var showDeleteConfirmation = false
    @State private var saveError: String?
    @State private var saving = false
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
        guard hasCompleteClosedDates, log.id != nil, !saving,
              activity != nil || log.activity == nil else { return false }
        let latestEnd = DtoManager.shared.activityDTO?.startTime ?? Date.now
        return endTime > startTime && endTime <= latestEnd
    }

    private var selectableActivities: [ActivityItem] {
        activities.filter { $0.archived != true || $0.persistentModelID == log.activity?.persistentModelID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Picker("Activity", selection: $activity) {
                        Text("Choose an activity").tag(Optional<ActivityItem>.none)
                        ForEach(selectableActivities) { item in
                            Text(item.name ?? "Unnamed").tag(Optional(item))
                        }
                    }
                    .disabled(!hasCompleteClosedDates || saving)
                    if log.activity == nil {
                        Text("This log's activity is unavailable. You can keep its missing assignment or choose an existing activity. The saved log is preserved until you tap Done.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                .disabled(saving)

                if hasCompleteClosedDates, endTime >= startTime {
                    Section("Duration") {
                        Text(Duration.seconds(endTime.timeIntervalSince(startTime)),
                             format: .units(allowed: [.hours, .minutes]))
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
                        .disabled(log.endTime == nil || saving)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
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
            .alert("Unable to save log", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
            .interactiveDismissDisabled(saving)
        }
    }

    private func save() {
        guard canSave, let id = log.id else { return }
        saving = true
        let selectedActivityId = activity?.id
        let start = startTime
        let end = endTime
        Task {
            defer { saving = false }
            do {
                try await PersistenceManager.shared.activityLogActor.saveCompletedLog(
                    logId: id, activityId: selectedActivityId, startTime: start, endTime: end
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
