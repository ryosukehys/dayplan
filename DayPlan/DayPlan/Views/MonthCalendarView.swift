import SwiftUI

struct MonthCalendarView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var selectedDay: Date?
    @State private var showingTrackingEntry = false
    @State private var trackingEntryDate: Date = Date()

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
        .sheet(isPresented: $showingTrackingEntry) {
            NavigationStack {
                TrackingEntryView(viewModel: viewModel, date: trackingEntryDate)
            }
            .presentationDetents([.medium, .large])
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

            monthTrackingSummary
                .padding()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > vertical else { return }
                    if value.translation.width < -60 {
                        withAnimation { viewModel.goToNextMonth() }
                    } else if value.translation.width > 60 {
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
                // Day number
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

                // Tracking item badge (show first item with data)
                trackingBadge(for: schedule)

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
                trackingEntryDate = date
                showingTrackingEntry = true
            } label: {
                Label("記録を入力", systemImage: "chart.bar.doc.horizontal")
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

    @ViewBuilder
    private func trackingBadge(for schedule: DaySchedule) -> some View {
        let itemsWithData = viewModel.trackingItems.filter { item in
            schedule.trackingValue(for: item.id).hasData
        }
        if let firstItem = itemsWithData.first {
            let value = schedule.trackingValue(for: firstItem.id)
            let hours = value.actual > 0 ? value.actualHours : value.plannedHours
            Text(String(format: "%.0fh", hours))
                .font(.system(size: 8))
                .foregroundColor(firstItem.color)
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

    // MARK: - Monthly Tracking Summary

    private var monthTrackingSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("月間記録サマリー")
                    .font(.subheadline.bold())
                Spacer()
            }

            ForEach(viewModel.trackingItems) { item in
                let data = viewModel.monthlyTrackingHours(for: viewModel.currentMonthDate, itemID: item.id)

                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: item.iconName)
                            .font(.caption)
                            .foregroundColor(item.color)
                        Text(item.name)
                            .font(.caption.bold())
                        Spacer()
                    }

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("予定")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatHoursMinutesJP(data.planned))
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        VStack(spacing: 2) {
                            Text("実績")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatHoursMinutesJP(data.actual))
                                .font(.subheadline.bold())
                                .foregroundColor(item.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        VStack(spacing: 2) {
                            Text("差分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let diff = data.actual - data.planned
                            Text(formatSignedHoursMinutesJP(diff))
                                .font(.subheadline.bold())
                                .foregroundColor(diff > 0 ? .red : .green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Date extension for Identifiable

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Tracking Entry View

struct TrackingEntryView: View {
    @Bindable var viewModel: ScheduleViewModel
    let date: Date

    @State private var values: [UUID: (plannedHours: Int, plannedMinutes: Int, actualHours: Int, actualMinutes: Int)] = [:]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                let schedule = viewModel.schedule(for: date)
                Text(schedule.dateString)
                    .font(.headline)
            }

            ForEach(viewModel.trackingItems) { item in
                Section {
                    HStack {
                        Text("予定")
                        Spacer()
                        Picker("時間", selection: plannedHoursBinding(for: item.id)) {
                            ForEach(0..<13, id: \.self) { h in
                                Text("\(h)時間").tag(h)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("分", selection: plannedMinutesBinding(for: item.id)) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d分", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("実績")
                        Spacer()
                        Picker("時間", selection: actualHoursBinding(for: item.id)) {
                            ForEach(0..<13, id: \.self) { h in
                                Text("\(h)時間").tag(h)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("分", selection: actualMinutesBinding(for: item.id)) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d分", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: item.iconName)
                            .foregroundColor(item.color)
                        Text(item.name)
                    }
                }
            }
        }
        .navigationTitle("記録入力")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    for item in viewModel.trackingItems {
                        let v = values[item.id] ?? (0, 0, 0, 0)
                        let plannedTotal = v.plannedHours * 60 + v.plannedMinutes
                        let actualTotal = v.actualHours * 60 + v.actualMinutes
                        viewModel.updateTrackingValue(for: date, itemID: item.id, planned: plannedTotal, actual: actualTotal)
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            let schedule = viewModel.schedule(for: date)
            for item in viewModel.trackingItems {
                let tv = schedule.trackingValue(for: item.id)
                values[item.id] = (
                    plannedHours: tv.planned / 60,
                    plannedMinutes: tv.planned % 60,
                    actualHours: tv.actual / 60,
                    actualMinutes: tv.actual % 60
                )
            }
        }
    }

    // MARK: - Bindings

    private func plannedHoursBinding(for id: UUID) -> Binding<Int> {
        Binding(
            get: { values[id]?.plannedHours ?? 0 },
            set: { values[id, default: (0, 0, 0, 0)].plannedHours = $0 }
        )
    }

    private func plannedMinutesBinding(for id: UUID) -> Binding<Int> {
        Binding(
            get: { values[id]?.plannedMinutes ?? 0 },
            set: { values[id, default: (0, 0, 0, 0)].plannedMinutes = $0 }
        )
    }

    private func actualHoursBinding(for id: UUID) -> Binding<Int> {
        Binding(
            get: { values[id]?.actualHours ?? 0 },
            set: { values[id, default: (0, 0, 0, 0)].actualHours = $0 }
        )
    }

    private func actualMinutesBinding(for id: UUID) -> Binding<Int> {
        Binding(
            get: { values[id]?.actualMinutes ?? 0 },
            set: { values[id, default: (0, 0, 0, 0)].actualMinutes = $0 }
        )
    }
}
