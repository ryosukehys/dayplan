import SwiftUI
import EventKit

struct StatisticsView: View {
    @Bindable var viewModel: ScheduleViewModel
    @Binding var selectedTab: StatsTab

    @State private var selectedPeriod: StatsPeriod = .weekly
    @State private var reminderManager = ReminderManager()

    enum StatsTab: String, CaseIterable {
        case statistics = "統計"
        case reminders = "TODO"
    }

    enum StatsPeriod: String, CaseIterable {
        case weekly = "週間"
        case monthly = "月間"
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedTab == .statistics {
                statisticsContent
            } else {
                remindersContent
            }
        }
        .navigationTitle(selectedTab == .statistics ? "統計" : "リマインダー")
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > vertical else { return }
                    if selectedTab == .statistics {
                        if value.translation.width < -60 {
                            withAnimation {
                                if selectedPeriod == .weekly {
                                    viewModel.goToNextWeek()
                                } else {
                                    viewModel.goToNextMonth()
                                }
                            }
                        } else if value.translation.width > 60 {
                            withAnimation {
                                if selectedPeriod == .weekly {
                                    viewModel.goToPreviousWeek()
                                } else {
                                    viewModel.goToPreviousMonth()
                                }
                            }
                        }
                    }
                }
        )
    }

    // MARK: - Statistics Content

    private var statisticsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                periodNavigation
                overtimeSummaryCard
                categoryBreakdown
                categoryDetailList
            }
            .padding(.vertical)
        }
    }

    // MARK: - Reminders Content

    private var remindersContent: some View {
        Group {
            if !reminderManager.hasAccess {
                reminderAccessRequest
            } else if reminderManager.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                remindersList
            }
        }
        .onAppear {
            reminderManager.checkAuthorization()
        }
    }

    private var reminderAccessRequest: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("リマインダーへのアクセス")
                .font(.headline)

            if reminderManager.authorizationStatus == .denied || reminderManager.authorizationStatus == .restricted {
                Text("リマインダーへのアクセスが拒否されています。\n設定アプリから許可してください。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    reminderManager.requestAccess()
                } label: {
                    Text("設定を開く")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            } else {
                Text("iPhoneのリマインダーを表示・完了するには\nアクセス許可が必要です。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if reminderManager.isLoading {
                    ProgressView()
                        .padding(.vertical, 12)
                } else {
                    Button {
                        reminderManager.requestAccess()
                    } label: {
                        Text("アクセスを許可する")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }

            if let error = reminderManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Text("状態: \(reminderManager.authorizationStatus.statusText)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            reminderManager.checkAuthorization()
        }
    }

    private var remindersList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // List picker
                if reminderManager.reminderLists.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            listFilterChip(id: nil, name: "すべて")

                            ForEach(reminderManager.reminderLists, id: \.calendarIdentifier) { list in
                                listFilterChip(id: list.calendarIdentifier, name: list.title)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Summary
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(reminderManager.incompleteCount)")
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                        Text("未完了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                    VStack(spacing: 2) {
                        Text("\(reminderManager.reminders.count - reminderManager.incompleteCount)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("完了済み")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Reminder items
                if reminderManager.reminders.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("リマインダーがありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    let incomplete = reminderManager.reminders.filter { !$0.isCompleted }
                    if !incomplete.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("未完了 (\(incomplete.count))")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 4)

                            ForEach(incomplete, id: \.calendarItemIdentifier) { reminder in
                                reminderRow(reminder)
                            }
                        }
                    }

                    let completed = reminderManager.reminders.filter { $0.isCompleted }
                    if !completed.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("完了済み (\(completed.count))")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 4)

                            ForEach(completed, id: \.calendarItemIdentifier) { reminder in
                                reminderRow(reminder)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            reminderManager.fetchReminders()
        }
    }

    private func listFilterChip(id: String?, name: String) -> some View {
        let isSelected = (id == nil && reminderManager.selectedListID == nil) ||
            (id != nil && reminderManager.selectedListID == id)

        return Button {
            reminderManager.selectedListID = id
            reminderManager.fetchReminders()
        } label: {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }

    private func reminderRow(_ reminder: EKReminder) -> some View {
        Button {
            reminderManager.toggleCompletion(reminder)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(reminder.isCompleted ? .green : Color(.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title ?? "無題")
                        .font(.subheadline)
                        .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                        .strikethrough(reminder.isCompleted)
                        .lineLimit(2)

                    if let dueDate = reminder.dueDateComponents,
                       let date = Calendar.current.date(from: dueDate) {
                        Text(dueDateString(date))
                            .font(.caption)
                            .foregroundColor(isOverdue(date) && !reminder.isCompleted ? .red : .secondary)
                    }

                    if let notes = reminder.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let calendar = reminder.calendar {
                    Circle()
                        .fill(Color(cgColor: calendar.cgColor))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func dueDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else if calendar.isDateInTomorrow(date) {
            return "明日"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Period Navigation

    private var periodNavigation: some View {
        HStack {
            Button {
                withAnimation {
                    if selectedPeriod == .weekly {
                        viewModel.goToPreviousWeek()
                    } else {
                        viewModel.goToPreviousMonth()
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(selectedPeriod == .weekly ? viewModel.weekRangeString : viewModel.currentMonthString)
                .font(.subheadline.bold())

            Spacer()

            Button {
                withAnimation {
                    if selectedPeriod == .weekly {
                        viewModel.goToNextWeek()
                    } else {
                        viewModel.goToNextMonth()
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Stats Data

    private var stats: [ScheduleViewModel.CategoryStat] {
        if selectedPeriod == .weekly {
            return viewModel.weeklyStats()
        } else {
            return viewModel.monthlyStats(for: viewModel.currentMonthDate)
        }
    }

    private var totalMinutes: Int {
        stats.reduce(0) { $0 + $1.totalMinutes }
    }

    private var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    // MARK: - Overtime Summary

    private var overtimeSummaryCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("残業時間")
                    .font(.subheadline.bold())
                Spacer()
            }

            if selectedPeriod == .weekly {
                HStack(spacing: 12) {
                    overtimeStatBox(
                        label: "予定",
                        hours: viewModel.weeklyPlannedOvertimeHours(),
                        color: .orange
                    )
                    overtimeStatBox(
                        label: "実績",
                        hours: viewModel.weeklyActualOvertimeHours(),
                        color: .red
                    )

                    let catOvertime = viewModel.weeklyOvertimeHours()
                    overtimeStatBox(
                        label: "カテゴリ",
                        hours: catOvertime,
                        color: .purple
                    )
                }
            } else {
                let overtime = viewModel.monthlyOvertimeHours(for: viewModel.currentMonthDate)
                HStack(spacing: 12) {
                    overtimeStatBox(label: "予定", hours: overtime.planned, color: .orange)
                    overtimeStatBox(label: "実績", hours: overtime.actual, color: .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func overtimeStatBox(label: String, hours: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatHoursMinutes(hours))
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("カテゴリ別時間配分")
                    .font(.subheadline.bold())
                Spacer()
                Text("合計 \(formatHoursMinutesJP(totalHours))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stacked horizontal bar
            if !stats.isEmpty {
                GeometryReader { geometry in
                    let barWidth = geometry.size.width

                    HStack(spacing: 0) {
                        ForEach(stats) { stat in
                            let fraction = totalMinutes > 0 ? CGFloat(stat.totalMinutes) / CGFloat(totalMinutes) : 0

                            Rectangle()
                                .fill(stat.category.color)
                                .frame(width: max(fraction * barWidth, 2))
                        }
                    }
                    .frame(height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(height: 32)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 32)
                    .overlay {
                        Text("データなし")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Category Detail List

    private var categoryDetailList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ詳細")
                .font(.subheadline.bold())
                .padding(.horizontal)

            if stats.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("この期間のデータがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(stats) { stat in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(stat.category.color)
                            .frame(width: 12, height: 12)

                        Text(stat.category.name)
                            .font(.subheadline)

                        Spacer()

                        // Bar
                        let maxMinutes = stats.first?.totalMinutes ?? 1
                        GeometryReader { geometry in
                            let fraction = CGFloat(stat.totalMinutes) / CGFloat(maxMinutes)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stat.category.color.opacity(0.3))
                                .frame(width: fraction * geometry.size.width, height: 16)
                        }
                        .frame(width: 80, height: 16)

                        Text(formatHoursMinutes(stat.totalHours))
                            .font(.subheadline.bold())
                            .frame(width: 50, alignment: .trailing)

                        if totalMinutes > 0 {
                            Text(String(format: "%.0f%%", Double(stat.totalMinutes) / Double(totalMinutes) * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

extension EKAuthorizationStatus {
    var statusText: String {
        switch self {
        case .notDetermined: return "未確認"
        case .restricted: return "制限あり"
        case .denied: return "拒否"
        case .fullAccess: return "フルアクセス"
        case .writeOnly: return "書き込みのみ"
        @unknown default: return "不明"
        }
    }
}
