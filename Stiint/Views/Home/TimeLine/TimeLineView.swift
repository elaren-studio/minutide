//
//  TimeLineView.swift
//  Stiint
//
//  Created by Wittig, Liam on 11.12.25.
//

import Foundation
import SwiftUI

struct TimeLineView: View {
    @AppStorage("timeline.displayMode") private var displayMode = MyDayDisplayMode.timeline.rawValue
    let selectedDate: Date
    let entries: [MyDayEntry]
    let now: Date
    let calendar = Calendar.current
    private let calendarHeight: Double = 1000
    private var dayStart: Date { calendar.startOfDay(for: selectedDate) }
    private var dayEnd: Date { calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart }
    private var totalHours: Double { dayEnd.timeIntervalSince(dayStart) / 3600 }
    private var hours: [Int] { Array(0..<Int(totalHours.rounded(.up))) }
    private var currentHour: Int { Int(max(0, now.timeIntervalSince(dayStart) / 3600)) }
    
    private var currentTimeValue: Double {
        now.timeIntervalSince(dayStart) / 3600
    }

    func calculateGeometryOfHouer(hour: Double, geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height / totalHours * CGFloat(hour) + (
            geometry.size.height / totalHours
        ) / 2
    }

    func getGeometry(date: Date?, geometry: GeometryProxy) -> CGFloat {
        let startOfDay = dayStart
        let endOfDay = dayEnd
        
        // Determine target date
        let targetDate: Date
        if let date = date {
            targetDate = date
        } else {
            // Use current time, but clamp to endOfDay if we're past the selected day
            targetDate = min(Date.now, endOfDay)
        }
        
        // Clamp to day boundaries
        if targetDate <= startOfDay {
            return calculateGeometryOfHouer(hour: 0, geometry: geometry)
        }
        if targetDate >= endOfDay {
            return calculateGeometryOfHouer(
                hour: Double(totalHours),
                geometry: geometry
            )
        }
        
        // Elapsed position stays monotonic through a repeated DST hour, and
        // retains subsecond intervals instead of truncating both ends to zero.
        let timeVal = targetDate.timeIntervalSince(startOfDay) / 3600
        return calculateGeometryOfHouer(hour: timeVal, geometry: geometry)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Tracked this day", value: MyDayEntry.durationText(entries.reduce(0) { $0 + $1.duration }))
                        .accessibilityIdentifier("timeline.total")
                    if entries.isEmpty {
                        Text("No tracked time for this day in the selected work scope.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if !shortEntries.isEmpty {
                        HStack {
                            Text("Recent entries").font(.headline)
                            Spacer()
                            Button("Show list") { displayMode = MyDayDisplayMode.list.rawValue }
                                .font(.subheadline)
                                .accessibilityIdentifier("timeline.showList")
                        }
                        ForEach(Array(shortEntries.suffix(3).reversed())) { entry in
                            MyDayEntryRow(entry: entry, identifierPrefix: "timeline.segment")
                            Divider()
                        }
                    }
                }
                .padding()
                .id("daySummary")
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                TimeLineSegmentView(
                                    hour: calendar.component(.hour, from: dayStart.addingTimeInterval(Double(hour) * 3600)),
                                    height: geometry.size.height / totalHours
                                )
                                .padding(.leading, 20)
                                .id(hour)
                            }
                        }
                        ForEach(entries) { entry in
                            TimeLineActivitySegmentView(
                                start: getGeometry(
                                    date: entry.start,
                                    geometry: geometry
                                ),
                                end: getGeometry(
                                    date: entry.end,
                                    geometry: geometry
                                ),
                                log: entry.log,
                                now: now,
                                displayDuration: entry.duration
                            )
                            .padding(.horizontal, 20)
                            .offset(x: 12)
                        }

                        // Moving red line

                        if Calendar.current.isDateInToday(selectedDate) {
                            TimeLineCurrentTimeView(
                                currentTimeValue: currentTimeValue,
                                geometry: geometry,
                                totalHours: totalHours
                            )
                        }
                    }
                }
                .frame(height: calendarHeight)

                Spacer()
                    .frame(height: 24)
            }.onAppear {
                if !shortEntries.isEmpty {
                    proxy.scrollTo("daySummary", anchor: .top)
                } else if calendar.isDateInToday(selectedDate) {
                    withAnimation {
                        proxy.scrollTo(currentHour, anchor: .center)
                    }
                }else{
                    proxy.scrollTo(12, anchor: .center)
                }
                
            }
            .onChange(of: shortEntries.filter { !$0.isRunning }.map(\.id)) { old, new in
                // A newly stopped brief timer should be discoverable without
                // moving the calendar on each elapsed-time refresh.
                if new.contains(where: { !old.contains($0) }) {
                    withAnimation { proxy.scrollTo("daySummary", anchor: .top) }
                }
            }
        }
    }

    private var shortEntries: [MyDayEntry] {
        entries.filter { $0.duration / 3600 * calendarHeight / totalHours < 44 }
    }
}

enum TimelineDayQuery {
    static func predicate(dayStart: Date, dayEnd: Date, now: Date) -> Predicate<ActivityLog> {
        let distantPast = Date.distantPast
        let distantFuture = Date.distantFuture

        return #Predicate<ActivityLog> { log in
            (log.endTime ?? now) > dayStart
                && (log.startTime ?? dayEnd) < dayEnd
                && (log.endTime ?? now) > (log.startTime ?? dayEnd)
                && (log.startTime ?? dayEnd) > distantPast
                && (log.startTime ?? dayEnd) < distantFuture
                && (log.endTime ?? now) > distantPast
                && (log.endTime ?? now) < distantFuture
        }
    }
}

#Preview {
    MyDayEntriesView(selectedDate: Date.now, mode: .timeline)
}
