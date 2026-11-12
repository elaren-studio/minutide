import SwiftUI

struct AnalyticsChartCard<Content: View>: View {
    let title: String
    let description: String
    private let content: Content

    init(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AnalyticsChartLegendItem: Identifiable {
    let id: String
    let label: String
    let color: Color
}

struct AnalyticsChartLegend: View {
    let items: [AnalyticsChartLegendItem]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 9, height: 9)
                            .padding(.top, 5)

                        Text(item.label)
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

enum ReportDurationText {
    static func string(from seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0s" }
        if seconds < 1 { return "<1s" }
        if seconds < 60 {
            let number = NumberFormatter.localizedString(from: NSNumber(value: Int(seconds.rounded(.down))), number: .decimal)
            return "\(number)s"
        }
        return TimeHandler().secondsToLocalizedDuration(seconds)
    }
}
