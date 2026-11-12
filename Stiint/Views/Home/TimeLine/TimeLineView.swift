//
//  TimeLineView.swift
//  Stiint
//
//  Created by Wittig, Liam on 11.12.25.
//

import SwiftData
import SwiftUI
internal import Combine

struct TimeLineView: View {
    @Query private var filteredLogs: [ActivityLog]
    let selectedDate: Date
    let calendar = Calendar.current
    let hours: [Int] = Array(0 ... 23)

    let totalHours: Int = 24

    let currentHour: Int = Calendar.current.component(.hour, from: Date())
    @State private var currentTimeValue: Double = 0.0

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @State private var currentZoom = 0.0
    @State private var totalZoom = 1000.0

    // Add minimum and maximum zoom constraints
    private let minZoom: Double = 800.0
    private let maxZoom: Double = 5000.0

    let lineHeight: CGFloat = 2
    
    init(selectedDate: Date) {
        print("loading data for \(selectedDate)")
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = TimelineDayQuery.predicate(
            dayStart: startOfDay,
            dayEnd: endOfDay,
            now: .now
        )

        _filteredLogs = Query(filter: predicate, sort: \.startTime)
    }

    func updateTime() {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        let second = Calendar.current.component(.second, from: now)
        currentTimeValue = Double(hour) + Double(minute) / 60 + Double(
            second
        ) / 3600
    }

    func calculateGeometryOfHouer(hour: Double, geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height / 24 * CGFloat(hour) + (
            geometry.size.height / 24
        ) / 2
    }

    func getGeometry(date: Date?, geometry: GeometryProxy) -> CGFloat {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
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
        
        let timeVal = TimeHandler().getTimeValueForDate(
            date: targetDate,
            selectedDate: selectedDate
        )
        return calculateGeometryOfHouer(hour: timeVal, geometry: geometry)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer()
                    .frame(height: 110)
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                TimeLineSegmentView(
                                    hour: hour,
                                    height: geometry.size.height / 24
                                )
                                .padding(.leading, 20)
                                .id(hour)
                            }
                        }
                        ForEach(filteredLogs) { log in
                            TimeLineActivitySegmentView(
                                start: getGeometry(
                                    date: log.startTime,
                                    geometry: geometry
                                ),
                                end: getGeometry(
                                    date: log.endTime,
                                    geometry: geometry
                                ),
                                log: log
                            )
                            .padding(.horizontal, 20)
                            .offset(x: 12)
                        }

                        // Moving red line

                        if Calendar.current.isDateInToday(selectedDate) {
                            TimeLineCurrentTimeView(
                                currentTimeValue: currentTimeValue,
                                geometry: geometry
                            )
                        }
                    }
                }
                .frame(height: currentZoom + totalZoom)

                Spacer()
                    .frame(height: 110)
            }.onAppear {
                updateTime()
                if(selectedDate > calendar.startOfDay(for: Date.now)){
                    withAnimation {
                        proxy.scrollTo(currentHour, anchor: .center)
                    }
                }else{
                    proxy.scrollTo(12, anchor: .center)
                }
                
            }.onReceive(timer) { _ in
                updateTime()

            }
        }
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
    TimeLineView(selectedDate: Date.now)
}
