import SwiftUI

struct RawDataView: View {
    let dateFormatter = ISO8601DateFormatter()
    let logs: [ActivityLog]
    @State private var searchTerm = ""
    @State private var csvURL: URL?
    @State private var exportFailed = false
    @State private var selectedLog: ActivityLog?

    private var searchedLogs: [ActivityLog] {
        guard !searchTerm.isEmpty else { return logs }
        return logs.filter {
            ($0.activity?.name ?? "Unknown activity").localizedCaseInsensitiveContains(searchTerm)
        }
    }

    private func dateText(_ date: Date?) -> String {
        guard let date, date.timeIntervalSinceReferenceDate.isFinite else { return "Missing date" }
        return dateFormatter.string(from: date)
    }

    private func durationText(_ log: ActivityLog) -> String {
        guard let start = log.startTime, let end = log.endTime,
              start.timeIntervalSinceReferenceDate.isFinite,
              end.timeIntervalSinceReferenceDate.isFinite, end >= start else { return "—" }
        return "\(end.timeIntervalSince(start))s"
    }

    var body: some View {
        List(searchedLogs) { log in
            VStack(alignment: .leading) {
                HStack {
                    Text(log.activity?.name ?? "Unknown activity")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(durationText(log)).font(.footnote)
                }
                HStack {
                    Text(dateText(log.startTime))
                    Spacer()
                    Text(log.endTime == nil ? "Unfinished" : dateText(log.endTime))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let startLat = log.startLatitude, let startLon = log.startLongitude,
                   let endLat = log.endLatitude, let endLon = log.endLongitude,
                   [startLat, startLon, endLat, endLon].allSatisfy(\.isFinite) {
                    HStack {
                        Text("\(abs(startLat), specifier: "%.4f")° \(startLat >= 0 ? "N" : "S"), \(abs(startLon), specifier: "%.4f")° \(startLon >= 0 ? "E" : "W")")
                        Spacer()
                        Text("\(abs(endLat), specifier: "%.4f")° \(endLat >= 0 ? "N" : "S"), \(abs(endLon), specifier: "%.4f")° \(endLon >= 0 ? "E" : "W")")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedLog = log }
        }
        .overlay {
            if searchedLogs.isEmpty {
                ContentUnavailableView("No logs found", systemImage: "questionmark.app")
            }
        }
        .searchable(text: $searchTerm)
        .sheet(item: $selectedLog) { log in LogDetailView(log: log) }
        .task { await prepareExport() }
        .onChange(of: selectedLog == nil) { _, dismissed in
            if dismissed { Task { await prepareExport() } }
        }
        .navigationTitle("Raw Data")
        .toolbar {
            ToolbarItem {
                if let csvURL {
                    ShareLink(item: csvURL, preview: SharePreview("Data Export", image: Image(systemName: "tablecells")))
                } else if exportFailed {
                    Button("Retry export", systemImage: "arrow.clockwise") {
                        Task { await prepareExport() }
                    }
                } else {
                    ProgressView()
                }
            }
        }
    }

    private func prepareExport() async {
        csvURL = nil
        exportFailed = false
        do { csvURL = try await CsvHandler().exportDataAsCsv(logs: logs) }
        catch { exportFailed = true }
    }
}
