import Sankey
import SwiftUI

struct SankyDiagramView: View {
    let data: TimeFrameData
    let filterData: FilterData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var labelFontSize: CGFloat = 12
    @State private var sankeyData = SankeyData(nodes: [], links: [])

    private var freeTimeAverage: Double {
        max(0, data.timeOverallAvg - data.timeSpendOnActivitiesAvg)
    }

    private var chartHeight: CGFloat {
        let nodeCount = max(1, data.dataPoints.count + (filterData.showFreeTime ? 1 : 0))
        let rowHeight = max(38, labelFontSize * 2.5)
        let minimumHeight: CGFloat = dynamicTypeSize.isAccessibilitySize ? 250 : 190
        return max(minimumHeight, CGFloat(nodeCount) * rowHeight + 48)
    }

    private var legendItems: [AnalyticsChartLegendItem] {
        let activities = data.dataPoints.enumerated().map { index, point in
            AnalyticsChartLegendItem(
                id: point.id.uuidString,
                label: "\(index + 1). \(point.activity.name ?? "Unknown task") · \(ReportDurationText.string(from: point.timeAvg))",
                color: point.activity.color
            )
        }

        guard filterData.showFreeTime else { return activities }
        return activities + [AnalyticsChartLegendItem(
            id: "free-time",
            label: "Free time · \(ReportDurationText.string(from: freeTimeAverage))",
            color: .accentColor
        )]
    }

    private func updateSankey() {
        let sourceID = "total"
        var nodes = [SankeyNode(sourceID, label: "Total", color: .accentColor)]
        var links: [SankeyLink] = []

        for (index, point) in data.dataPoints.enumerated() {
            let activityID = "activity-\(index)"
            nodes.append(SankeyNode(activityID, label: "#\(index + 1)", color: point.activity.color))
            links.append(SankeyLink(point.timeAvg, from: sourceID, to: activityID))
        }

        if filterData.showFreeTime {
            let freeTimeID = "free-time"
            nodes.append(SankeyNode(freeTimeID, label: "Free", color: .accentColor))
            links.append(SankeyLink(freeTimeAverage, from: sourceID, to: freeTimeID))
        }

        sankeyData = SankeyData(nodes: nodes, links: links)
    }

    var body: some View {
        AnalyticsChartCard(
            title: "Avg. Time per Day",
            description: "The diagram compares each activity's average daily time over the selected period."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                SankeyDiagram(sankeyData)
                    .nodeOpacity(1)
                    .nodePadding(Double(max(8, labelFontSize)))
                    .linkColorMode(.target)
                    .labelPadding(5)
                    .labelFontSize(Double(labelFontSize))
                    .frame(height: chartHeight)
                    .clipped()
                    .accessibilityIdentifier("analytics.sankey.plot")

                AnalyticsChartLegend(items: legendItems)
                    .accessibilityIdentifier("analytics.sankey.legend")
            }
        }
        .onAppear(perform: updateSankey)
        .onChange(of: data.dataPoints) { _, _ in updateSankey() }
        .onChange(of: filterData.showFreeTime) { _, _ in updateSankey() }
    }
}
