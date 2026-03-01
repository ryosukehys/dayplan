import SwiftUI

struct CategoryManageView: View {
    @Bindable var viewModel: ScheduleViewModel
    @State private var showingAddCategorySheet = false
    @State private var showingAddQuoteSheet = false
    @State private var showingAddTrackingItemSheet = false
    @State private var editingCategory: ScheduleCategory?
    @State private var editingTrackingItem: TrackingItem?
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue
    @State private var editCategoryName = ""
    @State private var editCategoryColor = Color.blue
    @State private var showingDeleteConfirm = false
    @State private var showingDeleteTrackingConfirm = false
    @State private var newQuoteText = ""
    @State private var newQuoteAuthor = ""
    @State private var newTrackingName = ""
    @State private var newTrackingColor = Color.red
    @State private var newTrackingIcon = "chart.bar.fill"
    @State private var editTrackingName = ""
    @State private var editTrackingColor = Color.red
    @State private var editTrackingIcon = "chart.bar.fill"

    var body: some View {
        List {
            // Tracking items section
            Section("記録項目（長押しで並び替え）") {
                ForEach(viewModel.trackingItems) { item in
                    Button {
                        editTrackingName = item.name
                        editTrackingColor = item.color
                        editTrackingIcon = item.iconName
                        editingTrackingItem = item
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.iconName)
                                .foregroundColor(item.color)
                                .frame(width: 20)

                            Text(item.name)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.caption)

                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeTrackingItem(viewModel.trackingItems[index])
                    }
                }
                .onMove { source, destination in
                    viewModel.moveTrackingItem(from: source, to: destination)
                }

                Button {
                    showingAddTrackingItemSheet = true
                } label: {
                    Label("記録項目を追加", systemImage: "plus.circle.fill")
                }
            }

            // Categories section
            Section("カテゴリ（長押しで並び替え）") {
                ForEach(viewModel.categories) { category in
                    Button {
                        editCategoryName = category.name
                        editCategoryColor = category.color
                        editingCategory = category
                    } label: {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 20, height: 20)

                            Text(category.name)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.caption)

                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeCategory(viewModel.categories[index])
                    }
                }
                .onMove { source, destination in
                    viewModel.moveCategory(from: source, to: destination)
                }

                Button {
                    showingAddCategorySheet = true
                } label: {
                    Label("カテゴリを追加", systemImage: "plus.circle.fill")
                }
            }

            // Quotes section
            Section("名言") {
                ForEach(viewModel.quotes) { quote in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.text)
                            .font(.subheadline)
                            .lineLimit(3)
                        Text("- \(quote.author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeQuote(viewModel.quotes[index])
                    }
                }

                Button {
                    showingAddQuoteSheet = true
                } label: {
                    Label("名言を追加", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        // Add tracking item sheet
        .sheet(isPresented: $showingAddTrackingItemSheet) {
            NavigationStack {
                Form {
                    TextField("項目名（例：残業時間、勉強時間）", text: $newTrackingName)
                    ColorPicker("カラー", selection: $newTrackingColor)

                    Section("アイコン") {
                        iconPicker(selection: $newTrackingIcon)
                    }
                }
                .navigationTitle("新規記録項目")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            showingAddTrackingItemSheet = false
                            newTrackingName = ""
                            newTrackingIcon = "chart.bar.fill"
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            let item = TrackingItem(
                                name: newTrackingName,
                                colorHex: newTrackingColor.toHex(),
                                iconName: newTrackingIcon
                            )
                            viewModel.addTrackingItem(item)
                            showingAddTrackingItemSheet = false
                            newTrackingName = ""
                            newTrackingIcon = "chart.bar.fill"
                        }
                        .disabled(newTrackingName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        // Edit tracking item sheet
        .sheet(item: $editingTrackingItem) { item in
            NavigationStack {
                Form {
                    TextField("項目名", text: $editTrackingName)
                    ColorPicker("カラー", selection: $editTrackingColor)

                    Section("アイコン") {
                        iconPicker(selection: $editTrackingIcon)
                    }

                    Section {
                        Button(role: .destructive) {
                            showingDeleteTrackingConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("この記録項目を削除", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("記録項目を編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            editingTrackingItem = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            var updated = item
                            updated.name = editTrackingName
                            updated.colorHex = editTrackingColor.toHex()
                            updated.iconName = editTrackingIcon
                            viewModel.updateTrackingItem(updated)
                            editingTrackingItem = nil
                        }
                        .disabled(editTrackingName.isEmpty)
                    }
                }
                .alert("記録項目を削除しますか？", isPresented: $showingDeleteTrackingConfirm) {
                    Button("削除", role: .destructive) {
                        viewModel.removeTrackingItem(item)
                        editingTrackingItem = nil
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("「\(item.name)」を削除します。この項目に記録されたデータは表示されなくなります。")
                }
            }
            .presentationDetents([.medium, .large])
        }
        // Add category sheet
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationStack {
                Form {
                    TextField("カテゴリ名", text: $newCategoryName)
                    ColorPicker("カラー", selection: $newCategoryColor)
                }
                .navigationTitle("新規カテゴリ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            showingAddCategorySheet = false
                            newCategoryName = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            let category = ScheduleCategory(
                                name: newCategoryName,
                                colorHex: newCategoryColor.toHex()
                            )
                            viewModel.addCategory(category)
                            showingAddCategorySheet = false
                            newCategoryName = ""
                        }
                        .disabled(newCategoryName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        // Edit category sheet
        .sheet(item: $editingCategory) { category in
            NavigationStack {
                Form {
                    TextField("カテゴリ名", text: $editCategoryName)
                    ColorPicker("カラー", selection: $editCategoryColor)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("このカテゴリを削除", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("カテゴリを編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            editingCategory = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            var updated = category
                            updated.name = editCategoryName
                            updated.colorHex = editCategoryColor.toHex()
                            viewModel.updateCategory(updated)
                            editingCategory = nil
                        }
                        .disabled(editCategoryName.isEmpty)
                    }
                }
                .alert("カテゴリを削除しますか？", isPresented: $showingDeleteConfirm) {
                    Button("削除", role: .destructive) {
                        viewModel.removeCategory(category)
                        editingCategory = nil
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("「\(category.name)」を削除します。このカテゴリを使用している予定のカテゴリ情報は失われます。")
                }
            }
            .presentationDetents([.medium])
        }
        // Add quote sheet
        .sheet(isPresented: $showingAddQuoteSheet) {
            NavigationStack {
                Form {
                    Section("名言") {
                        TextEditor(text: $newQuoteText)
                            .frame(minHeight: 80)
                    }
                    Section("発言者") {
                        TextField("例：ルター", text: $newQuoteAuthor)
                    }
                }
                .navigationTitle("名言を追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            showingAddQuoteSheet = false
                            newQuoteText = ""
                            newQuoteAuthor = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            let quote = Quote(text: newQuoteText, author: newQuoteAuthor)
                            viewModel.addQuote(quote)
                            showingAddQuoteSheet = false
                            newQuoteText = ""
                            newQuoteAuthor = ""
                        }
                        .disabled(newQuoteText.isEmpty || newQuoteAuthor.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Icon Picker

    private func iconPicker(selection: Binding<String>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(TrackingItem.availableIcons, id: \.self) { iconName in
                Button {
                    selection.wrappedValue = iconName
                } label: {
                    Image(systemName: iconName)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(selection.wrappedValue == iconName ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        .foregroundColor(selection.wrappedValue == iconName ? .blue : .primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(selection.wrappedValue == iconName ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
