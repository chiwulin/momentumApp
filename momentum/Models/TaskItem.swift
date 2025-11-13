import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var time: String?
    var isSubtask: Bool
    var parentId: UUID?
    var completed: Bool
    var estimatedMinutes: Int
    var createdAt: Date
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.parent)
    var subtasks: [TaskItem]?

    @Relationship
    var parent: TaskItem?

    var isBreakingDown: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        time: String? = nil,
        isSubtask: Bool = false,
        parentId: UUID? = nil,
        completed: Bool = false,
        estimatedMinutes: Int = 30,
        createdAt: Date = Date(),
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.isSubtask = isSubtask
        self.parentId = parentId
        self.completed = completed
        self.estimatedMinutes = estimatedMinutes
        self.createdAt = createdAt
        self.orderIndex = orderIndex
    }

    var completedSubtasksCount: Int {
        subtasks?.filter { $0.completed }.count ?? 0
    }

    var totalSubtasksCount: Int {
        subtasks?.count ?? 0
    }

    var progressText: String? {
        guard let subtasks = subtasks, !subtasks.isEmpty else { return nil }
        return "\(completedSubtasksCount)/\(totalSubtasksCount) done"
    }

    var sortedSubtasks: [TaskItem] {
        guard let subtasks = subtasks else { return [] }
        return subtasks.sorted { lhs, rhs in
            if lhs.completed != rhs.completed {
                return !lhs.completed // Incomplete first
            }
            return lhs.orderIndex < rhs.orderIndex
        }
    }
}
