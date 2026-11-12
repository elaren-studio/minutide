import SwiftUI

struct AnalyticsView: View {
    @State private var currentFilter: FilterData?
    @State private var workReportLoad: WorkReportLoad?
    @State private var hierarchyFilters = WorkReportFilters()
    @State private var groupings: Set<WorkReportGrouping> = [.task]
    @State private var metric: WorkReportMetric = .duration
    @State private var sortField: WorkReportSortField = .metric
    @State private var sortDirection: WorkReportSortDirection = .descending
    @State private var requestID = UUID()
    @State private var isLoading = false
    @State private var loadError: String?

    private func requestReload() {
        // Hide the previous result and its exports as soon as controls change.
        workReportLoad = nil
        loadError = nil
        isLoading = true
        requestID = UUID()
    }

    private func loadData(generation: UUID) async {
        guard generation == requestID, !Task.isCancelled, let filter = currentFilter else { return }
        let capturedHierarchyFilters = hierarchyFilters
        let capturedGroupings = WorkReportGrouping.allCases.filter(groupings.contains)
        let capturedMetric = metric
        let capturedSorting = [WorkReportSort(field: sortField, direction: sortDirection)]
        isLoading = true
        loadError = nil
        workReportLoad = nil
        do {
            let value = try await AnalyticsDataProvider().loadWorkReport(
                filterData: filter,
                hierarchyFilters: capturedHierarchyFilters,
                groupings: capturedGroupings,
                metric: capturedMetric,
                sorting: capturedSorting
            )
            guard generation == requestID, !Task.isCancelled else { return }
            workReportLoad = value
        } catch {
            guard generation == requestID, !Task.isCancelled else { return }
            loadError = error.localizedDescription
        }
        guard generation == requestID, !Task.isCancelled else { return }
        isLoading = false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                AnalyticsFilterView { filterData in
                    currentFilter = filterData
                }
                .padding(.horizontal)

                WorkReportControls(
                    filters: $hierarchyFilters,
                    groupings: $groupings,
                    metric: $metric,
                    sortField: $sortField,
                    sortDirection: $sortDirection,
                    options: workReportLoad?.options ?? WorkReportOptions()
                )
                .padding(.horizontal)

                if let loadError {
                    ContentUnavailableView {
                        Label("Report unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(loadError)
                    } actions: {
                        Button("Try again", systemImage: "arrow.clockwise", action: requestReload)
                            .accessibilityIdentifier("analytics.report.retry")
                    }
                    .frame(height: 300)
                    .accessibilityIdentifier("analytics.report.error")
                } else if let data = workReportLoad {
                    WorkReportSummaryView(result: data.report)
                        .id(requestID)
                        .padding(.horizontal)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.report.summary")

                    SankyDiagramView(data: data.timeFrameData, filterData: data.chartFilterData).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.sankey")
                    PieDiagramView(data: data.timeFrameData, filterData: data.chartFilterData).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.pie")
                    BarDiagramView(data: data.timeFrameData).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.bar")
                    LineDiagramView(data: data.timeFrameData).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.line")
                    AreaDiagramView(data: data.timeFrameData).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.area")
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(isLoading ? "Updating report…" : "Gathering data…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .accessibilityIdentifier("analytics.report.loading")
                }
            }
            .task(id: requestID) { [requestID] in await loadData(generation: requestID) }
            .onChange(of: currentFilter) { _, _ in requestReload() }
            .onChange(of: hierarchyFilters) { _, _ in requestReload() }
            .onChange(of: groupings) { _, _ in requestReload() }
            .onChange(of: metric) { _, _ in requestReload() }
            .onChange(of: sortField) { _, _ in requestReload() }
            .onChange(of: sortDirection) { _, _ in requestReload() }
            .refreshable { requestReload() }
            .navigationTitle("Reports")
        }
    }
}
