import Foundation

struct DaySchedule: Identifiable, Codable {
    var id: UUID
    var date: Date
    var timeBlocks: [TimeBlock]
    var todos: [String]
    var todoCompleted: [Bool]
    var trackingValues: [String: TrackingValue]
    var dayEvent: String

    init(
        id: UUID = UUID(),
        date: Date,
        timeBlocks: [TimeBlock] = [],
        todos: [String] = ["", "", ""],
        todoCompleted: [Bool] = [false, false, false],
        trackingValues: [String: TrackingValue] = [:],
        dayEvent: String = ""
    ) {
        self.id = id
        self.date = date
        self.timeBlocks = timeBlocks
        self.todos = todos
        self.todoCompleted = todoCompleted
        self.trackingValues = trackingValues
        self.dayEvent = dayEvent
    }

    enum CodingKeys: String, CodingKey {
        case id, date, timeBlocks, todos, todoCompleted
        case plannedOvertimeMinutes, actualOvertimeMinutes
        case trackingValues, dayEvent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        timeBlocks = try container.decode([TimeBlock].self, forKey: .timeBlocks)
        todos = try container.decode([String].self, forKey: .todos)
        todoCompleted = try container.decodeIfPresent([Bool].self, forKey: .todoCompleted) ?? [false, false, false]
        dayEvent = try container.decode(String.self, forKey: .dayEvent)

        // New format
        var values = try container.decodeIfPresent([String: TrackingValue].self, forKey: .trackingValues) ?? [:]

        // Migrate old overtime fields
        let oldPlanned = try container.decodeIfPresent(Int.self, forKey: .plannedOvertimeMinutes) ?? 0
        let oldActual = try container.decodeIfPresent(Int.self, forKey: .actualOvertimeMinutes) ?? 0
        let overtimeKey = TrackingItem.defaultOvertimeID.uuidString
        if values[overtimeKey] == nil && (oldPlanned > 0 || oldActual > 0) {
            values[overtimeKey] = TrackingValue(planned: oldPlanned, actual: oldActual)
        }
        trackingValues = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(timeBlocks, forKey: .timeBlocks)
        try container.encode(todos, forKey: .todos)
        try container.encode(todoCompleted, forKey: .todoCompleted)
        try container.encode(trackingValues, forKey: .trackingValues)
        try container.encode(dayEvent, forKey: .dayEvent)
    }

    // MARK: - Tracking Value Helpers

    func trackingValue(for itemID: UUID) -> TrackingValue {
        trackingValues[itemID.uuidString] ?? TrackingValue()
    }

    mutating func setTrackingValue(_ value: TrackingValue, for itemID: UUID) {
        trackingValues[itemID.uuidString] = value
    }

    var hasAnyTrackingData: Bool {
        trackingValues.values.contains { $0.hasData }
    }

    // MARK: - Computed Properties

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
