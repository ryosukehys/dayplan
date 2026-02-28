import SwiftUI

struct TodoSectionView: View {
    let date: Date
    @Bindable var viewModel: ScheduleViewModel

    var body: some View {
        let schedule = viewModel.schedule(for: date)

        VStack(alignment: .leading, spacing: 8) {
            Label("今日のやること（3つまで）", systemImage: "checklist")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 8) {
                    Circle()
                        .fill(todoColor(index: index, text: schedule.todos.indices.contains(index) ? schedule.todos[index] : ""))
                        .frame(width: 8, height: 8)

                    TextField("やること \(index + 1)", text: todoBinding(for: date, index: index))
                        .font(.subheadline)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func todoBinding(for date: Date, index: Int) -> Binding<String> {
        Binding(
            get: {
                let schedule = viewModel.schedule(for: date)
                return schedule.todos.indices.contains(index) ? schedule.todos[index] : ""
            },
            set: { newValue in
                viewModel.updateTodo(for: date, index: index, text: newValue)
            }
        )
    }

    private func todoColor(index: Int, text: String) -> Color {
        if text.isEmpty {
            return .gray.opacity(0.3)
        }
        let colors: [Color] = [.blue, .orange, .green]
        return colors[index % colors.count]
    }
}
