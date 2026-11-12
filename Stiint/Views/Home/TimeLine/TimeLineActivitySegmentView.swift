//
//  TimeLineActivitySegmentView.swift
//  Stiint
//
//  Created by Wittig, Liam on 11.12.25.
//

import SwiftUI

struct TimeLineActivitySegmentView: View {
    private static let unavailableDuration = "Duration unavailable"

    let start: CGFloat
    let end: CGFloat
    let log: ActivityLog

    let fmt = DateComponentsFormatter()

    let timeDistance: String
    private let canShowRunningTimer: Bool
    private let hasValidTimeRange: Bool

    init(
        start: CGFloat,
        end: CGFloat,
        log: ActivityLog,
        isShowingLogSheet: Bool = false,
        now: Date = .now
    ) {
        self.start = start
        self.end = end
        self.log = log
        self.isShowingLogSheet = isShowingLogSheet
        let finiteNow = Self.isFiniteDate(now)
        canShowRunningTimer = log.endTime == nil
            && finiteNow
            && log.startTime.map {
                guard Self.isFiniteDate($0) else { return false }
                let elapsed = now.timeIntervalSince($0)
                return elapsed.isFinite && elapsed >= 0
            } == true

        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = [.hour, .minute]
        if let startTime = log.startTime,
           Self.isFiniteDate(startTime),
           let endTime = log.endTime ?? (Self.isFiniteDate(now) ? now : nil),
           Self.isFiniteDate(endTime),
           endTime > startTime {
            let seconds = endTime.timeIntervalSince(startTime)
            if seconds.isFinite, seconds > 0 {
                hasValidTimeRange = true
                timeDistance = fmt.string(from: seconds) ?? Self.unavailableDuration
            } else {
                hasValidTimeRange = false
                timeDistance = Self.unavailableDuration
            }
        } else {
            hasValidTimeRange = canShowRunningTimer
            timeDistance = Self.unavailableDuration
        }
    }

    @State private var isShowingLogSheet = false

    var hasValidGeometry: Bool {
        start.isFinite && end.isFinite && start >= 0 && end >= start
    }

    var shouldRenderSegment: Bool {
        hasValidGeometry && hasValidTimeRange && (segmentHeight > 5 || log.endTime == nil)
    }

    private var segmentHeight: CGFloat {
        end - start
    }

    private static func isFiniteDate(_ date: Date) -> Bool {
        date.timeIntervalSinceReferenceDate.isFinite
    }

    var body: some View {
        if shouldRenderSegment {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .frame(height: segmentHeight)
                    .foregroundColor(log.activity?.color ?? .blue)
                    //.opacity(0.95)
                    .cornerRadius(10)
                    .shadow(
                        color: (log.activity?.color ?? .blue).opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                if segmentHeight > 39 {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(
                                systemName: log.activity?.sfSymbolName ?? "questionmark.circle.dashed"
                            )

                            Text(log.activity?.name ?? "no name")
                                .lineLimit(1)

                        }.font(.headline)
                            .foregroundColor(.white)

                        if segmentHeight > 59 {
                            if log.endTime == nil {
                                if canShowRunningTimer, let startTime = log.startTime {
                                    Text(startTime, style: .timer)
                                        .monospaced()
                                        .foregroundColor(.white)
                                } else {
                                    Text("Time unavailable")
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text(timeDistance)
                                    .foregroundColor(.white)
                            }
                        }
                    }.padding(10)
                }
            }
            .onTapGesture {
                guard log.endTime != nil else { return }
                isShowingLogSheet.toggle()
            }.sheet(isPresented: $isShowingLogSheet) {
        
                LogDetailView(log: log)
            }
            .padding(.leading, 40)
            .offset(y: start)
        }
    }
}

#Preview {
    TimeLineActivitySegmentView(
        start: 0,
        end: 60,
        log: ActivityLog(
            startTime: Date.now,
            activity: ActivityItem(
                id: UUID(),
                createdDate: Date.now,
                name: "test",
                color: .pink
            )
        )
    )
}
