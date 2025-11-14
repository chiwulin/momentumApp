import SwiftUI

struct MainTaskCard: View {
    let task: TaskItem
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let openAIService: OpenAIService

    @State private var isPressed = false
    @State private var isPulsing = false
    @State private var aiIcon: String?
    @State private var aiColor: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main task card
            HStack(spacing: 12) {
                // AI-powered circular icon based on task title
                Image(systemName: aiIcon ?? iconForTask(task.title))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(colorFromString(aiColor ?? "red"))
                    .clipShape(Circle())

                // Task content
                HStack {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let time = task.time {
                        Text(time)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 99)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .animation(.easeInOut(duration: 0.5).repeatCount(task.isBreakingDown ? .max : 1), value: isPulsing)
            .gesture(
                LongPressGesture(minimumDuration: 0.8)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                        onLongPress()
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )

            // Progress indicator
            if let progressText = task.progressText {
                Text(progressText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 52)
            }
        }
        .onChange(of: task.isBreakingDown) { _, isBreaking in
            isPulsing = isBreaking
        }
        .task(id: task.title) {
            await loadAIIcon()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title). Long press to break down into subtasks.")
        .accessibilityHint(task.progressText ?? "")
    }

    private func loadAIIcon() async {
        do {
            let iconResponse = try await openAIService.selectIcon(for: task.title)
            await MainActor.run {
                aiIcon = iconResponse.symbol
                aiColor = iconResponse.color
            }
        } catch {
            // Silently fall back to keyword-based icon selection
            print("Failed to load AI icon: \(error)")
        }
    }

    // Fallback icon selection (English-only, simplified)
    private func iconForTask(_ title: String) -> String {
        let lowercased = title.lowercased()

        // Sports & Activities
        if lowercased.contains("golf") {
            return "figure.golf"
        } else if lowercased.contains("gym") || lowercased.contains("workout") || lowercased.contains("exercise") {
            return "figure.run"
        } else if lowercased.contains("yoga") {
            return "figure.mind.and.body"
        }

        // Communication
        else if lowercased.contains("call") || lowercased.contains("phone") {
            return "phone.fill"
        } else if lowercased.contains("message") || lowercased.contains("text") {
            return "message.fill"
        } else if lowercased.contains("email") || lowercased.contains("mail") {
            return "envelope.fill"
        } else if lowercased.contains("meeting") {
            return "person.2.fill"
        }

        // Work & Productivity
        else if lowercased.contains("write") {
            return "pencil"
        } else if lowercased.contains("read") || lowercased.contains("book") {
            return "book.fill"
        } else if lowercased.contains("code") || lowercased.contains("develop") {
            return "chevron.left.forwardslash.chevron.right"
        }

        // Home & Errands
        else if lowercased.contains("buy") || lowercased.contains("shop") {
            return "cart.fill"
        } else if lowercased.contains("cook") || lowercased.contains("meal") {
            return "fork.knife"
        }

        // Default
        else {
            return "checkmark"
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "brown": return .brown
        case "red": return .red
        case "teal": return .teal
        case "pink": return .pink
        default: return .red
        }
    }
}
