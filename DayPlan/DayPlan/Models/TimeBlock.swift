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

func formatHoursMinutes(_ hours: Double) -> String {
    let totalMinutes = Int(round(hours * 60))
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    if m == 0 {
        return "\(h)h"
    } else if h == 0 {
        return "\(m)m"
    }
    return "\(h)h\(m)m"
}

func formatHoursMinutesJP(_ hours: Double) -> String {
    let totalMinutes = Int(round(hours * 60))
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    if m == 0 {
        return "\(h)時間"
    } else if h == 0 {
        return "\(m)分"
    }
    return "\(h)時間\(m)分"
}

func formatSignedHoursMinutesJP(_ hours: Double) -> String {
    let sign = hours >= 0 ? "+" : ""
    return "\(sign)\(formatHoursMinutesJP(abs(hours)))"
}
