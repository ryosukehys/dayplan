import SwiftUI

struct TimeBlockEditView: View {
    @Bindable var viewModel: ScheduleViewModel
    let date: Date
    var existingBlock: TimeBlock?
    var initialStartHour: Int = 9
    var initialStartMinute: Int = 0
    var initialEndHour: Int = 17
    var initialEndMinute: Int = 30
    var onSave: () -> Void

    @State private var selectedCategoryID: UUID?
    @State private var startHour: Int = 9
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 17
    @State private var endMinute: Int = 30
    @State private var title: String = ""

    @Environment(\.dismiss) private var dismiss

    var isEditing: Bool {
        existingBlock != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(viewModel.categories) { category in
                            Button {
                                selectedCategoryID = category.id
                                if title.isEmpty {
                                    title = category.name
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if selectedCategoryID == category.id {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedCategoryID == category.id ? category.color.opacity(0.15) : .clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("時間") {
                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("時", selection: $startHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)時").tag(h)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("分", selection: $startMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d分", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("終了")
                        Spacer()
                        Picker("時", selection: $endHour) {
                            ForEach(0..<25, id: \.self) { h in
                                Text("\(h)時").tag(h)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("分", selection: $endMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d分", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if endHour * 60 + endMinute <= startHour * 60 + startMinute {
                        Text("終了時間は開始時間より後にしてください")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("タイトル（任意）") {
                    TextField("例：定例ミーティング", text: $title)
                }
            }
            .navigationTitle(isEditing ? "予定を編集" : "予定を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "更新" : "追加") {
                        saveBlock()
                    }
                    .disabled(selectedCategoryID == nil || endHour * 60 + endMinute <= startHour * 60 + startMinute)
                }
            }
            .onAppear {
                if let block = existingBlock {
                    selectedCategoryID = block.categoryID
                    startHour = block.startHour
                    startMinute = block.startMinute
                    endHour = block.endHour
                    endMinute = block.endMinute
                    title = block.title
                } else {
                    startHour = initialStartHour
                    startMinute = initialStartMinute
                    endHour = initialEndHour
                    endMinute = initialEndMinute
                    if selectedCategoryID == nil {
                        selectedCategoryID = viewModel.categories.first?.id
                    }
                }
            }
        }
    }

    private func saveBlock() {
        guard let categoryID = selectedCategoryID else { return }

        if let existing = existingBlock {
            var updated = existing
            updated.categoryID = categoryID
            updated.startHour = startHour
            updated.startMinute = startMinute
            updated.endHour = endHour
            updated.endMinute = endMinute
            updated.title = title
            viewModel.updateTimeBlock(for: date, block: updated)
        } else {
            let block = TimeBlock(
                categoryID: categoryID,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                title: title
            )
            viewModel.addTimeBlock(to: date, block: block)
        }

        onSave()
        dismiss()
    }
}
