//
//  AnalyticsView.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var currentFilter: FilterData?
    @State private var timeFrameData: TimeFrameData?

    private func loadData() {
        if let filter = currentFilter {
            Task {
                timeFrameData = await AnalyticsDataProvider()
                    .loadDataForTimeFrame(
                        filterData: filter
                    )
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                AnalyticsFilterView { filterData in
                    currentFilter = filterData
                    print("Filter applied in AnalyticsView:")
                    print(
                        "- Date Range: \(filterData.startDate) to \(filterData.endDate)"
                    )
                    print("- Show Free Time: \(filterData.showFreeTime)")
                    print(
                        "- Selected Activities: \(filterData.selectedActivityIds.count)"
                    )
                }
                .padding(.horizontal)
                if let filter = currentFilter, let data = timeFrameData {
                    SankyDiagramView(data: data, filterData: filter).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.sankey")
                    PieDiagramView(data: data, filterData: filter).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.pie")
                    BarDiagramView(data: data).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.bar")
                    LineDiagramView(data: data).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.line")
                    AreaDiagramView(data: data).padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("analytics.chart.area")
                    
                } else {
                    VStack {
                        Spacer()
                        ProgressView()
                        Text("Gathering data...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(height: 300)
                }

            }.onAppear {
                loadData()
            }.onChange(of: currentFilter) { _, _ in
                loadData()
            }
            .refreshable {
                if let filter = currentFilter {
                    timeFrameData = await AnalyticsDataProvider()
                        .loadDataForTimeFrame(
                            filterData: filter
                        )
                }
            }
            .navigationTitle("Insights")
        }
    }
}
