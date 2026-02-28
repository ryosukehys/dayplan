import SwiftUI

struct ContentView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WeekView(viewModel: viewModel)
            }
            .tabItem {
                Label("週間", systemImage: "calendar.day.timeline.left")
            }
            .tag(0)

            NavigationStack {
                MonthCalendarView(viewModel: viewModel)
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                StatisticsView(viewModel: viewModel)
            }
            .tabItem {
                Label("統計", systemImage: "chart.bar")
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
                CategoryManageView(viewModel: viewModel)
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
            .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
