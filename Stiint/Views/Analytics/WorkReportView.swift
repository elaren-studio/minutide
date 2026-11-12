import SwiftData
import SwiftUI

struct WorkReportControls: View {
    @AppStorage(WorkScope.storageKey) private var organizationScopeRaw = "all"
    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]
    @Query(sort: \WorkClient.name) private var clients: [WorkClient]
    @Query(sort: \WorkProject.name) private var projects: [WorkProject]
    @Query(filter: #Predicate<ActivityItem> { $0.archived == false || $0.archived == nil },
           sort: \ActivityItem.createdDate) private var activeTasks: [ActivityItem]

    @Binding var filters: WorkReportFilters
    @Binding var groupings: Set<WorkReportGrouping>
    @Binding var metric: WorkReportMetric
    @Binding var sortField: WorkReportSortField
    @Binding var sortDirection: WorkReportSortDirection
    let options: WorkReportOptions

    @State private var didInitializeScope = false
    @State private var manuallyChangedOrganizationScope = false

    private var scope: WorkScope { WorkScope(rawValue: organizationScopeRaw) }

    private var organizationOptions: [WorkReportChoice] {
        merge(options.organizations, organizations.map {
            WorkReportChoice(id: $0.id, name: $0.name, colorHex: $0.colorHex, sfSymbolName: $0.sfSymbolName)
        })
    }

    private var clientOptions: [WorkReportChoice] {
        let current = clients.map { client in
            let parent = organizations.first { $0.id == client.organizationID }?.name
            let name = parent.map { "\(client.name) — \($0)" } ?? "\(client.name) — Unassigned organization"
            return WorkReportChoice(id: client.id, name: name, colorHex: client.colorHex,
                                    sfSymbolName: client.sfSymbolName)
        }
        return merge(options.clients, current)
    }

    private var projectOptions: [WorkReportChoice] {
        let current = projects.map { project in
            let client = clients.first { $0.id == project.clientID }
            let organization = organizations.first { $0.id == client?.organizationID }
            let path = [organization?.name, client?.name].compactMap { $0 }.joined(separator: " / ")
            let name = path.isEmpty ? "\(project.name) — Unassigned client" : "\(project.name) — \(path)"
            return WorkReportChoice(id: project.id, name: name, colorHex: project.colorHex,
                                    sfSymbolName: project.sfSymbolName)
        }
        return merge(options.projects, current)
    }

    private var taskOptions: [WorkReportChoice] {
        var choices = Dictionary(uniqueKeysWithValues: activeTasks.compactMap { task -> (UUID, WorkReportChoice)? in
            guard let id = task.id else { return nil }
            return (id, WorkReportChoice(id: id, name: taskChoiceName(task),
                                        colorHex: task.colorHex, sfSymbolName: task.sfSymbolName))
        })
        for choice in options.tasks { choices[choice.id] = choice }
        return choices.values.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            if order != .orderedSame { return order == .orderedAscending }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private var organizationScopeDescription: String {
        switch filters.organizations {
        case .any:
            return "All organizations and unassigned work"
        case .unassigned:
            return "Unassigned organization"
        case .selected(let ids):
            guard !ids.isEmpty else { return "No organizations selected" }
            let names = ids.compactMap { id in organizationOptions.first { $0.id == id }?.name }
            return names.isEmpty ? "\(ids.count) selected" : names.joined(separator: ", ")
        }
    }

    private var savedScopeTitle: String {
        switch scope {
        case .allWork: return "All Work"
        case .unassigned: return "Unassigned"
        case .organization(let id):
            return organizations.first { $0.id == id }?.name ?? "Organization \(id.uuidString.prefix(6))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Work report filters")
                    .font(.headline)
                Spacer()
                Text("Saved scope: \(savedScopeTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Report organization scope: \(organizationScopeDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { dimensionMenus }
                VStack(alignment: .leading, spacing: 8) { dimensionMenus }
            }

            if !selectedFilterChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedFilterChips) { chip in
                            Button(action: chip.remove) {
                                Label(chip.title, systemImage: "xmark.circle.fill")
                                    .font(.caption2)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Menu {
                ForEach(WorkReportGrouping.allCases) { grouping in
                    Button {
                        toggle(grouping)
                    } label: {
                        Label(grouping.title, systemImage: groupings.contains(grouping) ? "checkmark.circle.fill" : "circle")
                    }
                    .accessibilityIdentifier("analytics.report.grouping.\(grouping.rawValue)")
                    .accessibilityValue(groupings.contains(grouping) ? "Selected" : "Not selected")
                }
            } label: {
                Label(groupingSummary, systemImage: "square.grid.2x2")
                    .font(.subheadline)
            }
            .accessibilityIdentifier("analytics.report.grouping")

            HStack {
                Picker("Metric", selection: $metric) {
                    ForEach(WorkReportMetric.allCases) { value in
                        Text(value.title).tag(value)
                    }
                }
                .accessibilityIdentifier("analytics.report.metric")

                Picker("Sort", selection: $sortField) {
                    ForEach(WorkReportSortField.allCases) { value in
                        Text(value.title).tag(value)
                    }
                }
                .accessibilityIdentifier("analytics.report.sort")

                Button {
                    sortDirection = sortDirection == .ascending ? .descending : .ascending
                } label: {
                    Image(systemName: sortDirection == .ascending ? "arrow.up" : "arrow.down")
                }
                .accessibilityLabel(sortDirection == .ascending ? "Sort ascending" : "Sort descending")
                .accessibilityIdentifier("analytics.report.sort-direction")
            }
            .font(.subheadline)

            Text("Selections match any value within a level and must match every selected level.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            guard !didInitializeScope else { return }
            didInitializeScope = true
            filters.organizations = selection(for: scope)
        }
        .onChange(of: organizationScopeRaw) { _, newValue in
            guard !manuallyChangedOrganizationScope else { return }
            filters.organizations = selection(for: WorkScope(rawValue: newValue))
        }
    }

    @ViewBuilder
    private var dimensionMenus: some View {
        WorkReportDimensionMenu(
            title: "Organization",
            selection: filters.organizations,
            options: organizationOptions
        ) { selection in
            manuallyChangedOrganizationScope = true
            filters.organizations = selection
        }

        WorkReportDimensionMenu(title: "Client", selection: filters.clients, options: clientOptions) { selection in
            filters.clients = selection
        }

        WorkReportDimensionMenu(title: "Project", selection: filters.projects, options: projectOptions) { selection in
            filters.projects = selection
        }

        WorkReportDimensionMenu(title: "Task", selection: filters.tasks, options: taskOptions) { selection in
            filters.tasks = selection
        }
    }

    private var groupingSummary: String {
        let selected = WorkReportGrouping.allCases.filter(groupings.contains)
        return selected.isEmpty ? "Group by: All work" : "Group by: " + selected.map(\.title).joined(separator: " + ")
    }

    private func toggle(_ grouping: WorkReportGrouping) {
        if groupings.contains(grouping) { groupings.remove(grouping) }
        else { groupings.insert(grouping) }
    }

    private func selection(for scope: WorkScope) -> WorkReportSelection<UUID> {
        switch scope {
        case .allWork: .any
        case .unassigned: .unassigned
        case .organization(let id): .selected([id])
        }
    }

    private func merge(_ historical: [WorkReportChoice], _ current: [WorkReportChoice]) -> [WorkReportChoice] {
        var choices = Dictionary(uniqueKeysWithValues: historical.map { ($0.id, $0) })
        for choice in current { choices[choice.id] = choice }
        return choices.values.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            if order != .orderedSame { return order == .orderedAscending }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private func taskChoiceName(_ task: ActivityItem) -> String {
        let name = task.name ?? "Unknown task"
        let parents: [String]
        switch task.workParent {
        case .organization(let id):
            parents = [organizations.first { $0.id == id }?.name].compactMap { $0 }
        case .client(let id):
            guard let client = clients.first(where: { $0.id == id }) else {
                return "\(name) — Unavailable client"
            }
            parents = [organizations.first { $0.id == client.organizationID }?.name, client.name]
                .compactMap { $0 }
        case .project(let id):
            guard let project = projects.first(where: { $0.id == id }) else {
                return "\(name) — Unavailable project"
            }
            let client = clients.first { $0.id == project.clientID }
            parents = [organizations.first { $0.id == client?.organizationID }?.name,
                       client?.name, project.name].compactMap { $0 }
        case nil:
            parents = []
        }
        return parents.isEmpty ? "\(name) — Unassigned" : "\(name) — \(parents.joined(separator: " / "))"
    }

    private var selectedFilterChips: [WorkReportSelectedChip] {
        selectionChips(filters.organizations, title: "Organization", options: organizationOptions) { ids in
            manuallyChangedOrganizationScope = true
            filters.organizations = .selected(ids)
        } + selectionChips(filters.clients, title: "Client", options: clientOptions) { ids in
            filters.clients = .selected(ids)
        } + selectionChips(filters.projects, title: "Project", options: projectOptions) { ids in
            filters.projects = .selected(ids)
        } + selectionChips(filters.tasks, title: "Task", options: taskOptions) { ids in
            filters.tasks = .selected(ids)
        }
    }

    private func selectionChips(
        _ selection: WorkReportSelection<UUID>,
        title: String,
        options: [WorkReportChoice],
        onRemove: @escaping (Set<UUID>) -> Void
    ) -> [WorkReportSelectedChip] {
        guard case .selected(let ids) = selection else { return [] }
        return ids.sorted { $0.uuidString < $1.uuidString }.map { id in
            let name = options.first { $0.id == id }?.name ?? String(id.uuidString.prefix(6))
            return WorkReportSelectedChip(id: "\(title)-\(id.uuidString)", title: "\(title): \(name)") {
                var remaining = ids
                remaining.remove(id)
                onRemove(remaining)
            }
        }
    }
}

private struct WorkReportSelectedChip: Identifiable {
    let id: String
    let title: String
    let remove: () -> Void
}

private struct WorkReportDimensionMenu: View {
    let title: String
    let selection: WorkReportSelection<UUID>
    let options: [WorkReportChoice]
    let onSelect: (WorkReportSelection<UUID>) -> Void
    @State private var isShowingOptions = false

    private var summary: String {
        switch selection {
        case .any: return "Any"
        case .unassigned: return "Unassigned"
        case .selected(let ids): return ids.isEmpty ? "None" : "\(ids.count) selected"
        }
    }

    var body: some View {
        Button { isShowingOptions = true } label: {
            Text("\(title): \(summary)")
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .accessibilityIdentifier("analytics.report.filter.\(title.lowercased())")
        .sheet(isPresented: $isShowingOptions) {
            WorkReportDimensionSheet(title: title, selection: selection, options: options, onSelect: onSelect)
                .presentationDetents([.medium, .large])
        }
    }

}

private struct WorkReportDimensionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var draftSelection: WorkReportSelection<UUID>

    let title: String
    let options: [WorkReportChoice]
    let onSelect: (WorkReportSelection<UUID>) -> Void

    init(
        title: String,
        selection: WorkReportSelection<UUID>,
        options: [WorkReportChoice],
        onSelect: @escaping (WorkReportSelection<UUID>) -> Void
    ) {
        self.title = title
        self.options = options
        self.onSelect = onSelect
        _draftSelection = State(initialValue: selection)
    }

    private var filteredOptions: [WorkReportChoice] {
        guard !searchText.isEmpty else { return options }
        return options.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Match") {
                    Button { choose(.any) } label: { selectionLabel("Any", selected: isAny) }
                        .accessibilityIdentifier("analytics.report.filter.\(title.lowercased()).any")
                        .accessibilityValue(isAny ? "Selected" : "Not selected")
                    Button { choose(.unassigned) } label: { selectionLabel(unassignedTitle, selected: isUnassigned) }
                        .accessibilityIdentifier("analytics.report.filter.\(title.lowercased()).unassigned")
                        .accessibilityValue(isUnassigned ? "Selected" : "Not selected")
                }

                Section("Assigned") {
                    if filteredOptions.isEmpty {
                        ContentUnavailableView(searchText.isEmpty ? "No values yet" : "No matches", systemImage: "magnifyingglass")
                    } else {
                        ForEach(filteredOptions) { option in
                            Button { toggle(option.id) } label: {
                                selectionLabel(option.name, selected: isSelected(option.id))
                            }
                            .accessibilityIdentifier("analytics.report.filter.\(title.lowercased()).option.\(option.id.uuidString)")
                            .accessibilityValue(isSelected(option.id) ? "Selected" : "Not selected")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search \(title.lowercased())")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("analytics.report.filter.\(title.lowercased()).cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(draftSelection)
                        dismiss()
                    }
                        .accessibilityIdentifier("analytics.report.filter.\(title.lowercased()).done")
                }
            }
        }
    }

    private var unassignedTitle: String {
        switch title {
        case "Organization": return "Unassigned organization"
        case "Client": return "No client"
        case "Project": return "No project"
        case "Task": return "No task"
        default: return "Unassigned"
        }
    }

    private var isAny: Bool {
        if case .any = draftSelection { return true }
        return false
    }

    private var isUnassigned: Bool {
        if case .unassigned = draftSelection { return true }
        return false
    }

    private func isSelected(_ id: UUID) -> Bool {
        if case .selected(let ids) = draftSelection { return ids.contains(id) }
        return false
    }

    private func choose(_ selection: WorkReportSelection<UUID>) {
        draftSelection = selection
    }

    private func toggle(_ id: UUID) {
        var ids: Set<UUID>
        if case .selected(let current) = draftSelection { ids = current }
        else { ids = [] }
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        choose(.selected(ids))
    }

    private func selectionLabel(_ title: String, selected: Bool) -> some View {
        Label(title, systemImage: selected ? "checkmark.circle.fill" : "circle")
    }
}

struct WorkReportSummaryView: View {
    let result: WorkReportResult
    @State private var summaryURL: URL?
    @State private var detailsURL: URL?
    @State private var exportError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Report summary")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("\(durationText(result.totalDurationSeconds)) · \(result.totalEntryCount) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("analytics.report.totals")
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    summaryExportButton
                    detailsExportButton
                }
                VStack(alignment: .leading, spacing: 8) {
                    summaryExportButton
                    detailsExportButton
                }
            }

            if result.rows.isEmpty {
                ContentUnavailableView("No matching work", systemImage: "chart.bar.xaxis")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(result.rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.displayName)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(durationText(row.durationSeconds))
                                    .fontWeight(.medium)
                                Spacer(minLength: 8)
                                Text("\(row.entryCount) entries")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(durationText(row.durationSeconds))
                                    .fontWeight(.medium)
                                Text("\(row.entryCount) entries")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("analytics.report.row.\(row.id)")
                    Divider()
                }
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("CSV export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "The report could not be written.")
        }
        .onChange(of: result) { _, _ in
            summaryURL = nil
            detailsURL = nil
            exportError = nil
        }
    }

    private func exportSummary() {
        do { summaryURL = try WorkReportCSVExporter.writeSummaryCSV(result) }
        catch { exportError = error.localizedDescription }
    }

    private func exportDetails() {
        do { detailsURL = try WorkReportCSVExporter.writeDetailedCSV(result) }
        catch { exportError = error.localizedDescription }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        ReportDurationText.string(from: seconds)
    }

    @ViewBuilder
    private var summaryExportButton: some View {
        if let summaryURL {
            ShareLink(item: summaryURL, preview: SharePreview("Summary CSV")) {
                Label("Summary CSV", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("analytics.report.export.summary")
        } else {
            Button("Summary CSV", systemImage: "tablecells") { exportSummary() }
                .accessibilityIdentifier("analytics.report.export.summary")
        }
    }

    @ViewBuilder
    private var detailsExportButton: some View {
        if let detailsURL {
            ShareLink(item: detailsURL, preview: SharePreview("Detailed CSV")) {
                Label("Detailed CSV", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("analytics.report.export.details")
        } else {
            Button("Detailed CSV", systemImage: "tablecells") { exportDetails() }
                .accessibilityIdentifier("analytics.report.export.details")
        }
    }
}
