import Foundation

struct EmotionLog: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let emotion: String
    
    private enum CodingKeys: String, CodingKey {
        case timestamp
        case emotion
    }
}
