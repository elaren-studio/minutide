import SwiftUI

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    case lastMonth = "Last Month"
    case custom = "Custom Range"

    var id: String { rawValue }

    var accessibilityKey: String {
        switch self {
        case .today: "today"
        case .yesterday: "yesterday"
        case .last7Days: "last7Days"
        case .lastMonth: "lastMonth"
        case .custom: "custom"
        }
    }
}

public struct FilterData: Equatable {
    var startDate: Date
    var endDate: Date
    var showFreeTime: Bool
    // Kept for source compatibility with the original activity-only analytics path.
    var selectedActivityIds: [UUID]
}

struct AnalyticsFilterView: View {
    @State private var selectedDateRange: DateRangeFilter = .last7Days
    @State private var showFreeTime: Bool = true
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
    @State private var customEndDate: Date = .now
    @State private var showFilterSheet = false

    let onFilterChange: (FilterData) -> Void

    var body: some View {
        Button(action: { showFilterSheet = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDateRange.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(getDateRangeDescription())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("analytics.filter.date.summary")

                    HStack(spacing: 12) {
                        Label("Work filters", systemImage: "briefcase.fill")
                        if showFreeTime {
                            Label("Free time", systemImage: "clock.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("analytics.filter.date.open")
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                selectedDateRange: selectedDateRange,
                showFreeTime: showFreeTime,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            ) { range, freeTime, start, end in
                selectedDateRange = range
                showFreeTime = freeTime
                customStartDate = start
                customEndDate = end
                applyFilter()
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear(perform: applyFilter)
    }

    private func applyFilter() {
        let range = getDateRange()
        onFilterChange(FilterData(
            startDate: range.start,
            endDate: range.end,
            showFreeTime: showFreeTime,
            selectedActivityIds: []
        ))
    }

    /// `end` is exclusive. Date-only custom end selections include the whole selected day.
    private func getDateRange(now: Date = .now) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        switch selectedDateRange {
        case .today:
            return (startOfToday, endOfToday)
        case .yesterday:
            let start = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
            return (start, startOfToday)
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
            return (start, endOfToday)
        case .lastMonth:
            let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? startOfToday
            let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) ?? startOfThisMonth
            return (startOfLastMonth, startOfThisMonth)
        case .custom:
            let start = calendar.startOfDay(for: customStartDate)
            let selectedEndDay = calendar.startOfDay(for: customEndDate)
            let end = calendar.date(byAdding: .day, value: 1, to: selectedEndDay) ?? selectedEndDay
            return (start, end)
        }
    }

    private func getDateRangeDescription() -> String {
        let calendar = Calendar.current
        let (start, end) = getDateRange()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        return "\(formatter.string(from: start)) - \(formatter.string(from: inclusiveEnd))"
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draftDateRange: DateRangeFilter
    @State private var draftShowFreeTime: Bool
    @State private var draftStartDate: Date
    @State private var draftEndDate: Date
    let onApply: (DateRangeFilter, Bool, Date, Date) -> Void

    init(selectedDateRange: DateRangeFilter, showFreeTime: Bool,
         customStartDate: Date, customEndDate: Date,
         onApply: @escaping (DateRangeFilter, Bool, Date, Date) -> Void) {
        _draftDateRange = State(initialValue: selectedDateRange)
        _draftShowFreeTime = State(initialValue: showFreeTime)
        _draftStartDate = State(initialValue: customStartDate)
        _draftEndDate = State(initialValue: customEndDate)
        self.onApply = onApply
    }

    private var hasValidDates: Bool {
        draftDateRange != .custom
            || Calendar.current.startOfDay(for: draftStartDate) <= Calendar.current.startOfDay(for: draftEndDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Picker("Date Range", selection: $draftDateRange) {
                        ForEach(DateRangeFilter.allCases) { range in
                            Text(range.rawValue).tag(range)
                                .accessibilityIdentifier("analytics.filter.date.preset.\(range.accessibilityKey)")
                        }
                    }
                    .sensoryFeedback(.selection, trigger: draftDateRange)
                    .pickerStyle(.inline)
                    .accessibilityIdentifier("analytics.filter.date.preset")
                }
                if draftDateRange == .custom {
                    Section("Custom Range") {
                        DatePicker("Start Date", selection: $draftStartDate, displayedComponents: .date)
                            .accessibilityIdentifier("analytics.filter.date.start")
                        DatePicker("End Date", selection: $draftEndDate, displayedComponents: .date)
                            .accessibilityIdentifier("analytics.filter.date.end")
                        if !hasValidDates {
                            Text("End date must be on or after the start date.")
                                .font(.footnote).foregroundStyle(.red)
                        }
                    }
                }
                Section {
                    Toggle("Show Free Time", isOn: $draftShowFreeTime)
                        .accessibilityIdentifier("analytics.filter.freeTime")
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("analytics.filter.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draftDateRange, draftShowFreeTime, draftStartDate, draftEndDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasValidDates)
                    .accessibilityIdentifier("analytics.filter.apply")
                }
            }
        }
    }
}

#Preview {
    AnalyticsFilterView { _ in }.padding()
}
