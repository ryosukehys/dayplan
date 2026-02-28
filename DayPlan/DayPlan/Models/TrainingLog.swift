import Foundation

struct TrainingLog: Identifiable, Codable {
    var id: UUID
    var date: Date
    var morningNote: String
    var afternoonNote: String
    var runningDistanceKm: Double

    init(
        id: UUID = UUID(),
        date: Date,
        morningNote: String = "",
        afternoonNote: String = "",
        runningDistanceKm: Double = 0
    ) {
        self.id = id
        self.date = date
        self.morningNote = morningNote
        self.afternoonNote = afternoonNote
        self.runningDistanceKm = runningDistanceKm
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 (EEEE)"
        return formatter.string(from: date)
    }

    var hasContent: Bool {
        !morningNote.isEmpty || !afternoonNote.isEmpty || runningDistanceKm > 0
    }
}
