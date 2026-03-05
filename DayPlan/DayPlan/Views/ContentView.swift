import SwiftUI

struct ContentView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var calendarManager = CalendarManager()
    @State private var selectedTab = 0
    @State private var statsTab: StatisticsView.StatsTab = .statistics

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab {
                    switch newValue {
                    case 0:
                        // 週間タブ2度押しで今週に遷移
                        viewModel.goToToday()
                    case 1:
                        // カレンダータブ2度押しで今月に遷移
                        viewModel.goToToday()
                    case 2:
                        // 統計タブを2度押しでリマインダー/統計を切り替え
                        withAnimation {
                            statsTab = statsTab == .statistics ? .reminders : .statistics
                        }
                    case 3:
                        // 練習記録タブ2度押しで今週に遷移
                        viewModel.goToToday()
                    default:
                        break
                    }
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                WeekView(viewModel: viewModel, calendarManager: calendarManager)
            }
            .tabItem {
                Label("週間", systemImage: "calendar.day.timeline.left")
            }
            .tag(0)

            NavigationStack {
                MonthCalendarView(viewModel: viewModel, calendarManager: calendarManager)
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                StatisticsView(viewModel: viewModel, selectedTab: $statsTab)
            }
            .tabItem {
                Label(statsTab == .statistics ? "統計" : "リマインダー",
                      systemImage: statsTab == .statistics ? "chart.bar" : "checklist")
            }
            .tag(2)

            NavigationStack {
                TrainingLogView(viewModel: viewModel)
            }
            .tabItem {
                Label("練習記録", systemImage: "figure.run")
            }
            .tag(3)

            NavigationStack {
                CategoryManageView(viewModel: viewModel, calendarManager: calendarManager)
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
            .tag(4)
        }
        .onAppear {
            calendarManager.checkAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
