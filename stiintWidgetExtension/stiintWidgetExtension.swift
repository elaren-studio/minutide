//
// Original Stiint by Liam Wittig. Adaptive community Live Activity layout.
//
import ActivityKit
import SwiftUI
import WidgetKit

struct stiintWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityDTO.self) { context in
            HStack(spacing: 12) {
                activityIcon(context.attributes)
                    .font(.title2)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.name)
                        .font(.headline)
                        .lineLimit(1)
                    elapsed(context.attributes.startTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    activityIcon(context.attributes).font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    elapsed(context.attributes.startTime)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            } compactLeading: {
                activityIcon(context.attributes)
            } compactTrailing: {
                elapsed(context.attributes.startTime)
                    .font(.caption2)
                    .frame(width: 58)
            } minimal: {
                activityIcon(context.attributes)
            }
        }
    }

    private func activityIcon(_ attributes: LiveActivityDTO) -> some View {
        Image(systemName: attributes.icon)
            .foregroundStyle(Color(hex: attributes.color))
            .accessibilityLabel(attributes.name)
    }

    private func elapsed(_ startTime: Date) -> some View {
        Text(startTime, style: .timer)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Elapsed time")
    }
}

#if DEBUG
#Preview("Over an hour", as: .dynamicIsland(.expanded), using: LiveActivityDTO(
    id: UUID(), name: "A longer activity name", startTime: .now.addingTimeInterval(-3661),
    icon: "book.fill", color: "#007AFF"
)) {
    stiintWidgetExtension()
} contentStates: {
    LiveActivityDTO.ContentState(isActive: true)
}
#endif
