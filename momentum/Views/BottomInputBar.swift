import SwiftUI

struct BottomInputBar: View {
    @Binding var isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 12) {
            // Microphone icon
            Image(systemName: isRecording ? "mic.fill" : "mic.fill")
                .font(.system(size: 20))
                .foregroundStyle(isRecording ? .red : .gray.opacity(0.4))
                .frame(width: 24, height: 24)

            // Text
            Text(isRecording ? "Tap to stop recording" : "Hold to add task")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isRecording ? .red : .gray.opacity(0.5))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // White background
                RoundedRectangle(cornerRadius: 99)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

                // Pulsing ring during recording
                if isRecording {
                    RoundedRectangle(cornerRadius: 99)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                }
            }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .onTapGesture {
            // If already recording, tap to stop
            if isRecording {
                onStopRecording()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // Long press to start recording (only if not already recording)
            if !isRecording {
                onStartRecording()
            }
        })
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    pulseScale = 1.1
                }
            } else {
                pulseScale = 1.0
            }
        }
        .accessibilityElement()
        .accessibilityLabel(isRecording ? "Recording in progress" : "Add task by voice")
        .accessibilityHint(isRecording ? "Tap to stop recording and create task" : "Hold for 0.5 seconds to start recording")
    }
}
