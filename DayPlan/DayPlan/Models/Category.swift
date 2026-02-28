import SwiftUI

struct ScheduleCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String

    var color: Color {
        Color(hex: colorHex)
    }

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    static let defaults: [ScheduleCategory] = [
        ScheduleCategory(name: "仕事", colorHex: "#4A90D9"),
        ScheduleCategory(name: "通勤", colorHex: "#F5A623"),
        ScheduleCategory(name: "残業", colorHex: "#D0021B"),
        ScheduleCategory(name: "食事", colorHex: "#7ED321"),
        ScheduleCategory(name: "睡眠", colorHex: "#9013FE"),
        ScheduleCategory(name: "運動", colorHex: "#50E3C2"),
        ScheduleCategory(name: "趣味", colorHex: "#FF6B9D"),
        ScheduleCategory(name: "家事", colorHex: "#B8E986"),
        ScheduleCategory(name: "自己投資", colorHex: "#BD10E0"),
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
