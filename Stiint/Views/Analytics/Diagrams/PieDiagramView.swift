import Charts
import SwiftUI

struct PieDiagramView: View {
    let data: TimeFrameData
    let filterData: FilterData

    @State private var pieChartData: [DataPoint] = []

    private var legendItems: [AnalyticsChartLegendItem] {
        pieChartData.map { point in
            AnalyticsChartLegendItem(
                id: point.id.uuidString,
                label: "\(point.activity.name ?? "Unknown task") · \(ReportDurationText.string(from: point.timeSpend))",
                color: point.activity.color
            )
        }
    }

    private func updatePieChart() {
        let freeTimeActivity = ActivityItem(id: UUID(), name: "Free Time", color: .accentColor)
        pieChartData = data.dataPoints
        if filterData.showFreeTime {
            pieChartData.append(DataPoint(
                activity: freeTimeActivity,
                timeSpend: data.timeOverall - data.timeSpendOnActivities,
                filterData: filterData
            ))
        }
    }

    var body: some View {
        AnalyticsChartCard(
            title: "Avg. Time per Day",
            description: "Slices compare time spent on each activity over the selected period. Free time appears when enabled."
        ) {
            if pieChartData.isEmpty {
                ContentUnavailableView("Nothing to display", systemImage: "questionmark.app")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Chart(pieChartData, id: \.activity.id) { element in
                        SectorMark(
                            angle: .value("Count", element.timeSpend),
                            innerRadius: .ratio(0.6)
                        )
                        .foregroundStyle(by: .value("Name", element.activity.name ?? "Unknown task"))
                    }
                    .chartForegroundStyleScale(range: pieChartData.map { $0.activity.color })
                    .chartLegend(.hidden)
                    .chartXAxis(.hidden)
                    .frame(height: 260)
                    .clipped()

                    AnalyticsChartLegend(items: legendItems)
                }
            }
        }
        .onAppear(perform: updatePieChart)
        .onChange(of: data.dataPoints) { _, _ in updatePieChart() }
        .onChange(of: filterData.showFreeTime) { _, _ in updatePieChart() }
    }
}
