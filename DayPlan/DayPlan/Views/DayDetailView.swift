import SwiftUI

struct DayDetailView: View {
    @Bindable var viewModel: ScheduleViewModel
    @State var date: Date

    @State private var showingAddBlock = false
    @State private var editingBlock: TimeBlock?
    @State private var showingCopyAlert = false
    @State private var showingPasteConfirm = false
    @State private var showingOvertimeEntry = false
    @State private var prefillStartHour: Int = 9
    @State private var prefillStartMinute: Int = 0
    @State private var prefillEndHour: Int = 10
    @State private var prefillEndMinute: Int = 0

    var schedule: DaySchedule {
        viewModel.schedule(for: date)
    }

    init(viewModel: ScheduleViewModel, date: Date) {
        self.viewModel = viewModel
        self._date = State(initialValue: date)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dateHeader
                dayEventSection
                timeBarSection
                statsRow
                timeBlocksList

                TodoSectionView(date: date, viewModel: viewModel)
                    .padding(.horizontal)

                Spacer(minLength: 80)
            }
        }
        .navigationTitle(schedule.dateString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.copySchedule(from: date)
                        showingCopyAlert = true
                    } label: {
                        Label("この日をコピー", systemImage: "doc.on.doc")
                    }

                    if viewModel.copiedDaySchedule != nil {
                        Button {
                            showingPasteConfirm = true
                        } label: {
                            Label("ペースト", systemImage: "doc.on.clipboard")
                        }
                    }

                    Divider()

                    Button {
                        showingOvertimeEntry = true
                    } label: {
                        Label("残業時間を入力", systemImage: "clock.badge.exclamationmark")
                    }

                    if schedule.isWeekday && schedule.timeBlocks.isEmpty {
                        Button {
                            viewModel.addDefaultWorkSchedule(to: date)
                        } label: {
                            Label("定例勤務を追加 (9:00-17:30)", systemImage: "briefcase")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button {
                    prefillStartHour = 9
                    prefillStartMinute = 0
                    prefillEndHour = 10
                    prefillEndMinute = 0
                    showingAddBlock = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBlock) {
            TimeBlockEditView(
                viewModel: viewModel,
                date: date,
                initialStartHour: prefillStartHour,
                initialStartMinute: prefillStartMinute,
                initialEndHour: prefillEndHour,
                initialEndMinute: prefillEndMinute,
                onSave: {}
            )
            .presentationDetents([.large])
        }
        .sheet(item: $editingBlock) { block in
            TimeBlockEditView(viewModel: viewModel, date: date, existingBlock: block, onSave: {
                editingBlock = nil
            })
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingOvertimeEntry) {
            NavigationStack {
                OvertimeEntryView(viewModel: viewModel, date: date)
            }
            .presentationDetents([.medium])
        }
        .alert("コピーしました", isPresented: $showingCopyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(schedule.dateString) のスケジュールをコピーしました。他の日にペーストできます。")
        }
        .alert("ペーストしますか？", isPresented: $showingPasteConfirm) {
            Button("ペースト", role: .destructive) {
                viewModel.pasteSchedule(to: date)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この日のスケジュールをコピーした内容で置き換えます。")
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > vertical else { return }
                    if value.translation.width < -60 {
                        withAnimation {
                            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                        }
                    } else if value.translation.width > 60 {
                        withAnimation {
                            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                        }
                    }
                }
        )
    }

    // MARK: - Subviews

    private var dateHeader: some View {
        HStack {
            Button {
                withAnimation {
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }

            Spacer()

            Text({
                let f = DateFormatter()
                f.locale = Locale(identifier: "ja_JP")
                f.dateFormat = "yyyy年M月d日 (EEEE)"
                return f.string(from: date)
            }())
            .font(.headline)
            .foregroundColor(.primary)

            Spacer()

            Button {
                withAnimation {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var timeBarSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("タイムライン")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text("空きをタップで予定追加")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            TimeBarView(
                schedule: schedule,
                categories: viewModel.categories,
                compact: false,
                onTapGap: { startMin, endMin in
                    prefillStartHour = startMin / 60
                    prefillStartMinute = startMin % 60
                    prefillEndHour = endMin / 60
                    prefillEndMinute = endMin % 60
                    showingAddBlock = true
                }
            )
            .padding(.horizontal)
        }
    }

    private var dayEventSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今日の大きな予定")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            TextField("例：出張、飲み会、発表会...", text: dayEventBinding)
                .font(.subheadline)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    private var dayEventBinding: Binding<String> {
        Binding(
            get: { viewModel.schedule(for: date).dayEvent },
            set: { viewModel.updateDayEvent(for: date, event: $0) }
        )
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            // Tappable overtime planned
            Button {
                showingOvertimeEntry = true
            } label: {
                statCard(title: "残業予定", value: String(format: "%.1fh", schedule.plannedOvertimeHours), icon: "clock", color: .orange)
            }
            .buttonStyle(.plain)

            // Tappable overtime actual
            Button {
                showingOvertimeEntry = true
            } label: {
                statCard(title: "残業実績", value: String(format: "%.1fh", schedule.actualOvertimeHours), icon: "clock.badge.exclamationmark", color: .red)
            }
            .buttonStyle(.plain)

            statCard(title: "空き時間", value: String(format: "%.1fh", schedule.freeTimeHours), icon: "clock", color: .green)
            statCard(title: "予定数", value: "\(schedule.timeBlocks.count)件", icon: "calendar", color: .blue)
        }
        .padding(.horizontal)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption.bold())
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var timeBlocksList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("予定一覧")
                    .font(.subheadline.bold())
                Spacer()
            }
            .padding(.horizontal)

            if schedule.timeBlocks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("予定がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if schedule.isWeekday {
                        Button("定例勤務を追加") {
                            viewModel.addDefaultWorkSchedule(to: date)
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(schedule.sortedBlocks) { block in
                    let category = viewModel.category(for: block.categoryID)

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(category?.color ?? .gray)
                            .frame(width: 6, height: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.title.isEmpty ? (category?.name ?? "不明") : block.title)
                                .font(.subheadline.bold())
                            Text(block.timeRangeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(String(format: "%.1fh", block.durationHours))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)

                        Menu {
                            Button {
                                editingBlock = block
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.removeTimeBlock(from: date, blockID: block.id)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }

            // Add schedule button in the list
            Button {
                if let lastBlock = schedule.sortedBlocks.last {
                    prefillStartHour = lastBlock.endHour
                    prefillStartMinute = lastBlock.endMinute
                    let endTotal = lastBlock.endTotalMinutes + 60
                    prefillEndHour = min(endTotal / 60, 24)
                    prefillEndMinute = endTotal >= 1440 ? 0 : endTotal % 60
                } else {
                    prefillStartHour = 9
                    prefillStartMinute = 0
                    prefillEndHour = 10
                    prefillEndMinute = 0
                }
                showingAddBlock = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("予定を追加")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }
}
