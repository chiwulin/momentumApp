import SwiftUI

struct TestOpenAIView: View {
    @StateObject private var openAIService = OpenAIService()
    @State private var testTask = "Plan a birthday party"
    @State private var isLoading = false
    @State private var result = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("OpenAI API Test")
                .font(.title)
                .bold()

            TextField("Enter a task to break down", text: $testTask)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button(action: testAPI) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isLoading ? "Testing..." : "Test OpenAI API")
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding(.horizontal)

            if !errorMessage.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error:")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            if !result.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success! ✅")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text(result)
                        .font(.body)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    private func testAPI() {
        isLoading = true
        errorMessage = ""
        result = ""

        Task {
            do {
                let subtasks = try await openAIService.breakdownTask(testTask)

                await MainActor.run {
                    var resultText = "API is working! Got \(subtasks.count) subtasks:\n\n"
                    for (index, subtask) in subtasks.enumerated() {
                        resultText += "\(index + 1). \(subtask.title) (\(subtask.estimatedMinutes) mins)\n"
                    }
                    result = resultText
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    TestOpenAIView()
}
