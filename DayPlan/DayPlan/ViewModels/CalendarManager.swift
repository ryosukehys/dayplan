import EventKit
import SwiftUI

@Observable
class CalendarManager {
    var calendarEvents: [EKEvent] = []
    var availableCalendars: [EKCalendar] = []
    var selectedCalendarIDs: Set<String> = []
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var isLoading = false
    var errorMessage: String?
    var isEnabled = false

    // Calendar used for exporting time blocks
    var exportCalendarID: String?

    @ObservationIgnored
    private var _eventStore: EKEventStore?

    private var eventStore: EKEventStore {
        if _eventStore == nil {
            _eventStore = EKEventStore()
        }
        return _eventStore!
    }

    private let selectedCalendarsKey = "calendarManager_selectedCalendars"
    private let exportCalendarKey = "calendarManager_exportCalendar"
    private let enabledKey = "calendarManager_enabled"

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        if let saved = UserDefaults.standard.array(forKey: selectedCalendarsKey) as? [String] {
            selectedCalendarIDs = Set(saved)
        }
        exportCalendarID = UserDefaults.standard.string(forKey: exportCalendarKey)
    }

    // MARK: - Authorization

    var hasAccess: Bool {
        authorizationStatus == .fullAccess
    }

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if hasAccess {
            loadCalendars()
        }
    }

    func requestAccess() {
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            openSettings()
            return
        }
        isLoading = true
        errorMessage = nil
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if granted {
                    self.isEnabled = true
                    UserDefaults.standard.set(true, forKey: self.enabledKey)
                    self.loadCalendars()
                } else if let error {
                    self.errorMessage = error.localizedDescription
                } else if self.authorizationStatus == .denied {
                    self.openSettings()
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Calendar Management

    func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event).sorted { $0.title < $1.title }
        // If no calendars selected yet, select all by default
        if selectedCalendarIDs.isEmpty {
            selectedCalendarIDs = Set(availableCalendars.map { $0.calendarIdentifier })
            saveSelectedCalendars()
        }
    }

    func toggleCalendar(_ calendarID: String) {
        if selectedCalendarIDs.contains(calendarID) {
            selectedCalendarIDs.remove(calendarID)
        } else {
            selectedCalendarIDs.insert(calendarID)
        }
        saveSelectedCalendars()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)
    }

    func setExportCalendar(_ calendarID: String?) {
        exportCalendarID = calendarID
        if let id = calendarID {
            UserDefaults.standard.set(id, forKey: exportCalendarKey)
        } else {
            UserDefaults.standard.removeObject(forKey: exportCalendarKey)
        }
    }

    private func saveSelectedCalendars() {
        UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: selectedCalendarsKey)
    }

    // MARK: - Fetch Events

    func fetchEvents(for date: Date) -> [EKEvent] {
        guard hasAccess, isEnabled else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let calendars = availableCalendars.filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard hasAccess, isEnabled else { return [] }
        let calendars = availableCalendars.filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Export Time Block to Calendar

    func exportTimeBlock(_ block: TimeBlock, date: Date, categoryName: String) -> String? {
        guard hasAccess else { return nil }

        let event = EKEvent(eventStore: eventStore)
        event.title = block.title.isEmpty ? categoryName : block.title

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        event.startDate = calendar.date(byAdding: .minute, value: block.startTotalMinutes, to: startOfDay)
        event.endDate = calendar.date(byAdding: .minute, value: block.endTotalMinutes, to: startOfDay)

        if let exportID = exportCalendarID,
           let cal = availableCalendars.first(where: { $0.calendarIdentifier == exportID }) {
            event.calendar = cal
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }

        event.notes = "DayPlanから追加"

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteEvent(identifier: String) {
        guard hasAccess else { return }
        if let event = eventStore.event(withIdentifier: identifier) {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Helpers

    /// Convert EKEvent to start/end minutes since midnight for timeline display
    static func eventMinutes(_ event: EKEvent, on date: Date) -> (start: Int, end: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let startMinutes: Int
        if event.startDate < startOfDay {
            startMinutes = 0
        } else {
            startMinutes = Int(event.startDate.timeIntervalSince(startOfDay) / 60)
        }

        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let endMinutes: Int
        if event.endDate > endOfDay {
            endMinutes = 1440
        } else {
            endMinutes = Int(event.endDate.timeIntervalSince(startOfDay) / 60)
        }

        return (start: min(startMinutes, 1440), end: min(endMinutes, 1440))
    }

    static func eventTimeString(_ event: EKEvent) -> String {
        if event.isAllDay {
            return "終日"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}
