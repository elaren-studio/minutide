import Charts
import SwiftUI

struct LineDiagramView: View {
    let data: TimeFrameData

    private var legendItems: [AnalyticsChartLegendItem] {
        data.seriesStyles.enumerated().map { index, style in
            AnalyticsChartLegendItem(id: "line-\(index)", label: style.name, color: style.color)
        }
    }

    var body: some View {
        AnalyticsChartCard(
            title: "Daily Time Spent",
            description: "Each point shows the time recorded for an activity on a selected date."
        ) {
            if data.dataSeries.isEmpty {
                ContentUnavailableView("Nothing to display", systemImage: "questionmark.app")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Chart {
                        ForEach(data.dataSeries) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Time Spent", point.timeSpend)
                            )
                            .foregroundStyle(by: .value("Activity", point.activity.name ?? "Unknown task"))
                            .symbol(by: .value("Activity", point.activity.name ?? "Unknown task"))
                        }
                    }
                    .chartYScale(domain: 0 ... max(1, data.dataSeries.map(\.timeSpend).max() ?? 0))
                    .chartForegroundStyleScale(
                        domain: data.seriesStyles.map { $0.name },
                        range: data.seriesStyles.map { $0.color }
                    )
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let time = value.as(Double.self) {
                                    Text(ReportDurationText.string(from: time))
                                }
                            }
                        }
                    }
                    .frame(height: 260)
                    .clipped()

                    AnalyticsChartLegend(items: legendItems)
                }
            }
        }
    }
}
