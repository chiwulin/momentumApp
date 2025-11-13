import SwiftUI

struct MainTaskCard: View {
    let task: TaskItem
    let onDelete: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main task card
            HStack(spacing: 12) {
                // Smart circular icon based on task title
                Image(systemName: iconForTask(task.title))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor(for: task.title))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title). Long press to break down into subtasks.")
        .accessibilityHint(task.progressText ?? "")
    }

    private func iconForTask(_ title: String) -> String {
        let lowercased = title.lowercased()

        // Sports & Activities
        if lowercased.contains("golf") || lowercased.contains("高爾夫") {
            return "figure.golf"
        } else if lowercased.contains("gym") || lowercased.contains("workout") || lowercased.contains("exercise") || lowercased.contains("運動") {
            return "figure.run"
        } else if lowercased.contains("yoga") || lowercased.contains("瑜伽") {
            return "figure.mind.and.body"
        } else if lowercased.contains("swim") || lowercased.contains("游泳") {
            return "figure.pool.swim"
        }

        // Communication
        else if lowercased.contains("call") || lowercased.contains("phone") || lowercased.contains("電話") {
            return "phone.fill"
        } else if lowercased.contains("message") || lowercased.contains("text") || lowercased.contains("訊息") || lowercased.contains("聊天") {
            return "message.fill"
        } else if lowercased.contains("email") || lowercased.contains("mail") || lowercased.contains("郵件") {
            return "envelope.fill"
        } else if lowercased.contains("meeting") || lowercased.contains("會議") {
            return "person.2.fill"
        } else if lowercased.contains("video") || lowercased.contains("zoom") || lowercased.contains("視訊") {
            return "video.fill"
        }

        // Work & Productivity
        else if lowercased.contains("write") || lowercased.contains("寫") || lowercased.contains("編輯") {
            return "pencil"
        } else if lowercased.contains("read") || lowercased.contains("閱讀") || lowercased.contains("book") {
            return "book.fill"
        } else if lowercased.contains("research") || lowercased.contains("search") || lowercased.contains("搜尋") || lowercased.contains("研究") {
            return "magnifyingglass"
        } else if lowercased.contains("review") || lowercased.contains("檢閱") || lowercased.contains("check") {
            return "checkmark.circle.fill"
        } else if lowercased.contains("plan") || lowercased.contains("規劃") || lowercased.contains("schedule") {
            return "calendar"
        } else if lowercased.contains("presentation") || lowercased.contains("簡報") {
            return "rectangle.on.rectangle"
        } else if lowercased.contains("code") || lowercased.contains("程式") || lowercased.contains("develop") {
            return "chevron.left.forwardslash.chevron.right"
        }

        // Home & Errands
        else if lowercased.contains("buy") || lowercased.contains("購買") || lowercased.contains("shop") {
            return "cart.fill"
        } else if lowercased.contains("cook") || lowercased.contains("烹飪") || lowercased.contains("meal") {
            return "fork.knife"
        } else if lowercased.contains("clean") || lowercased.contains("清潔") {
            return "sparkles"
        } else if lowercased.contains("laundry") || lowercased.contains("洗衣") {
            return "washer.fill"
        } else if lowercased.contains("fix") || lowercased.contains("repair") || lowercased.contains("修理") {
            return "wrench.fill"
        }

        // Health & Wellness
        else if lowercased.contains("doctor") || lowercased.contains("hospital") || lowercased.contains("醫生") || lowercased.contains("醫院") {
            return "cross.case.fill"
        } else if lowercased.contains("medicine") || lowercased.contains("藥") || lowercased.contains("pill") {
            return "pills.fill"
        } else if lowercased.contains("sleep") || lowercased.contains("睡眠") || lowercased.contains("rest") {
            return "bed.double.fill"
        }

        // Travel & Transportation
        else if lowercased.contains("flight") || lowercased.contains("fly") || lowercased.contains("航班") || lowercased.contains("飛") {
            return "airplane"
        } else if lowercased.contains("drive") || lowercased.contains("car") || lowercased.contains("開車") {
            return "car.fill"
        } else if lowercased.contains("train") || lowercased.contains("火車") {
            return "train.side.front.car"
        }

        // Weather & Nature
        else if lowercased.contains("weather") || lowercased.contains("天氣") {
            return "sun.max.fill"
        } else if lowercased.contains("walk") || lowercased.contains("散步") || lowercased.contains("hike") {
            return "figure.walk"
        }

        // Finance
        else if lowercased.contains("pay") || lowercased.contains("payment") || lowercased.contains("付款") || lowercased.contains("bill") {
            return "dollarsign.circle.fill"
        } else if lowercased.contains("bank") || lowercased.contains("銀行") {
            return "building.columns.fill"
        }

        // Entertainment
        else if lowercased.contains("movie") || lowercased.contains("film") || lowercased.contains("電影") {
            return "film.fill"
        } else if lowercased.contains("music") || lowercased.contains("音樂") {
            return "music.note"
        } else if lowercased.contains("game") || lowercased.contains("遊戲") {
            return "gamecontroller.fill"
        }

        // Default
        else {
            return "checkmark"
        }
    }

    private func iconColor(for title: String) -> Color {
        let lowercased = title.lowercased()

        // Sports - Orange/Red
        if lowercased.contains("golf") || lowercased.contains("gym") || lowercased.contains("workout") ||
           lowercased.contains("exercise") || lowercased.contains("運動") || lowercased.contains("高爾夫") {
            return Color.orange
        }

        // Communication - Blue
        else if lowercased.contains("call") || lowercased.contains("phone") || lowercased.contains("message") ||
                lowercased.contains("email") || lowercased.contains("mail") || lowercased.contains("meeting") ||
                lowercased.contains("電話") || lowercased.contains("訊息") || lowercased.contains("郵件") || lowercased.contains("會議") {
            return Color.blue
        }

        // Work - Purple
        else if lowercased.contains("write") || lowercased.contains("read") || lowercased.contains("research") ||
                lowercased.contains("code") || lowercased.contains("寫") || lowercased.contains("閱讀") || lowercased.contains("程式") {
            return Color.purple
        }

        // Shopping - Green
        else if lowercased.contains("buy") || lowercased.contains("shop") || lowercased.contains("購買") {
            return Color.green
        }

        // Food - Brown/Orange
        else if lowercased.contains("cook") || lowercased.contains("meal") || lowercased.contains("烹飪") {
            return Color.brown
        }

        // Health - Red
        else if lowercased.contains("doctor") || lowercased.contains("hospital") || lowercased.contains("medicine") ||
                lowercased.contains("醫生") || lowercased.contains("醫院") {
            return Color.red
        }

        // Travel - Teal
        else if lowercased.contains("flight") || lowercased.contains("fly") || lowercased.contains("drive") ||
                lowercased.contains("航班") || lowercased.contains("開車") {
            return Color.teal
        }

        // Finance - Green
        else if lowercased.contains("pay") || lowercased.contains("bank") || lowercased.contains("付款") || lowercased.contains("銀行") {
            return Color.green
        }

        // Entertainment - Pink
        else if lowercased.contains("movie") || lowercased.contains("music") || lowercased.contains("game") ||
                lowercased.contains("電影") || lowercased.contains("音樂") || lowercased.contains("遊戲") {
            return Color.pink
        }

        // Default - Red
        else {
            return Color.red
        }
    }
}
