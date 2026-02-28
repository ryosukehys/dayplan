import SwiftUI

struct TrainingLogView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var selectedPeriod: TrainingPeriod = .weekly
    @State private var selectedDate: Date = Date()
    @State private var showingEditSheet = false
    @State private var editDate: Date = Date()

    enum TrainingPeriod: String, CaseIterable {
        case weekly = "週間"
        case monthly = "月間"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period picker
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(TrainingPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Period navigation
                periodNavigation

                // Distance summary
                distanceSummary

                // Daily logs
                dailyLogsList
            }
            .padding(.vertical)
        }
        .navigationTitle("練習記録")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editDate = Date()
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                TrainingLogEditView(viewModel: viewModel, date: editDate)
            }
            .presentationDetents([.large])
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation {
                            if selectedPeriod == .weekly {
                                viewModel.goToNextWeek()
                            } else {
                                viewModel.goToNextMonth()
                            }
                        }
                    } else if value.translation.width > 50 {
                        withAnimation {
                            if selectedPeriod == .weekly {
                                viewModel.goToPreviousWeek()
                            } else {
                                viewModel.goToPreviousMonth()
                            }
                        }
                    }
                }
        )
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

    // MARK: - Distance Summary

    private var distanceSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("走行距離")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectedPeriod == .weekly {
                    Text(String(format: "%.1f km", viewModel.weeklyRunningDistance()))
                        .font(.title.bold())
                        .foregroundColor(.blue)
                } else {
                    Text(String(format: "%.1f km", viewModel.monthlyRunningDistance(for: viewModel.currentMonthDate)))
                        .font(.title.bold())
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            VStack(spacing: 4) {
                Text("練習日数")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let logDates = currentDates
                let count = logDates.filter { viewModel.trainingLog(for: $0).hasContent }.count
                Text("\(count)日")
                    .font(.title.bold())
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Daily Logs

    private var currentDates: [Date] {
        if selectedPeriod == .weekly {
            return viewModel.weekDates
        } else {
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month], from: viewModel.currentMonthDate)
            guard let firstOfMonth = calendar.date(from: comps),
                  let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
            return range.compactMap { day in
                calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
            }
        }
    }

    private var dailyLogsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日別記録")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ForEach(currentDates, id: \.self) { date in
                let log = viewModel.trainingLog(for: date)
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(date)

                Button {
                    editDate = date
                    showingEditSheet = true
                } label: {
                    HStack(spacing: 12) {
                        // Date label
                        VStack(spacing: 2) {
                            Text(dayOfWeekString(date))
                                .font(.caption2)
                                .foregroundColor(isWeekend(date) ? .red : .secondary)
                            Text(dayNumberString(date))
                                .font(.subheadline.bold())
                                .foregroundColor(isToday ? .white : .primary)
                                .frame(width: 28, height: 28)
                                .background(isToday ? Color.blue : Color.clear)
                                .clipShape(Circle())
                        }
                        .frame(width: 36)

                        if log.hasContent {
                            VStack(alignment: .leading, spacing: 4) {
                                if !log.morningNote.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("午前")
                                            .font(.system(size: 9).bold())
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.orange.opacity(0.15))
                                            .cornerRadius(3)
                                        Text(log.morningNote)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                }

                                if !log.afternoonNote.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("午後")
                                            .font(.system(size: 9).bold())
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.15))
                                            .cornerRadius(3)
                                        Text(log.afternoonNote)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Spacer()

                            if log.runningDistanceKm > 0 {
                                VStack(spacing: 1) {
                                    Text(String(format: "%.1f", log.runningDistanceKm))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.blue)
                                    Text("km")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("記録なし")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if date != currentDates.last {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
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

// MARK: - Training Log Edit View

struct TrainingLogEditView: View {
    @Bindable var viewModel: ScheduleViewModel
    let date: Date

    @State private var morningNote: String = ""
    @State private var afternoonNote: String = ""
    @State private var distanceText: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                let log = viewModel.trainingLog(for: date)
                Text(log.fullDateString)
                    .font(.headline)
            }

            Section("午前の練習") {
                TextEditor(text: $morningNote)
                    .frame(minHeight: 100)
            }

            Section("午後の練習") {
                TextEditor(text: $afternoonNote)
                    .frame(minHeight: 100)
            }

            Section("走行距離 (km)") {
                TextField("0.0", text: $distanceText)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("練習記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    var log = viewModel.trainingLog(for: date)
                    log.morningNote = morningNote
                    log.afternoonNote = afternoonNote
                    log.runningDistanceKm = Double(distanceText) ?? 0
                    viewModel.updateTrainingLog(log)
                    dismiss()
                }
            }
        }
        .onAppear {
            let log = viewModel.trainingLog(for: date)
            morningNote = log.morningNote
            afternoonNote = log.afternoonNote
            distanceText = log.runningDistanceKm > 0 ? String(format: "%.1f", log.runningDistanceKm) : ""
        }
    }
}
