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
                let text = schedule.todos.indices.contains(index) ? schedule.todos[index] : ""
                let isCompleted = schedule.todoCompleted.indices.contains(index) ? schedule.todoCompleted[index] : false

                HStack(spacing: 8) {
                    Button {
                        if !text.isEmpty {
                            viewModel.toggleTodoCompleted(for: date, index: index)
                        }
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isCompleted ? .green : (text.isEmpty ? Color(.systemGray4) : todoColor(index: index)))
                    }
                    .buttonStyle(.plain)
                    .disabled(text.isEmpty)

                    TextField("やること \(index + 1)", text: todoBinding(for: date, index: index))
                        .font(.subheadline)
                        .textFieldStyle(.roundedBorder)
                        .strikethrough(isCompleted && !text.isEmpty)
                        .foregroundColor(isCompleted ? .secondary : .primary)
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

    private func todoColor(index: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .green]
        return colors[index % colors.count]
    }
}
