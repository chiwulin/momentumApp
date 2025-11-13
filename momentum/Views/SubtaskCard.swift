import SwiftUI

struct SubtaskCard: View {
    let subtask: TaskItem
    let onComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox icon
            Image(systemName: subtask.completed ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundColor(subtask.completed ? .green : Color.gray.opacity(0.4))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onComplete()
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                // Task title
                Text(subtask.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(subtask.completed ? .gray : .primary)
                    .strikethrough(subtask.completed, color: .gray)
                    .lineLimit(2)

                // Time information
                HStack(spacing: 4) {
                    if subtask.estimatedMinutes > 0 {
                        Text("\(subtask.estimatedMinutes) mins")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }

                    if let time = subtask.time {
                        Text("@ \(time)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtask.title). \(subtask.estimatedMinutes) minutes. \(subtask.completed ? "Completed" : "Not completed")")
        .accessibilityHint(subtask.completed ? "" : "Tap checkbox to mark as complete")
    }
}
