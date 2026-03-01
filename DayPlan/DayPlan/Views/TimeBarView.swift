import SwiftUI

struct TimeBarView: View {
    let schedule: DaySchedule
    let categories: [ScheduleCategory]
    let compact: Bool
    var onTapGap: ((Int, Int) -> Void)?
    var showCurrentTime: Bool = false

    private let totalMinutes: CGFloat = 1440 // 24 hours
    private let hourLabels = [0, 3, 6, 9, 12, 15, 18, 21, 24]

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            GeometryReader { geometry in
                let barWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background (free time) — tappable gaps
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: compact ? 24 : 36)
                        .onTapGesture { location in
                            guard let onTapGap = onTapGap else { return }
                            let tappedMinute = Int((location.x / barWidth) * 1440)
                            let gaps = schedule.gapSlots()
                            if let gap = gaps.first(where: { tappedMinute >= $0.startMinute && tappedMinute < $0.endMinute }) {
                                let sorted = schedule.sortedBlocks
                                let hasPrev = sorted.contains { $0.endTotalMinutes == gap.startMinute }
                                let hasNext = sorted.contains { $0.startTotalMinutes == gap.endMinute }

                                if hasPrev || hasNext {
                                    // Between events: fill the entire gap
                                    onTapGap(gap.startMinute, gap.endMinute)
                                } else {
                                    // Open area: 1-hour block from tap point
                                    let snapped = (tappedMinute / 15) * 15
                                    let start = max(gap.startMinute, snapped)
                                    let end = min(gap.endMinute, start + 60)
                                    onTapGap(start, end)
                                }
                            }
                        }

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
                            .allowsHitTesting(false)

                        if !compact && widthFraction * barWidth > 40 {
                            Text(block.title.isEmpty ? (category?.name ?? "") : block.title)
                                .font(.system(size: 9))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: widthFraction * barWidth - 4, alignment: .center)
                                .offset(x: startFraction * barWidth + 2, y: 0)
                                .allowsHitTesting(false)
                        }
                    }
                    // Current time indicator
                    if showCurrentTime {
                        let now = Date()
                        let cal = Calendar.current
                        let currentMinute = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
                        let fraction = CGFloat(currentMinute) / totalMinutes
                        let barHeight: CGFloat = compact ? 24 : 36

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: barHeight + 6)
                            .offset(x: fraction * barWidth - 1, y: -3)
                            .allowsHitTesting(false)

                        if !compact {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .offset(x: fraction * barWidth - 3, y: -(barHeight / 2) - 3)
                                .allowsHitTesting(false)
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
