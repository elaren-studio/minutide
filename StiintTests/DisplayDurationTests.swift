import Testing
@testable import Stiint

@MainActor
struct DisplayDurationTests {
    @Test func subminuteReportsKeepSecondsWithoutRoundingPositiveTimeToZeroMinutes() {
        #expect(ReportDurationText.string(from: 28.75) == "28s")
        #expect(ReportDurationText.string(from: 59.99) == "59s")
        #expect(ReportDurationText.string(from: 0.2) == "<1s")
        #expect(ReportDurationText.string(from: 60) != "0m")
        #expect(!ReportDurationText.string(from: 60).isEmpty)
        #expect(ReportDurationText.string(from: 0) == "0s")
        #expect(ReportDurationText.string(from: -.infinity) == "0s")
    }
}
