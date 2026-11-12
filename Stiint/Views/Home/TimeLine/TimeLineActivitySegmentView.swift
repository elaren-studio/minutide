//
//  TimeLineActivitySegmentView.swift
//  Stiint
//
//  Created by Wittig, Liam on 11.12.25.
//

import SwiftData
import SwiftUI

struct TimeLineActivitySegmentView: View {
    private static let unavailableDuration = "Duration unavailable"

    let start: CGFloat
    let end: CGFloat
    let log: ActivityLog

    private var capturedTask: WorkNodeSnapshot? { log.workSnapshot.task }
    private var capturedColor: Color { Color(hex: capturedTask?.colorHex) }

    let timeDistance: String
    private let canShowRunningTimer: Bool
    private let hasValidTimeRange: Bool

    init(
        start: CGFloat,
        end: CGFloat,
        log: ActivityLog,
        isShowingLogSheet: Bool = false,
        now: Date = .now,
        displayDuration: TimeInterval? = nil
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

        if let startTime = log.startTime,
           Self.isFiniteDate(startTime),
           let endTime = log.endTime ?? (Self.isFiniteDate(now) ? now : nil),
           Self.isFiniteDate(endTime),
           endTime > startTime {
            let seconds = endTime.timeIntervalSince(startTime)
            if seconds.isFinite, seconds > 0 {
                hasValidTimeRange = true
                timeDistance = MyDayEntry.durationText(displayDuration ?? seconds)
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
        hasValidGeometry && hasValidTimeRange
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
                    // This is a marker, not a minimum-duration block. Compact entries
                    // also have separate full-size rows above the calendar.
                    .frame(height: max(segmentHeight, 2))
                    .foregroundColor(capturedColor)
                    //.opacity(0.95)
                    .cornerRadius(10)
                    .shadow(
                        color: capturedColor.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                if segmentHeight >= 44 {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(
                                systemName: capturedTask?.sfSymbolName ?? "questionmark.circle.dashed"
                            )

                            Text(capturedTask?.name ?? "Unavailable task")
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(capturedTask?.name ?? "Unavailable task"), \(timeDistance)")
            .accessibilityAddTraits(log.endTime == nil ? [] : .isButton)
            .accessibilityIdentifier("timeline.segment.\(log.id?.uuidString ?? String(describing: log.persistentModelID))")
            .accessibilityHidden(segmentHeight < 44)
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
