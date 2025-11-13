import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    var title: String
    var time: Date
    var icon: String
    var iconColor: String
    var subtasks: [Subtask]

    init(id: UUID = UUID(), title: String, time: Date, icon: String, iconColor: String = "green", subtasks: [Subtask] = []) {
        self.id = id
        self.title = title
        self.time = time
        self.icon = icon
        self.iconColor = iconColor
        self.subtasks = subtasks
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}
