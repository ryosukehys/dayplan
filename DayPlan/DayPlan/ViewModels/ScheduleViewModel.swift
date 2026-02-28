import SwiftUI

@Observable
class ScheduleViewModel {
    var categories: [ScheduleCategory] = []
    var weekSchedules: [DaySchedule] = []
    var selectedDate: Date = Date()
    var copiedDaySchedule: DaySchedule?
    var currentWeekStart: Date = Date()

    private let categoriesKey = "savedCategories"
    private let schedulesKey = "savedSchedules"

    init() {
        loadCategories()
        updateCurrentWeekStart()
        loadSchedules()
    }

    // MARK: - Week Navigation

    func updateCurrentWeekStart() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        // Sunday = 1, Monday = 2, so Monday offset is (weekday - 2 + 7) % 7
        let daysFromMonday = (weekday - 2 + 7) % 7
        currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate)!
        currentWeekStart = calendar.startOfDay(for: currentWeekStart)
    }

    func goToNextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
        updateCurrentWeekStart()
        loadSchedules()
    }

    func goToPreviousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
        updateCurrentWeekStart()
        loadSchedules()
    }

    func goToToday() {
        selectedDate = Date()
        updateCurrentWeekStart()
        loadSchedules()
    }

    var weekDates: [Date] {
        (0..<7).map { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStart)!
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

    // MARK: - Schedule Management

    func schedule(for date: Date) -> DaySchedule {
        let calendar = Calendar.current
        if let existing = weekSchedules.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return existing
        }
        return DaySchedule(date: date)
    }

    func updateSchedule(_ schedule: DaySchedule) {
        let calendar = Calendar.current
        if let index = weekSchedules.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: schedule.date) }) {
            weekSchedules[index] = schedule
        } else {
            weekSchedules.append(schedule)
        }
        saveSchedules()
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
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 30,
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
                startHour: block.startHour,
                startMinute: block.startMinute,
                endHour: block.endHour,
                endMinute: block.endMinute,
                title: block.title
            )
        }
        newSchedule.todos = copied.todos
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

    // MARK: - Overtime Calculation

    func weeklyOvertimeMinutes() -> Int {
        weekSchedules.reduce(0) { $0 + $1.overtimeMinutes(categories: categories) }
    }

    func weeklyOvertimeHours() -> Double {
        Double(weeklyOvertimeMinutes()) / 60.0
    }

    func monthlyOvertimeHours() -> Double {
        // Sum all schedules for the current month
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: selectedDate)
        let currentYear = calendar.component(.year, from: selectedDate)

        return weekSchedules
            .filter {
                calendar.component(.month, from: $0.date) == currentMonth &&
                calendar.component(.year, from: $0.date) == currentYear
            }
            .reduce(0.0) { $0 + $1.overtimeHours(categories: categories) }
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

    func category(for id: UUID) -> ScheduleCategory? {
        categories.first { $0.id == id }
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

    private func saveSchedules() {
        if let data = try? JSONEncoder().encode(weekSchedules) {
            let key = scheduleKeyForWeek()
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadSchedules() {
        let key = scheduleKeyForWeek()
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            weekSchedules = saved
        } else {
            weekSchedules = []
        }
    }

    private func scheduleKeyForWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(schedulesKey)_\(formatter.string(from: currentWeekStart))"
    }
}
