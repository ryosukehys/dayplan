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
                Label("スケジュール", systemImage: "calendar")
            }
            .tag(0)

            NavigationStack {
                CategoryManageView(viewModel: viewModel)
            }
            .tabItem {
                Label("カテゴリ", systemImage: "paintpalette")
            }
            .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
