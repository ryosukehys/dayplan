import SwiftUI

struct TimeBarView: View {
    let schedule: DaySchedule
    let categories: [ScheduleCategory]
    let compact: Bool

    private let totalMinutes: CGFloat = 1440 // 24 hours
    private let hourLabels = [0, 3, 6, 9, 12, 15, 18, 21, 24]

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            GeometryReader { geometry in
                let barWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background (free time)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: compact ? 24 : 36)

                    // Time blocks
                    ForEach(schedule.sortedBlocks) { block in
                        let startFraction = CGFloat(block.startTotalMinutes) / totalMinutes
                        let widthFraction = CGFloat(block.durationMinutes) / totalMinutes
                        let category = categories.first { $0.id == block.categoryID }

                        RoundedRectangle(cornerRadius: 2)
                            .fill(category?.color ?? .gray)
                            .frame(
                                width: max(widthFraction * barWidth, 2),
                                height: compact ? 24 : 36
                            )
                            .offset(x: startFraction * barWidth)

                        if !compact && widthFraction * barWidth > 40 {
                            Text(block.title.isEmpty ? (category?.name ?? "") : block.title)
                                .font(.system(size: 9))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: widthFraction * barWidth - 4, alignment: .center)
                                .offset(x: startFraction * barWidth + 2, y: 0)
                        }
                    }
                }
                .frame(height: compact ? 24 : 36)
            }
            .frame(height: compact ? 24 : 36)

            // Hour labels
            if !compact {
                GeometryReader { geometry in
                    let barWidth = geometry.size.width

                    ZStack(alignment: .leading) {
                        ForEach(hourLabels, id: \.self) { hour in
                            let fraction = CGFloat(hour * 60) / totalMinutes
                            Text("\(hour)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .offset(x: fraction * barWidth - 6)
                        }
                    }
                }
                .frame(height: 14)
            }
        }
    }
}

struct TimeBarView_Previews: PreviewProvider {
    static var previews: some View {
        let categories = ScheduleCategory.defaults
        let schedule = DaySchedule(
            date: Date(),
            timeBlocks: [
                TimeBlock(categoryID: categories[0].id, startHour: 9, startMinute: 0, endHour: 17, endMinute: 30, title: "仕事"),
                TimeBlock(categoryID: categories[1].id, startHour: 8, startMinute: 0, endHour: 9, endMinute: 0, title: "通勤"),
                TimeBlock(categoryID: categories[4].id, startHour: 0, startMinute: 0, endHour: 7, endMinute: 0, title: "睡眠"),
            ]
        )

        VStack(spacing: 20) {
            TimeBarView(schedule: schedule, categories: categories, compact: false)
            TimeBarView(schedule: schedule, categories: categories, compact: true)
        }
        .padding()
    }
}
