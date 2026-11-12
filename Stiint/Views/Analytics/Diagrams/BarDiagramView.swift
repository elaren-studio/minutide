import Charts
import SwiftUI

struct BarDiagramView: View {
    let data: TimeFrameData

    private var legendItems: [AnalyticsChartLegendItem] {
        data.dataPoints.map { point in
            AnalyticsChartLegendItem(
                id: point.id.uuidString,
                label: point.activity.name ?? "Unknown task",
                color: point.activity.color
            )
        }
    }

    var body: some View {
        AnalyticsChartCard(
            title: "Avg. Time per Day",
            description: "Bars compare each tracked activity by its average daily time."
        ) {
            if data.dataPoints.isEmpty {
                ContentUnavailableView("Nothing to display", systemImage: "questionmark.app")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Chart(data.dataPoints, id: \.id) { element in
                        BarMark(
                            x: .value("Index", data.dataPoints.firstIndex(where: { item in
                                item.id == element.id
                            }) ?? 0),
                            y: .value("Count", max(0, element.timeAvg))
                        )
                        .foregroundStyle(by: .value("Name", element.activity.name ?? "Unknown task"))
                    }
                    .chartForegroundStyleScale(range: data.dataPoints.map { $0.activity.color })
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let time = value.as(Double.self) {
                                    Text(ReportDurationText.string(from: time))
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 260)
                    .clipped()

                    AnalyticsChartLegend(items: legendItems)
                }
            }
        }
    }
}
