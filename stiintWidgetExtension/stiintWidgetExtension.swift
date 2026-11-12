//
// Original Stiint by Liam Wittig. Adaptive community Live Activity layout.
//
import ActivityKit
import SwiftUI
import WidgetKit

struct stiintWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityDTO.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    activityIcon(context.attributes)
                        .font(.title3)
                        .frame(width: 24, alignment: .leading)
                    Text(context.attributes.name)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                    status(context.state.isActive)
                }

                workPath(context.attributes)

                HStack(spacing: 4) {
                    Text("Started")
                        .foregroundStyle(.secondary)
                    Text(context.attributes.startTime, style: .time)
                        .fontWeight(.medium)
                }
                .font(.caption)

                HStack(alignment: .firstTextBaseline) {
                    Text("Elapsed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    elapsed(context.attributes.startTime)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    activityIcon(context.attributes).font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    status(context.state.isActive)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.name)
                            .font(.headline)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        workPath(context.attributes)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Started")
                                .foregroundStyle(.secondary)
                            Text(context.attributes.startTime, style: .time)
                                .fontWeight(.medium)
                            Spacer(minLength: 4)
                            Text("Elapsed")
                                .foregroundStyle(.secondary)
                            elapsed(context.attributes.startTime)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            } compactLeading: {
                activityIcon(context.attributes).font(.body)
            } compactTrailing: {
                elapsed(context.attributes.startTime)
                    .font(.caption2.weight(.semibold))
                    .frame(width: 58, alignment: .trailing)
            } minimal: {
                activityIcon(context.attributes).font(.body)
            }
        }
    }

    private func activityIcon(_ attributes: LiveActivityDTO) -> some View {
        Image(systemName: attributes.icon)
            .foregroundStyle(Color(hex: attributes.color))
            .accessibilityLabel(attributes.name)
    }

    private func workPath(_ attributes: LiveActivityDTO) -> some View {
        Text(attributes.workPath.isEmpty ? "Unassigned" : attributes.workPath)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .truncationMode(.tail)
    }

    private func status(_ isActive: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary)
                .frame(width: 7, height: 7)
            Text(isActive ? "Tracking" : "Stopped")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(isActive ? .primary : .secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            isActive ? Color.green.opacity(0.14) : Color.secondary.opacity(0.12),
            in: Capsule()
        )
        .accessibilityElement(children: .combine)
    }

    private func elapsed(_ startTime: Date) -> some View {
        Text(startTime, style: .timer)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.trailing)
            .accessibilityLabel("Elapsed time")
    }
}

#if DEBUG
#Preview("Over an hour", as: .dynamicIsland(.expanded), using: LiveActivityDTO(
    id: UUID(), name: "A longer activity name", startTime: .now.addingTimeInterval(-3661),
    icon: "book.fill", color: "#007AFF",
    organizationName: "Elaren Studio", clientName: "Minutide", projectName: "Time Tracking"
)) {
    stiintWidgetExtension()
} contentStates: {
    LiveActivityDTO.ContentState(isActive: true)
}
#endif
