import SwiftUI
import SwiftData

struct HomeView: View {
    var todayRequest: UUID? = nil
    @State private var dayOffset: Int = 0
    @AppStorage("timeline.displayMode") private var displayMode = MyDayDisplayMode.timeline.rawValue
    @AppStorage("work.organizationScope") private var organizationScope = "all"
    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]

    private var scopeBinding: Binding<WorkScope> {
        Binding(get: { WorkScope(rawValue: organizationScope) },
                set: { organizationScope = $0.rawValue })
    }

    enum ActiveSheet: Identifiable {
        case createLog
        case selectDate
        var id: Int { hashValue }
    }

    @State private var activeSheet: ActiveSheet?

    let dayRange: Int = -2000

    private func dateFor(offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
    }

    private func offsetFor(date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDate = calendar.startOfDay(for: date)

        return calendar
            .dateComponents(
                [.day],
                from: startOfToday,
                to: startOfDate
            ).day ?? 0
    }

    private func formattedDate(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var selectedDate: Date {
        dateFor(offset: dayOffset)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(dayRange...0, id: \.self) { offset in
                        TimeLineDisplayer(
                            offset: offset,
                            currentOffset: dayOffset,
                            mode: MyDayDisplayMode(rawValue: displayMode) ?? .timeline
                        )
                        .tag(offset)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.6)
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .blur(radius: phase.isIdentity ? 0 : 2)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(
                id: .init(
                    get: { dayOffset },
                    set: { dayOffset = $0 ?? 0 }
                )
            )
            .scrollTargetBehavior(.paging)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    WorkScopePicker(selection: scopeBinding, organizations: organizations,
                                    identifier: "timeline.scope")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("View mode", selection: $displayMode) {
                            Label("Timeline", systemImage: "calendar.day.timeline.left")
                                .tag(MyDayDisplayMode.timeline.rawValue)
                                .accessibilityIdentifier("timeline.mode.timeline")
                            Label("List", systemImage: "list.bullet")
                                .tag(MyDayDisplayMode.list.rawValue)
                                .accessibilityIdentifier("timeline.mode.list")
                        }
                    } label: {
                        Image(systemName: displayMode == MyDayDisplayMode.list.rawValue
                              ? "list.bullet" : "calendar.day.timeline.left")
                    }
                    .accessibilityLabel("View mode")
                    .accessibilityIdentifier("timeline.mode")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .createLog
                    } label: {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                    .accessibilityLabel("Create Log")
                    .accessibilityIdentifier("timeline.log.new")
                }

                ToolbarItem(placement: .navigation) {
                    Button {
                        activeSheet = .selectDate
                    } label: {
                        Text(formattedDate(for: selectedDate))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.selection, trigger: dayOffset)
            .onChange(of: todayRequest) { _, _ in dayOffset = 0 }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createLog:
                CreateLogView(defaultDate: selectedDate)

            case .selectDate:
                DaySelectionSheet(
                    date: .init(
                        get: { selectedDate },
                        set: { dayOffset = offsetFor(date: $0) }
                    ),
                    dayRange: dayRange
                )
                .presentationDetents([.medium])
            }
        }
    }

}

struct TimeLineDisplayer: View {
    let offset: Int
    let currentOffset: Int
    let mode: MyDayDisplayMode

    private var date: Date {
        Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
    }

    var body: some View {
        ZStack {
            if abs(offset - currentOffset) <= 1 {
                MyDayEntriesView(selectedDate: date, mode: mode)
            } else {
                Color.clear
            }
        }
        .containerRelativeFrame(.horizontal)
    }
}
