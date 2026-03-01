import SwiftUI

@Observable
class ScheduleViewModel {
    var categories: [ScheduleCategory] = []
    var selectedDate: Date = Date()
    var copiedDaySchedule: DaySchedule?
    var currentWeekStart: Date = Date()
    var currentMonthDate: Date = Date()

    // Training logs
    var trainingLogs: [TrainingLog] = []

    // Quotes
    var quotes: [Quote] = []

    private let categoriesKey = "savedCategories"
    private let schedulesKey = "savedSchedules"
    private let trainingKey = "savedTraining"
    private let quotesKey = "savedQuotes"

    // In-memory cache of loaded schedules keyed by "yyyy-MM-dd"
    private var scheduleCache: [String: DaySchedule] = [:]

    init() {
        loadCategories()
        loadQuotes()
        updateCurrentWeekStart()
        loadMonthSchedules(for: selectedDate)
    }

    // MARK: - Date Helpers

    private var calendar: Calendar { Calendar.current }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    // MARK: - Week Navigation

    func updateCurrentWeekStart() {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday - 2 + 7) % 7
        currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate)!
        currentWeekStart = calendar.startOfDay(for: currentWeekStart)
    }

    func goToNextWeek() {
        selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
        updateCurrentWeekStart()
        loadMonthSchedules(for: selectedDate)
    }

    func goToPreviousWeek() {
        selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
        updateCurrentWeekStart()
        loadMonthSchedules(for: selectedDate)
    }

    func goToToday() {
        selectedDate = Date()
        updateCurrentWeekStart()
        currentMonthDate = Date()
        loadMonthSchedules(for: selectedDate)
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        updateCurrentWeekStart()
        loadMonthSchedules(for: selectedDate)
    }

    var weekDates: [Date] {
        (0..<7).map { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)!
        }
    }

    var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: weekDates.last!)
        return "\(start) 〜 \(end)"
    }

    // MARK: - Month Navigation

    func goToNextMonth() {
        currentMonthDate = calendar.date(byAdding: .month, value: 1, to: currentMonthDate)!
        loadMonthSchedules(for: currentMonthDate)
    }

    func goToPreviousMonth() {
        currentMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonthDate)!
        loadMonthSchedules(for: currentMonthDate)
    }

    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonthDate)
    }

    var monthDates: [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: currentMonthDate)
        guard let firstOfMonth = calendar.date(from: comps) else { return [] }

        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        // Monday=0 offset
        let leadingBlanks = (firstWeekday - 2 + 7) % 7

        var dates: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }
        // Pad trailing to fill last row
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        return dates
    }

    // MARK: - Schedule Management

    func schedule(for date: Date) -> DaySchedule {
        let key = dateKey(for: date)
        if let cached = scheduleCache[key] {
            return cached
        }
        // Try loading from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "\(schedulesKey)_\(key)"),
           let saved = try? JSONDecoder().decode(DaySchedule.self, from: data) {
            scheduleCache[key] = saved
            return saved
        }
        return DaySchedule(date: date)
    }

    func updateSchedule(_ schedule: DaySchedule) {
        let key = dateKey(for: schedule.date)
        scheduleCache[key] = schedule
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: "\(schedulesKey)_\(key)")
        }
    }

    func addTimeBlock(to date: Date, block: TimeBlock) {
        var daySchedule = schedule(for: date)
        daySchedule.timeBlocks.append(block)
        updateSchedule(daySchedule)
    }

    func removeTimeBlock(from date: Date, blockID: UUID) {
        var daySchedule = schedule(for: date)
        daySchedule.timeBlocks.removeAll { $0.id == blockID }
        updateSchedule(daySchedule)
    }

    func updateTimeBlock(for date: Date, block: TimeBlock) {
        var daySchedule = schedule(for: date)
        if let index = daySchedule.timeBlocks.firstIndex(where: { $0.id == block.id }) {
            daySchedule.timeBlocks[index] = block
            updateSchedule(daySchedule)
        }
    }

    // MARK: - Default Weekday Schedule

    func addDefaultWorkSchedule(to date: Date) {
        guard let workCategory = categories.first(where: { $0.name == "仕事" }) else { return }
        let workBlock = TimeBlock(
            categoryID: workCategory.id,
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 30,
            title: "仕事"
        )
        addTimeBlock(to: date, block: workBlock)
    }

    // MARK: - Copy & Paste

    func copySchedule(from date: Date) {
        copiedDaySchedule = schedule(for: date)
    }

    func pasteSchedule(to date: Date) {
        guard let copied = copiedDaySchedule else { return }
        var newSchedule = DaySchedule(date: date)
        newSchedule.timeBlocks = copied.timeBlocks.map { block in
            TimeBlock(
                categoryID: block.categoryID,
                startHour: block.startHour, startMinute: block.startMinute,
                endHour: block.endHour, endMinute: block.endMinute,
                title: block.title
            )
        }
        newSchedule.todos = copied.todos
        newSchedule.todoCompleted = copied.todoCompleted
        updateSchedule(newSchedule)
    }

    func pasteSchedule(to dates: [Date]) {
        for date in dates {
            pasteSchedule(to: date)
        }
    }

    // MARK: - Todos

    func updateTodo(for date: Date, index: Int, text: String) {
        var daySchedule = schedule(for: date)
        while daySchedule.todos.count <= index {
            daySchedule.todos.append("")
        }
        daySchedule.todos[index] = text
        updateSchedule(daySchedule)
    }

    func toggleTodoCompleted(for date: Date, index: Int) {
        var daySchedule = schedule(for: date)
        while daySchedule.todoCompleted.count <= index {
            daySchedule.todoCompleted.append(false)
        }
        daySchedule.todoCompleted[index].toggle()
        updateSchedule(daySchedule)
    }

    // MARK: - Overtime (Planned / Actual)

    func updatePlannedOvertime(for date: Date, minutes: Int) {
        var daySchedule = schedule(for: date)
        daySchedule.plannedOvertimeMinutes = minutes
        updateSchedule(daySchedule)
    }

    func updateActualOvertime(for date: Date, minutes: Int) {
        var daySchedule = schedule(for: date)
        daySchedule.actualOvertimeMinutes = minutes
        updateSchedule(daySchedule)
    }

    func weeklyPlannedOvertimeHours() -> Double {
        weekDates.reduce(0.0) { $0 + schedule(for: $1).plannedOvertimeHours }
    }

    func weeklyActualOvertimeHours() -> Double {
        weekDates.reduce(0.0) { $0 + schedule(for: $1).actualOvertimeHours }
    }

    func weeklyOvertimeMinutes() -> Int {
        weekDates.reduce(0) { $0 + schedule(for: $1).overtimeMinutes(categories: categories) }
    }

    func weeklyOvertimeHours() -> Double {
        Double(weeklyOvertimeMinutes()) / 60.0
    }

    func monthlySchedules(for date: Date) -> [DaySchedule] {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        return range.compactMap { day in
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { return nil }
            let s = schedule(for: d)
            return s.timeBlocks.isEmpty && s.plannedOvertimeMinutes == 0 && s.actualOvertimeMinutes == 0 ? nil : s
        }
    }

    func monthlyOvertimeHours(for date: Date) -> (planned: Double, actual: Double) {
        let schedules = monthlySchedules(for: date)
        let planned = schedules.reduce(0.0) { $0 + $1.plannedOvertimeHours }
        let actual = schedules.reduce(0.0) { $0 + $1.actualOvertimeHours }
        return (planned, actual)
    }

    // MARK: - Statistics

    struct CategoryStat: Identifiable {
        let id: UUID
        let category: ScheduleCategory
        let totalMinutes: Int
        var totalHours: Double { Double(totalMinutes) / 60.0 }
    }

    func weeklyStats() -> [CategoryStat] {
        var minutesByCategory: [UUID: Int] = [:]
        for date in weekDates {
            let s = schedule(for: date)
            for block in s.timeBlocks {
                minutesByCategory[block.categoryID, default: 0] += block.durationMinutes
            }
        }
        return categories.compactMap { cat in
            guard let minutes = minutesByCategory[cat.id], minutes > 0 else { return nil }
            return CategoryStat(id: cat.id, category: cat, totalMinutes: minutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    func monthlyStats(for date: Date) -> [CategoryStat] {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        var minutesByCategory: [UUID: Int] = [:]
        for day in range {
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
            let s = schedule(for: d)
            for block in s.timeBlocks {
                minutesByCategory[block.categoryID, default: 0] += block.durationMinutes
            }
        }
        return categories.compactMap { cat in
            guard let minutes = minutesByCategory[cat.id], minutes > 0 else { return nil }
            return CategoryStat(id: cat.id, category: cat, totalMinutes: minutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    // MARK: - Category Management

    func addCategory(_ category: ScheduleCategory) {
        categories.append(category)
        saveCategories()
    }

    func removeCategory(_ category: ScheduleCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    func updateCategory(_ category: ScheduleCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    func moveCategory(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        saveCategories()
    }

    func category(for id: UUID) -> ScheduleCategory? {
        categories.first { $0.id == id }
    }

    // MARK: - Training Log

    func trainingLog(for date: Date) -> TrainingLog {
        let key = dateKey(for: date)
        if let data = UserDefaults.standard.data(forKey: "\(trainingKey)_\(key)"),
           let saved = try? JSONDecoder().decode(TrainingLog.self, from: data) {
            return saved
        }
        return TrainingLog(date: date)
    }

    func updateTrainingLog(_ log: TrainingLog) {
        let key = dateKey(for: log.date)
        if let data = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(data, forKey: "\(trainingKey)_\(key)")
        }
    }

    func weeklyRunningDistance() -> Double {
        weekDates.reduce(0.0) { $0 + trainingLog(for: $1).runningDistanceKm }
    }

    func monthlyRunningDistance(for date: Date) -> Double {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return 0 }

        return range.reduce(0.0) { total, day in
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { return total }
            return total + trainingLog(for: d).runningDistanceKm
        }
    }

    func weeklyTrainingLogs() -> [TrainingLog] {
        weekDates.map { trainingLog(for: $0) }.filter { $0.hasContent }
    }

    // MARK: - Day Event

    func updateDayEvent(for date: Date, event: String) {
        var daySchedule = schedule(for: date)
        daySchedule.dayEvent = event
        updateSchedule(daySchedule)
    }

    // MARK: - Quotes

    var randomQuote: Quote? {
        guard !quotes.isEmpty else { return nil }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: selectedDate) ?? 0
        return quotes[dayOfYear % quotes.count]
    }

    func addQuote(_ quote: Quote) {
        quotes.append(quote)
        saveQuotes()
    }

    func removeQuote(_ quote: Quote) {
        quotes.removeAll { $0.id == quote.id }
        saveQuotes()
    }

    func updateQuote(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[index] = quote
            saveQuotes()
        }
    }

    private func saveQuotes() {
        if let data = try? JSONEncoder().encode(quotes) {
            UserDefaults.standard.set(data, forKey: quotesKey)
        }
    }

    private func loadQuotes() {
        if let data = UserDefaults.standard.data(forKey: quotesKey),
           let saved = try? JSONDecoder().decode([Quote].self, from: data) {
            quotes = saved
        } else {
            quotes = Quote.defaults
            saveQuotes()
        }
    }

    // MARK: - Persistence

    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: categoriesKey)
        }
    }

    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let saved = try? JSONDecoder().decode([ScheduleCategory].self, from: data) {
            categories = saved
        } else {
            categories = ScheduleCategory.defaults
            saveCategories()
        }
    }

    func loadMonthSchedules(for date: Date) {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return }

        for day in range {
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
            let key = dateKey(for: d)
            if scheduleCache[key] == nil {
                if let data = UserDefaults.standard.data(forKey: "\(schedulesKey)_\(key)"),
                   let saved = try? JSONDecoder().decode(DaySchedule.self, from: data) {
                    scheduleCache[key] = saved
                }
            }
        }
    }
}
