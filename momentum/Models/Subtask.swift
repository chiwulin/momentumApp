import Foundation

enum SubtaskType {
    case regular
    case ai
}

struct Subtask: Identifiable, Codable {
    let id: UUID
    var title: String
    var duration: Int // in minutes
    var scheduledTime: Date
    var type: SubtaskType
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, duration: Int, scheduledTime: Date, type: SubtaskType = .regular, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.duration = duration
        self.scheduledTime = scheduledTime
        self.type = type
        self.isCompleted = isCompleted
    }

    var formattedDuration: String {
        if duration < 60 {
            return "\(duration) mins"
        } else {
            let hours = duration / 60
            let mins = duration % 60
            if mins == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(mins) mins"
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: scheduledTime)
    }

    var formattedSchedule: String {
        "\(formattedDuration) @ \(formattedTime)~ am"
    }

    // Custom Codable implementation for SubtaskType
    enum CodingKeys: String, CodingKey {
        case id, title, duration, scheduledTime, type, isCompleted
    }

    enum TypeValue: String, Codable {
        case regular, ai
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(duration, forKey: .duration)
        try container.encode(scheduledTime, forKey: .scheduledTime)
        try container.encode(type == .ai ? TypeValue.ai : TypeValue.regular, forKey: .type)
        try container.encode(isCompleted, forKey: .isCompleted)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        duration = try container.decode(Int.self, forKey: .duration)
        scheduledTime = try container.decode(Date.self, forKey: .scheduledTime)
        let typeValue = try container.decode(TypeValue.self, forKey: .type)
        type = typeValue == .ai ? .ai : .regular
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    }
}
