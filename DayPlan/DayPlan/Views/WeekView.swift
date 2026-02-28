import SwiftUI

struct WeekView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var showingPasteTargets = false
    @State private var pasteTargetDates: Set<Date> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Weekly overtime summary
                weekSummaryCard

                // Days
                ForEach(viewModel.weekDates, id: \.self) { date in
                    NavigationLink(destination: DayDetailView(viewModel: viewModel, date: date)) {
                        dayRow(for: date)
                    }
                    .buttonStyle(.plain)

                    if date != viewModel.weekDates.last {
                        Divider()
                            .padding(.horizontal)
                    }
                }

                // Category legend
                categoryLegend
                    .padding(.top, 12)
            }
        }
        .navigationTitle("DayPlan")
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    viewModel.goToPreviousWeek()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .principal) {
                Button {
                    viewModel.goToToday()
                } label: {
                    Text(viewModel.weekRangeString)
                        .font(.subheadline.bold())
                }
                .buttonStyle(.plain)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.goToNextWeek()
                } label: {
                    Image(systemName: "chevron.right")
                }

                if viewModel.copiedDaySchedule != nil {
                    Button {
                        showingPasteTargets = true
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPasteTargets) {
            pasteTargetSheet
        }
    }

    // MARK: - Week Summary

    private var weekSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("今週の残業")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f 時間", viewModel.weeklyOvertimeHours()))
                    .font(.title2.bold())
                    .foregroundColor(viewModel.weeklyOvertimeHours() > 0 ? .red : .primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("残業目安")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let overtime = viewModel.weeklyOvertimeHours()
                if overtime <= 5 {
                    Text("余裕あり")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                } else if overtime <= 10 {
                    Text("やや多い")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                } else {
                    Text("早めに帰ろう!")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Day Row

    private func dayRow(for date: Date) -> some View {
        let schedule = viewModel.schedule(for: date)
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        return HStack(spacing: 12) {
            // Day label
            VStack(spacing: 2) {
                Text(dayOfWeekString(date))
                    .font(.caption2)
                    .foregroundColor(isWeekend(date) ? .red : .secondary)

                Text(dayNumberString(date))
                    .font(.title3.bold())
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())
            }
            .frame(width: 40)

            // Time bar
            VStack(alignment: .leading, spacing: 2) {
                TimeBarView(schedule: schedule, categories: viewModel.categories, compact: true)

                HStack {
                    if schedule.overtimeHours(categories: viewModel.categories) > 0 {
                        Text(String(format: "残業 %.1fh", schedule.overtimeHours(categories: viewModel.categories)))
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }

                    Text(String(format: "空き %.1fh", schedule.freeTimeHours))
                        .font(.system(size: 9))
                        .foregroundColor(.green)

                    let todoCount = schedule.todos.filter { !$0.isEmpty }.count
                    if todoCount > 0 {
                        Text("Todo \(todoCount)/3")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
    }

    // MARK: - Category Legend

    private var categoryLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("カテゴリ")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 6) {
                ForEach(viewModel.categories) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Paste Target Sheet

    private var pasteTargetSheet: some View {
        NavigationStack {
            List {
                Section("ペースト先の日を選択") {
                    ForEach(viewModel.weekDates, id: \.self) { date in
                        let schedule = viewModel.schedule(for: date)

                        Button {
                            if pasteTargetDates.contains(date) {
                                pasteTargetDates.remove(date)
                            } else {
                                pasteTargetDates.insert(date)
                            }
                        } label: {
                            HStack {
                                Image(systemName: pasteTargetDates.contains(date) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(pasteTargetDates.contains(date) ? .blue : .secondary)

                                Text(schedule.dateString)
                                    .foregroundColor(.primary)

                                Spacer()

                                if !schedule.timeBlocks.isEmpty {
                                    Text("\(schedule.timeBlocks.count)件")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("スケジュールをペースト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingPasteTargets = false
                        pasteTargetDates = []
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ペースト") {
                        viewModel.pasteSchedule(to: Array(pasteTargetDates))
                        showingPasteTargets = false
                        pasteTargetDates = []
                    }
                    .disabled(pasteTargetDates.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helpers

    private func dayOfWeekString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dayNumberString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
}
