import SwiftUI

struct MonthCalendarView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var selectedDay: Date?
    @State private var showingOvertimeEntry = false
    @State private var overtimeDate: Date = Date()

    private let weekdayLabels = ["月", "火", "水", "木", "金", "土", "日"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            calendarGrid
        }
        .navigationTitle("カレンダー")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { date in
            NavigationStack {
                DayDetailView(viewModel: viewModel, date: date)
            }
        }
        .sheet(isPresented: $showingOvertimeEntry) {
            NavigationStack {
                OvertimeEntryView(viewModel: viewModel, date: overtimeDate)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation { viewModel.goToPreviousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Button {
                viewModel.currentMonthDate = Date()
                viewModel.loadMonthSchedules(for: Date())
            } label: {
                Text(viewModel.currentMonthString)
                    .font(.title3.bold())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                withAnimation { viewModel.goToNextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(label == "土" ? .blue : label == "日" ? .red : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(viewModel.monthDates.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        dayCellView(for: date)
                    } else {
                        Color.clear
                            .frame(height: 90)
                    }
                }
            }
            .padding(.horizontal, 4)

            monthOvertimeSummary
                .padding()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation { viewModel.goToNextMonth() }
                    } else if value.translation.width > 50 {
                        withAnimation { viewModel.goToPreviousMonth() }
                    }
                }
        )
    }

    // MARK: - Day Cell

    private func dayCellView(for date: Date) -> some View {
        let schedule = viewModel.schedule(for: date)
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let weekday = calendar.component(.weekday, from: date)

        return Button {
            selectedDay = date
        } label: {
            VStack(spacing: 1) {
                // Day number - LARGER
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.bold())
                    .foregroundColor(isToday ? .white : weekday == 1 ? .red : weekday == 7 ? .blue : .primary)
                    .frame(width: 30, height: 30)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())

                // Day event text
                if !schedule.dayEvent.isEmpty {
                    Text(schedule.dayEvent)
                        .font(.system(size: 8).bold())
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }

                // Event indicators (color dots)
                if !schedule.timeBlocks.isEmpty {
                    HStack(spacing: 1) {
                        let uniqueCategories = Array(Set(schedule.timeBlocks.compactMap { viewModel.category(for: $0.categoryID) })).prefix(3)
                        ForEach(Array(uniqueCategories), id: \.id) { cat in
                            Circle()
                                .fill(cat.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 6)
                }

                // Mini time bar
                if !schedule.timeBlocks.isEmpty {
                    miniTimeBar(for: schedule)
                        .frame(height: 6)
                }

                // Overtime badge
                if schedule.actualOvertimeMinutes > 0 || schedule.plannedOvertimeMinutes > 0 {
                    Text(String(format: "残%.0fh", schedule.actualOvertimeHours > 0 ? schedule.actualOvertimeHours : schedule.plannedOvertimeHours))
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }

                // Event count
                if schedule.timeBlocks.count > 0 {
                    Text("\(schedule.timeBlocks.count)件")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                overtimeDate = date
                showingOvertimeEntry = true
            } label: {
                Label("残業時間を入力", systemImage: "clock.badge.exclamationmark")
            }

            if viewModel.copiedDaySchedule != nil {
                Button {
                    viewModel.pasteSchedule(to: date)
                } label: {
                    Label("ペースト", systemImage: "doc.on.clipboard")
                }
            }

            Button {
                viewModel.copySchedule(from: date)
            } label: {
                Label("この日をコピー", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Mini Time Bar

    private func miniTimeBar(for schedule: DaySchedule) -> some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray4))
                    .frame(height: 6)

                ForEach(schedule.sortedBlocks) { block in
                    let start = CGFloat(block.startTotalMinutes) / 1440.0
                    let width = CGFloat(block.durationMinutes) / 1440.0
                    let cat = viewModel.category(for: block.categoryID)

                    Rectangle()
                        .fill(cat?.color ?? .gray)
                        .frame(width: max(width * barWidth, 1), height: 6)
                        .offset(x: start * barWidth)
                }
            }
        }
    }

    // MARK: - Monthly Overtime Summary

    private var monthOvertimeSummary: some View {
        let overtime = viewModel.monthlyOvertimeHours(for: viewModel.currentMonthDate)

        return VStack(spacing: 8) {
            HStack {
                Text("月間残業サマリー")
                    .font(.subheadline.bold())
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("予定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f時間", overtime.planned))
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                VStack(spacing: 2) {
                    Text("実績")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f時間", overtime.actual))
                        .font(.title3.bold())
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                VStack(spacing: 2) {
                    Text("差分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let diff = overtime.actual - overtime.planned
                    Text(String(format: "%+.1f時間", diff))
                        .font(.title3.bold())
                        .foregroundColor(diff > 0 ? .red : .green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Date extension for Identifiable

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Overtime Entry View

struct OvertimeEntryView: View {
    @Bindable var viewModel: ScheduleViewModel
    let date: Date

    @State private var plannedHours: Double = 0
    @State private var plannedMinutes: Int = 0
    @State private var actualHours: Double = 0
    @State private var actualMinutes: Int = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                let schedule = viewModel.schedule(for: date)
                Text(schedule.dateString)
                    .font(.headline)
            }

            Section("残業予定") {
                HStack {
                    Text("時間")
                    Spacer()
                    Picker("時間", selection: $plannedHours) {
                        ForEach(0..<13, id: \.self) { h in
                            Text("\(h)時間").tag(Double(h))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分", selection: $plannedMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d分", m)).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Section("残業実績") {
                HStack {
                    Text("時間")
                    Spacer()
                    Picker("時間", selection: $actualHours) {
                        ForEach(0..<13, id: \.self) { h in
                            Text("\(h)時間").tag(Double(h))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分", selection: $actualMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d分", m)).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .navigationTitle("残業時間入力")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    let plannedTotal = Int(plannedHours) * 60 + plannedMinutes
                    let actualTotal = Int(actualHours) * 60 + actualMinutes
                    viewModel.updatePlannedOvertime(for: date, minutes: plannedTotal)
                    viewModel.updateActualOvertime(for: date, minutes: actualTotal)
                    dismiss()
                }
            }
        }
        .onAppear {
            let schedule = viewModel.schedule(for: date)
            plannedHours = Double(schedule.plannedOvertimeMinutes / 60)
            plannedMinutes = schedule.plannedOvertimeMinutes % 60
            actualHours = Double(schedule.actualOvertimeMinutes / 60)
            actualMinutes = schedule.actualOvertimeMinutes % 60
        }
    }
}
