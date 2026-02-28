import Foundation

struct Quote: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var author: String

    init(id: UUID = UUID(), text: String, author: String) {
        self.id = id
        self.text = text
        self.author = author
    }

    static let defaults: [Quote] = [
        Quote(
            text: "明日、世界が滅びるとしても　今日、君はリンゴの木を植える",
            author: "ルター"
        ),
        Quote(
            text: "理想を持つことは本当に素晴らしいことです。ですが誤解される覚悟をしておいてください。大きなビジョンを持って行動する人はたとえ最後に正しかったとしても狂っていると言われるものです。",
            author: "マーク・ザッカーバーグ"
        ),
    ]
}
