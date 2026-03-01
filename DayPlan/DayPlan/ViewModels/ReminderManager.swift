import EventKit
import SwiftUI

@Observable
class ReminderManager {
    var reminders: [EKReminder] = []
    var reminderLists: [EKCalendar] = []
    var selectedListID: String?
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var isLoading = false

    private let eventStore = EKEventStore()

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        if hasAccess {
            fetchLists()
            fetchReminders()
        }
    }

    func requestAccess() {
        eventStore.requestFullAccessToReminders { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
                if granted {
                    self.fetchLists()
                    self.fetchReminders()
                }
            }
        }
    }

    func fetchLists() {
        reminderLists = eventStore.calendars(for: .reminder)
    }

    func fetchReminders() {
        isLoading = true
        let calendars: [EKCalendar]?
        if let selectedID = selectedListID,
           let cal = reminderLists.first(where: { $0.calendarIdentifier == selectedID }) {
            calendars = [cal]
        } else {
            calendars = nil
        }

        let predicate = eventStore.predicateForReminders(in: calendars)
        eventStore.fetchReminders(matching: predicate) { fetched in
            DispatchQueue.main.async {
                self.reminders = (fetched ?? []).sorted {
                    if $0.isCompleted != $1.isCompleted {
                        return !$0.isCompleted
                    }
                    if let d0 = $0.dueDateComponents, let d1 = $1.dueDateComponents {
                        let date0 = Calendar.current.date(from: d0) ?? .distantFuture
                        let date1 = Calendar.current.date(from: d1) ?? .distantFuture
                        return date0 < date1
                    }
                    return ($0.title ?? "") < ($1.title ?? "")
                }
                self.isLoading = false
            }
        }
    }

    func toggleCompletion(_ reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted
        if reminder.isCompleted {
            reminder.completionDate = Date()
        }
        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders()
        } catch {
            reminder.isCompleted = !reminder.isCompleted
        }
    }

    var hasAccess: Bool {
        authorizationStatus == .fullAccess || authorizationStatus == .authorized
    }

    var incompleteCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }
}
