import SwiftData
import SwiftUI

enum MyDayDisplayMode: String {
    case timeline, list
}

/// One validated interval, clipped to the selected calendar day. The stored log is never changed.
struct MyDayEntry: Identifiable {
    let log: ActivityLog
    let start: Date
    let end: Date
    var id: PersistentIdentifier { log.persistentModelID }
    var duration: TimeInterval { end.timeIntervalSince(start) }
    var isRunning: Bool { log.endTime == nil }
    var task: WorkNodeSnapshot? { log.workSnapshot.task }
    var path: String {
        let snapshot = log.workSnapshot
        return [snapshot.organization?.name, snapshot.client?.name, snapshot.project?.name]
            .compactMap { $0 }.joined(separator: " / ")
    }

    static func entries(logs: [ActivityLog], dayStart: Date, dayEnd: Date,
                        now: Date, scope: WorkScope) -> [MyDayEntry] {
        guard validDate(dayStart), validDate(dayEnd), dayEnd > dayStart, validDate(now) else { return [] }
        return logs.compactMap { log -> MyDayEntry? in
            guard let start = log.startTime, validDate(start),
                  let end = log.endTime ?? Optional(now), validDate(end), end > start,
                  start < dayEnd, end > dayStart else { return nil }
            switch scope {
            case .allWork: break
            case .unassigned:
                guard log.workSnapshot.organization?.id == nil else { return nil }
            case .organization(let id):
                guard log.workSnapshot.organization?.id == id else { return nil }
            }
            return MyDayEntry(log: log, start: max(start, dayStart), end: min(end, dayEnd))
        }.sorted {
            if $0.start != $1.start { return $0.start < $1.start }
            if $0.end != $1.end { return $0.end < $1.end }
            return ($0.log.id?.uuidString ?? "") < ($1.log.id?.uuidString ?? "")
        }
    }

    static func validDate(_ date: Date) -> Bool {
        date.timeIntervalSinceReferenceDate.isFinite && date > .distantPast && date < .distantFuture
    }

    /// Seconds are never rounded up into invented tracked minutes.
    static func durationText(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0 sec" }
        if seconds < 1 { return "<1 sec" }
        let whole = seconds.rounded(.down)
        let hours = (whole / 3600).rounded(.down)
        let minutes = ((whole.truncatingRemainder(dividingBy: 3600)) / 60).rounded(.down)
        let remaining = whole.truncatingRemainder(dividingBy: 60)
        if hours > 0 { return "\(hours.formatted(.number.precision(.fractionLength(0)))) hr \(Int(minutes)) min \(Int(remaining)) sec" }
        if minutes > 0 { return "\(Int(minutes)) min \(Int(remaining)) sec" }
        return "\(Int(remaining)) sec"
    }
}

struct MyDayEntriesView: View {
    let selectedDate: Date
    let mode: MyDayDisplayMode
    @Query private var logs: [ActivityLog]
    @AppStorage("work.organizationScope") private var organizationScope = "all"
    private let dayStart: Date
    private let dayEnd: Date

    init(selectedDate: Date, mode: MyDayDisplayMode) {
        self.selectedDate = selectedDate
        self.mode = mode
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        dayStart = start
        dayEnd = end
        // Fetch all potential open intervals; the shared projection validates against live now.
        // Capturing now in the persistent predicate would hide a timer started after this view appeared.
        _logs = Query(filter: TimelineDayQuery.predicate(dayStart: start, dayEnd: end, now: end),
                      sort: \ActivityLog.startTime)
    }

    var body: some View {
        SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { context in
            let entries = MyDayEntry.entries(logs: logs, dayStart: dayStart, dayEnd: dayEnd,
                                             now: context.date, scope: WorkScope(rawValue: organizationScope))
            if mode == .list {
                MyDayListView(entries: entries)
            } else {
                TimeLineView(selectedDate: selectedDate, entries: entries, now: context.date)
            }
        }
    }
}

struct MyDayListView: View {
    let entries: [MyDayEntry]

    var body: some View {
        List {
            Section {
                LabeledContent("Tracked this day", value: MyDayEntry.durationText(entries.reduce(0) { $0 + $1.duration }))
                    .accessibilityIdentifier("timeline.total")
            }
            if !entries.isEmpty {
                Section("Entries") {
                    ForEach(entries) { entry in
                        MyDayEntryRow(entry: entry, identifierPrefix: "timeline.entry")
                    }
                }
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No tracked time", systemImage: "clock",
                                       description: Text("No entries for this day in the selected work scope."))
            }
        }
    }
}

struct MyDayEntryRow: View {
    let entry: MyDayEntry
    let identifierPrefix: String
    @State private var selectedLog: ActivityLog?

    var body: some View {
        Button {
            guard !entry.isRunning else { return }
            selectedLog = entry.log
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entry.task?.sfSymbolName ?? "questionmark.circle.dashed")
                    .foregroundStyle(Color(hex: entry.task?.colorHex))
                    .font(.title3)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.task?.name ?? "Unavailable task").font(.headline)
                        Spacer(minLength: 8)
                        Text(MyDayEntry.durationText(entry.duration)).monospacedDigit().font(.subheadline)
                    }
                    if !entry.path.isEmpty {
                        Text(entry.path).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(timeRange).font(.caption).foregroundStyle(.secondary)
                    if entry.isRunning {
                        Label("Running", systemImage: "record.circle")
                            .font(.caption.weight(.semibold)).foregroundStyle(.tint)
                    }
                    if entry.log.startTime != entry.start || (!entry.isRunning && entry.log.endTime != entry.end) {
                        Text("Time shown within this day").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(identifierPrefix).\(entry.log.id?.uuidString ?? String(describing: entry.id))")
        .accessibilityHint(entry.isRunning ? "Stop the timer to edit this entry" : "Edit recorded entry")
        .sheet(item: $selectedLog) { log in LogDetailView(log: log) }
    }

    private var timeRange: String {
        let style = Date.FormatStyle.dateTime.hour().minute().second()
        let endText = entry.isRunning && Calendar.current.isDateInToday(entry.end)
            ? "Now" : entry.end.formatted(style)
        return "\(entry.start.formatted(style)) – \(endText)"
    }
}
