import SwiftUI

struct TrackingItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var iconName: String

    var color: Color { Color(hex: colorHex) }

    static let defaultOvertimeID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    static let defaults: [TrackingItem] = [
        TrackingItem(id: defaultOvertimeID, name: "残業時間", colorHex: "#D0021B", iconName: "clock.badge.exclamationmark")
    ]

    static let availableIcons = [
        "clock", "clock.badge.exclamationmark", "book.fill", "figure.run",
        "briefcase.fill", "bed.double.fill", "fork.knife", "chart.bar.fill",
        "star.fill", "heart.fill", "pencil", "dollarsign.circle"
    ]
}

struct TrackingValue: Codable, Hashable {
    var planned: Int = 0
    var actual: Int = 0

    var plannedHours: Double { Double(planned) / 60.0 }
    var actualHours: Double { Double(actual) / 60.0 }

    var hasData: Bool { planned > 0 || actual > 0 }
}
