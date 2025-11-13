import SwiftUI

struct VoiceInputButton: View {
    @Binding var isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulsing ring during recording
            if isRecording {
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 4)
                    .frame(width: 72, height: 72)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                            pulseScale = 1.5
                        }
                    }
                    .onDisappear {
                        pulseScale = 1.0
                    }
            }

            // Main button
            Circle()
                .fill(isRecording ? Color.red : Color.blue)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: isRecording)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    if !isRecording {
                        onStartRecording()
                    } else {
                        onStopRecording()
                    }
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
        .accessibilityElement()
        .accessibilityLabel(isRecording ? "Recording" : "Voice input")
        .accessibilityHint(isRecording ? "Long press to stop recording" : "Long press for 0.5 seconds to start recording")
    }
}
