import Foundation

struct TimeBlock: Identifiable, Codable, Hashable {
    var id: UUID
    var categoryID: UUID
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var title: String

    init(
        id: UUID = UUID(),
        categoryID: UUID,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        title: String = ""
    ) {
        self.id = id
        self.categoryID = categoryID
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.title = title
    }

    var startTotalMinutes: Int {
        startHour * 60 + startMinute
    }

    var endTotalMinutes: Int {
        endHour * 60 + endMinute
    }

    var durationMinutes: Int {
        endTotalMinutes - startTotalMinutes
    }

    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }

    var startTimeString: String {
        String(format: "%d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%d:%02d", endHour, endMinute)
    }

    var timeRangeString: String {
        "\(startTimeString) - \(endTimeString)"
    }

    var isOvertime: Bool {
        // Overtime is work after 17:30 — determined by category name at the view model level
        false
    }
}
