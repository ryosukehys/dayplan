import SwiftUI

struct CategoryManageView: View {
    @Bindable var viewModel: ScheduleViewModel
    @State private var showingAddCategorySheet = false
    @State private var showingAddQuoteSheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue
    @State private var newQuoteText = ""
    @State private var newQuoteAuthor = ""

    var body: some View {
        List {
            // Categories section
            Section("カテゴリ（長押しで並び替え）") {
                ForEach(viewModel.categories) { category in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)

                        Text(category.name)
                            .font(.body)

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
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
}
