import Charts
import SwiftUI

struct AreaDiagramView: View {
    let data: TimeFrameData

    private var legendItems: [AnalyticsChartLegendItem] {
        data.seriesStyles.enumerated().map { index, style in
            AnalyticsChartLegendItem(id: "area-\(index)", label: style.name, color: style.color)
        }
    }

    var body: some View {
        AnalyticsChartCard(
            title: "Daily Time Spent",
            description: "Areas show each activity's recorded time for every day in the selected period."
        ) {
            if data.dataSeries.isEmpty {
                ContentUnavailableView("Nothing to display", systemImage: "questionmark.app")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Chart {
                        ForEach(data.dataSeries) { point in
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Time Spent", point.timeSpend),
                                stacking: .unstacked
                            )
                            .foregroundStyle(by: .value("Activity", point.activity.name ?? "Unknown task"))
                        }
                    }
                    .chartYScale(domain: 0 ... 24 * 60 * 60)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let time = value.as(Double.self) {
                                    Text(ReportDurationText.string(from: time))
                                }
                            }
                        }
                    }
                    .chartForegroundStyleScale(
                        domain: data.seriesStyles.map { $0.name },
                        range: data.seriesStyles.map { $0.color }
                    )
                    .chartLegend(.hidden)
                    .frame(height: 260)
                    .clipped()

                    AnalyticsChartLegend(items: legendItems)
                }
            }
        }
    }
}
