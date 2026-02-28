import SwiftUI

struct CategoryManageView: View {
    @Bindable var viewModel: ScheduleViewModel
    @State private var showingAddSheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 20, height: 20)

                    Text(category.name)
                        .font(.body)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeCategory(viewModel.categories[index])
                }
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("カテゴリを追加", systemImage: "plus.circle.fill")
            }
        }
        .navigationTitle("カテゴリ管理")
        .sheet(isPresented: $showingAddSheet) {
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
                            showingAddSheet = false
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
                            showingAddSheet = false
                            newCategoryName = ""
                        }
                        .disabled(newCategoryName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
