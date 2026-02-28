import Foundation

struct DaySchedule: Identifiable, Codable {
    var id: UUID
    var date: Date
    var timeBlocks: [TimeBlock]
    var todos: [String]

    init(id: UUID = UUID(), date: Date, timeBlocks: [TimeBlock] = [], todos: [String] = ["", "", ""]) {
        self.id = id
        self.date = date
        self.timeBlocks = timeBlocks
        self.todos = todos
    }

    var sortedBlocks: [TimeBlock] {
        timeBlocks.sorted { $0.startTotalMinutes < $1.startTotalMinutes }
    }

    var totalScheduledMinutes: Int {
        timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var freeTimeMinutes: Int {
        // Assuming a 24-hour day (1440 minutes)
        1440 - totalScheduledMinutes
    }

    var freeTimeHours: Double {
        Double(freeTimeMinutes) / 60.0
    }

    func overtimeMinutes(categories: [ScheduleCategory]) -> Int {
        timeBlocks.filter { block in
            guard let cat = categories.first(where: { $0.id == block.categoryID }) else { return false }
            return cat.name == "残業"
        }.reduce(0) { $0 + $1.durationMinutes }
    }

    func overtimeHours(categories: [ScheduleCategory]) -> Double {
        Double(overtimeMinutes(categories: categories)) / 60.0
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: date)
    }

    var isWeekday: Bool {
        dayOfWeek >= 2 && dayOfWeek <= 6
    }
}
