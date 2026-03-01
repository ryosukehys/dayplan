import EventKit
import SwiftUI

@Observable
class ReminderManager {
    var reminders: [EKReminder] = []
    var reminderLists: [EKCalendar] = []
    var selectedListID: String?
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private var _eventStore: EKEventStore?

    private var eventStore: EKEventStore {
        if _eventStore == nil {
            _eventStore = EKEventStore()
        }
        return _eventStore!
    }

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        if hasAccess {
            fetchLists()
            fetchReminders()
        }
    }

    func requestAccess() {
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            openSettings()
            return
        }
        isLoading = true
        errorMessage = nil
        eventStore.requestFullAccessToReminders { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
                if granted {
                    self.fetchLists()
                    self.fetchReminders()
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

    func fetchLists() {
        reminderLists = eventStore.calendars(for: .reminder)
    }

    func fetchReminders() {
        // 初回のみローディング表示（データがある場合はバックグラウンド更新）
        if reminders.isEmpty {
            isLoading = true
        }
        let calendars: [EKCalendar]?
        if let selectedID = selectedListID,
           let cal = reminderLists.first(where: { $0.calendarIdentifier == selectedID }) {
            calendars = [cal]
        } else {
            calendars = nil
        }

        let predicate = eventStore.predicateForReminders(in: calendars)
        eventStore.fetchReminders(matching: predicate) { [weak self] fetched in
            DispatchQueue.main.async {
                guard let self else { return }
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

    func addReminder(title: String, listID: String? = nil) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        if let listID,
           let calendar = reminderLists.first(where: { $0.calendarIdentifier == listID }) {
            reminder.calendar = calendar
        } else {
            reminder.calendar = eventStore.defaultCalendarForNewReminders()
        }
        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders()
        } catch {
            errorMessage = error.localizedDescription
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
        authorizationStatus == .fullAccess
    }

    var incompleteCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }
}
