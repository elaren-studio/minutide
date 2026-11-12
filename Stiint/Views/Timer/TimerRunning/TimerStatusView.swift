//
//  TimerStatusView.swift
//  Stiint
//
//  Created by Wittig, Liam on 11.12.25.
//

import SwiftUI

struct TimerStatusView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    var canSwitch = true
    var switchTask: () -> Void = {}
    @State private var isStopping = false

    var body: some View {
        if let activity = DtoManager.shared.activityDTO {
            Group {
                if dynamicTypeSize.isAccessibilitySize && placement != .inline {
                    VStack(alignment: .leading, spacing: 4) {
                        taskButton(activity)
                        HStack {
                            elapsed(activity)
                            Spacer()
                            stopButton(activity)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        taskButton(activity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if placement != .inline {
                            elapsed(activity)
                                .layoutPriority(1)
                        }
                        stopButton(activity)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .accessibilityElement(children: .contain)
        }
    }

    private func taskButton(_ activity: ActivityDTO) -> some View {
        Button(action: switchTask) {
            HStack(spacing: 10) {
                Image(systemName: activity.icon)
                    .foregroundStyle(activity.color)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(activity.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .accessibilityIdentifier("timer.accessory.name")
                    if placement != .inline, !activity.workPath.isEmpty {
                        Text(activity.workPath)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Image(systemName: "chevron.up")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSwitch || isStopping)
        .accessibilityLabel("Switch Task, currently tracking \(activity.name)")
        .accessibilityHint(activity.workPath)
        .accessibilityIdentifier("timeline.timer.switch")
    }

    private func elapsed(_ activity: ActivityDTO) -> some View {
        Text(activity.startTime, style: .timer)
            .font(.system(.subheadline, design: .monospaced))
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("timer.accessory.elapsed")
    }

    private func stopButton(_ activity: ActivityDTO) -> some View {
        Button(isStopping ? "Stopping…" : "Stop") {
            guard !isStopping else { return }
            isStopping = true
            Task {
                // A late tap must not stop a different task started meanwhile.
                await RunningManager.shared.stopSpecificActivity(activityId: activity.id)
                isStopping = false
            }
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .frame(minHeight: 44)
        .fixedSize(horizontal: true, vertical: false)
        .disabled(isStopping)
        .accessibilityLabel("Stop \(activity.name)")
        .accessibilityIdentifier("timer.accessory.stop")
    }
}

#Preview {
    TimerStatusView()
}
