import SwiftUI

struct StatisticsView: View {
    @Bindable var viewModel: ScheduleViewModel

    @State private var selectedPeriod: StatsPeriod = .weekly

    enum StatsPeriod: String, CaseIterable {
        case weekly = "週間"
        case monthly = "月間"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period picker
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Period navigation
                periodNavigation

                // Overtime summary
                overtimeSummaryCard

                // Category breakdown bar chart
                categoryBreakdown

                // Category detail list
                categoryDetailList
            }
            .padding(.vertical)
        }
        .navigationTitle("統計")
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > vertical else { return }
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
            Text(String(format: "%.1fh", hours))
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
                Text(String(format: "合計 %.1f時間", totalHours))
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

                        Text(String(format: "%.1fh", stat.totalHours))
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
