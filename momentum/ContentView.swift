import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.orderIndex) private var tasks: [TaskItem]

    @StateObject private var openAIService = OpenAIService()
    @StateObject private var speechService = SpeechRecognitionService()

    @State private var showAddTaskAlert = false
    @State private var newTaskTitle = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var breakingDownTaskId: UUID?
    @State private var showAPITest = false

    var body: some View {
        ZStack {
            // Background - clean light gradient
            LinearGradient(
                colors: [Color.white, Color.gray.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Title with API test button
                HStack {
                    Text("Today")
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(.gray.opacity(0.15))

                    Spacer()

                    // API Test Button (temporary)
                    Button(action: {
                        showAPITest = true
                    }) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.gray.opacity(0.3))
                            .padding(8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)

                // Task list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mainTasks) { task in
                            VStack(alignment: .leading, spacing: 12) {
                                MainTaskCard(
                                    task: task,
                                    onDelete: {
                                        deleteTask(task)
                                    },
                                    onLongPress: {
                                        breakdownTask(task)
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // Subtasks - displayed vertically
                                let subtasks = task.sortedSubtasks
                                if !subtasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(subtasks) { subtask in
                                            SubtaskCard(
                                                subtask: subtask,
                                                onComplete: {
                                                    completeSubtask(subtask)
                                                }
                                            )
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }

                Spacer()
            }

            // Bottom input bar
            VStack {
                Spacer()

                BottomInputBar(
                    isRecording: $speechService.isRecording,
                    onStartRecording: {
                        startVoiceInput()
                    },
                    onStopRecording: {
                        stopVoiceInput()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }

            // Loading indicator
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
        .alert("Add New Task", isPresented: $showAddTaskAlert) {
            TextField("Task title", text: $newTaskTitle)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {
                newTaskTitle = ""
            }
            Button("Add") {
                addTask(title: newTaskTitle)
                newTaskTitle = ""
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await requestPermissions()
        }
        .sheet(isPresented: $showAPITest) {
            TestOpenAIView()
        }
    }

    private var mainTasks: [TaskItem] {
        tasks.filter { !$0.isSubtask }
    }

    private func requestPermissions() async {
        let speechAuthorized = await speechService.requestAuthorization()
        let micAuthorized = await speechService.requestMicrophonePermission()

        if !speechAuthorized || !micAuthorized {
            errorMessage = "Please grant speech recognition and microphone permissions in Settings."
            showError = true
        }
    }

    private func addTask(title: String) {
        guard !title.isEmpty else { return }

        let task = TaskItem(
            title: title,
            orderIndex: tasks.count
        )
        modelContext.insert(task)

        do {
            try modelContext.save()
            HapticManager.shared.mediumImpact()
        } catch {
            errorMessage = "Failed to save task: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteTask(_ task: TaskItem) {
        HapticManager.shared.mediumImpact()

        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(task)

            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to delete task: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func breakdownTask(_ task: TaskItem) {
        // Prevent multiple simultaneous breakdowns
        guard breakingDownTaskId == nil else { return }
        guard task.subtasks?.isEmpty ?? true else { return }

        HapticManager.shared.mediumImpact()
        task.isBreakingDown = true
        breakingDownTaskId = task.id
        isLoading = true

        Task {
            do {
                let subtaskResponses = try await openAIService.breakdownTask(task.title)

                await MainActor.run {
                    // Create subtasks with animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        for (index, response) in subtaskResponses.enumerated() {
                            let subtask = TaskItem(
                                title: response.title,
                                isSubtask: true,
                                parentId: task.id,
                                estimatedMinutes: response.estimatedMinutes,
                                orderIndex: index
                            )
                            subtask.parent = task
                            modelContext.insert(subtask)
                        }

                        task.isBreakingDown = false
                        breakingDownTaskId = nil
                        isLoading = false

                        do {
                            try modelContext.save()
                            HapticManager.shared.success()
                        } catch {
                            errorMessage = "Failed to save subtasks: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    task.isBreakingDown = false
                    breakingDownTaskId = nil
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func completeSubtask(_ subtask: TaskItem) {
        HapticManager.shared.lightImpact()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            subtask.completed = true

            do {
                try modelContext.save()
                HapticManager.shared.success()
            } catch {
                errorMessage = "Failed to update subtask: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func startVoiceInput() {
        HapticManager.shared.mediumImpact()

        do {
            try speechService.startRecording()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }

    private func stopVoiceInput() {
        HapticManager.shared.mediumImpact()

        let transcribedText = speechService.stopRecording()

        if !transcribedText.isEmpty {
            addTask(title: transcribedText)
            HapticManager.shared.success()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
