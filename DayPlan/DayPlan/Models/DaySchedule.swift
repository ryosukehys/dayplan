import Foundation

struct DaySchedule: Identifiable, Codable {
    var id: UUID
    var date: Date
    var timeBlocks: [TimeBlock]
    var todos: [String]
    var todoCompleted: [Bool]
    var plannedOvertimeMinutes: Int
    var actualOvertimeMinutes: Int
    var dayEvent: String

    init(
        id: UUID = UUID(),
        date: Date,
        timeBlocks: [TimeBlock] = [],
        todos: [String] = ["", "", ""],
        todoCompleted: [Bool] = [false, false, false],
        plannedOvertimeMinutes: Int = 0,
        actualOvertimeMinutes: Int = 0,
        dayEvent: String = ""
    ) {
        self.id = id
        self.date = date
        self.timeBlocks = timeBlocks
        self.todos = todos
        self.todoCompleted = todoCompleted
        self.plannedOvertimeMinutes = plannedOvertimeMinutes
        self.actualOvertimeMinutes = actualOvertimeMinutes
        self.dayEvent = dayEvent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        timeBlocks = try container.decode([TimeBlock].self, forKey: .timeBlocks)
        todos = try container.decode([String].self, forKey: .todos)
        todoCompleted = try container.decodeIfPresent([Bool].self, forKey: .todoCompleted) ?? [false, false, false]
        plannedOvertimeMinutes = try container.decode(Int.self, forKey: .plannedOvertimeMinutes)
        actualOvertimeMinutes = try container.decode(Int.self, forKey: .actualOvertimeMinutes)
        dayEvent = try container.decode(String.self, forKey: .dayEvent)
    }

    var sortedBlocks: [TimeBlock] {
        timeBlocks.sorted { $0.startTotalMinutes < $1.startTotalMinutes }
    }

    var totalScheduledMinutes: Int {
        timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var freeTimeMinutes: Int {
        max(0, 1440 - totalScheduledMinutes)
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

    var plannedOvertimeHours: Double {
        Double(plannedOvertimeMinutes) / 60.0
    }

    var actualOvertimeHours: Double {
        Double(actualOvertimeMinutes) / 60.0
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

    func minutesForCategory(_ categoryID: UUID) -> Int {
        timeBlocks.filter { $0.categoryID == categoryID }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func gapSlots() -> [(startMinute: Int, endMinute: Int)] {
        let sorted = sortedBlocks
        var gaps: [(Int, Int)] = []
        var current = 0

        for block in sorted {
            if block.startTotalMinutes > current {
                gaps.append((current, block.startTotalMinutes))
            }
            current = max(current, block.endTotalMinutes)
        }

        if current < 1440 {
            gaps.append((current, 1440))
        }

        return gaps
    }
}
