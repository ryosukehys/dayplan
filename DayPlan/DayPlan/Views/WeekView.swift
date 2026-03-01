import SwiftUI

struct WeekView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var showingPasteTargets = false
    @State private var pasteTargetDates: Set<Date> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Quote of the week
                quoteCard

                weekSummaryCard

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

                categoryLegend
                    .padding(.top, 12)
            }
        }
        .navigationTitle("DayPlan")
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    withAnimation { viewModel.goToPreviousWeek() }
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
                    withAnimation { viewModel.goToNextWeek() }
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > vertical else { return }
                    if value.translation.width < -60 {
                        withAnimation { viewModel.goToNextWeek() }
                    } else if value.translation.width > 60 {
                        withAnimation { viewModel.goToPreviousWeek() }
                    }
                }
        )
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        Group {
            if let quote = viewModel.randomQuote {
                VStack(alignment: .leading, spacing: 6) {
                    Text(quote.text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Spacer()
                        Text("- \(quote.author)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Week Summary

    private var weekSummaryCard: some View {
        VStack(spacing: 8) {
            if !viewModel.trackingItems.isEmpty {
                HStack {
                    Text("今週の記録")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                }

                ForEach(viewModel.trackingItems) { item in
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(item.color)
                            Text(item.name)
                                .font(.caption.bold())
                        }
                        .frame(width: 90, alignment: .leading)

                        HStack(spacing: 4) {
                            Text("予定")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text(formatHoursMinutes(viewModel.weeklyTrackingPlanned(for: item.id)))
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }

                        HStack(spacing: 4) {
                            Text("実績")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text(formatHoursMinutes(viewModel.weeklyTrackingActual(for: item.id)))
                                .font(.caption.bold())
                                .foregroundColor(item.color)
                        }

                        Spacer()
                    }
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

            VStack(alignment: .leading, spacing: 2) {
                if !schedule.dayEvent.isEmpty {
                    Text(schedule.dayEvent)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }

                TimeBarView(schedule: schedule, categories: viewModel.categories, compact: true, showCurrentTime: isToday)

                HStack {
                    if schedule.overtimeHours(categories: viewModel.categories) > 0 {
                        Text("残業 \(formatHoursMinutes(schedule.overtimeHours(categories: viewModel.categories)))")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }

                    Text("空き \(formatHoursMinutes(schedule.freeTimeHours))")
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
