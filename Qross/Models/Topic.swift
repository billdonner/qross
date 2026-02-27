import SwiftUI

struct Topic: Identifiable, Codable, Hashable {
    let id: String          // category name from card-engine
    let name: String
    let questionCount: Int
    var color: Color = .blue

    enum CodingKeys: String, CodingKey {
        case id, name, questionCount
    }

    init(id: String, name: String, questionCount: Int, color: Color = .blue) {
        self.id = id
        self.name = name
        self.questionCount = questionCount
        self.color = color
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        questionCount = try c.decode(Int.self, forKey: .questionCount)
        color = .blue
    }

    static func == (lhs: Topic, rhs: Topic) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Curated palette for topic colors — designed for dark + light mode, color-blind safe
enum TopicPalette {
    static let colors: [Color] = [
        .blue, .orange, .green, .purple, .pink,
        .teal, .indigo, .mint, .cyan, .brown,
        Color(red: 0.95, green: 0.5, blue: 0.2),   // warm orange
        Color(red: 0.4, green: 0.7, blue: 0.3),     // forest green
        Color(red: 0.6, green: 0.3, blue: 0.8),     // violet
        Color(red: 0.9, green: 0.3, blue: 0.5),     // rose
        Color(red: 0.2, green: 0.6, blue: 0.8),     // sky
        Color(red: 0.8, green: 0.6, blue: 0.2),     // gold
        Color(red: 0.5, green: 0.8, blue: 0.7),     // seafoam
        Color(red: 0.7, green: 0.4, blue: 0.5),     // mauve
        Color(red: 0.3, green: 0.5, blue: 0.7),     // steel blue
        Color(red: 0.85, green: 0.45, blue: 0.55),  // salmon
        Color(red: 0.55, green: 0.65, blue: 0.35),  // olive
        Color(red: 0.65, green: 0.35, blue: 0.65),  // plum
        Color(red: 0.4, green: 0.75, blue: 0.55),   // jade
        Color(red: 0.75, green: 0.55, blue: 0.35),  // copper
        Color(red: 0.35, green: 0.55, blue: 0.55),  // slate teal
        Color(red: 0.8, green: 0.35, blue: 0.35),   // brick
    ]

    static func assign(to topics: [Topic]) -> [Topic] {
        topics.enumerated().map { i, t in
            Topic(id: t.id, name: t.name, questionCount: t.questionCount,
                  color: colors[i % colors.count])
        }
    }
}
