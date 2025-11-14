import Foundation

struct SubtaskResponse: Codable {
    let title: String
    let estimatedMinutes: Int
}

struct IconResponse: Codable {
    let symbol: String
    let color: String
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let response_format: ResponseFormat?

    struct ResponseFormat: Codable {
        let type: String
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

@MainActor
class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(apiKey: String = "") {
        // In production, load from secure storage or environment
        // For now, you'll need to set this in the environment or in code
        self.apiKey = apiKey.isEmpty ? ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "" : apiKey
    }

    func breakdownTask(_ taskTitle: String) async throws -> [SubtaskResponse] {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let systemPrompt = """
        You are a task breakdown assistant. Break down the given task into 2-4 smaller actionable subtasks.
        Each subtask should take 15-60 minutes to complete.

        You MUST respond with valid JSON in this exact format:
        {
          "subtasks": [
            {"title": "First subtask name", "estimatedMinutes": 20},
            {"title": "Second subtask name", "estimatedMinutes": 30}
          ]
        }

        Rules:
        - Always use the key "subtasks" (not "tasks" or anything else)
        - Each subtask must have "title" and "estimatedMinutes" fields
        - estimatedMinutes should be between 15 and 60
        - Provide 2-4 subtasks
        """

        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: "Break down this task: \(taskTitle)")
            ],
            temperature: 0.7,
            response_format: OpenAIRequest.ResponseFormat(type: "json_object")
        )

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30 // 30 second timeout

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let error as NSError {
            // Network error - provide more details
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    throw OpenAIError.networkError("No internet connection. Please check your network settings.")
                case NSURLErrorTimedOut:
                    throw OpenAIError.networkError("Request timed out. Please try again.")
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    throw OpenAIError.networkError("Cannot connect to OpenAI servers. Please check your internet connection.")
                case NSURLErrorNetworkConnectionLost:
                    throw OpenAIError.networkError("Network connection was lost. Please check your internet and try again.")
                case NSURLErrorSecureConnectionFailed:
                    throw OpenAIError.networkError("Secure connection failed. This might be a firewall or VPN issue.")
                default:
                    throw OpenAIError.networkError("Network error: \(error.localizedDescription)")
                }
            }
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiErrorWithMessage(statusCode: httpResponse.statusCode, message: message)
            }
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }

        // Parse the JSON content
        guard let contentData = content.data(using: .utf8) else {
            throw OpenAIError.invalidFormat
        }

        // Try to parse the JSON
        guard let jsonObject = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            // Maybe it's directly an array?
            if let subtasks = try? JSONDecoder().decode([SubtaskResponse].self, from: contentData) {
                return subtasks
            }
            throw OpenAIError.invalidFormat
        }

        // Try different possible keys
        var subtasksArray: [[String: Any]]?

        if let array = jsonObject["subtasks"] as? [[String: Any]] {
            subtasksArray = array
        } else if let array = jsonObject["tasks"] as? [[String: Any]] {
            subtasksArray = array
        } else if let array = jsonObject["items"] as? [[String: Any]] {
            subtasksArray = array
        } else {
            // Maybe the whole object is a wrapper, try to find any array
            for (_, value) in jsonObject {
                if let array = value as? [[String: Any]] {
                    subtasksArray = array
                    break
                }
            }
        }

        guard let tasksArray = subtasksArray else {
            throw OpenAIError.invalidFormatWithDetails("Could not find subtasks array in JSON: \(content)")
        }

        let subtasks = tasksArray.compactMap { dict -> SubtaskResponse? in
            // Try different field names
            let title = dict["title"] as? String ??
                       dict["name"] as? String ??
                       dict["task"] as? String ??
                       dict["description"] as? String

            let minutes = dict["estimatedMinutes"] as? Int ??
                         dict["estimated_minutes"] as? Int ??
                         dict["duration"] as? Int ??
                         dict["time"] as? Int ??
                         30 // Default

            guard let taskTitle = title else { return nil }
            return SubtaskResponse(title: taskTitle, estimatedMinutes: minutes)
        }

        guard !subtasks.isEmpty else {
            throw OpenAIError.invalidFormatWithDetails("No valid subtasks found in JSON: \(content)")
        }

        return subtasks
    }

    func selectIcon(for taskTitle: String) async throws -> IconResponse {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let systemPrompt = """
        You are an SF Symbols expert. Given a task title, select the most appropriate SF Symbol icon and color.

        You MUST respond with valid JSON in this exact format:
        {
          "symbol": "sf.symbol.name",
          "color": "colorName"
        }

        Rules for SF Symbols:
        - Use actual SF Symbol names (e.g., "figure.golf", "cart.fill", "envelope.fill")
        - Common symbols: checkmark, phone.fill, message.fill, envelope.fill, calendar, cart.fill,
          fork.knife, car.fill, airplane, book.fill, pencil, magnifyingglass, person.2.fill,
          video.fill, dollarsign.circle.fill, film.fill, music.note, gamecontroller.fill,
          figure.run, figure.golf, wrench.fill, cross.case.fill, sparkles
        - Default to "checkmark" if unsure

        Rules for colors (use these exact names):
        - "orange" for sports, exercise, fitness
        - "blue" for communication, calls, messages, emails
        - "purple" for work, productivity, writing, coding
        - "green" for shopping, finance, money
        - "brown" for food, cooking
        - "red" for health, medical, urgent tasks
        - "teal" for travel, transportation
        - "pink" for entertainment, leisure
        - Default to "red" if unsure
        """

        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: "Select icon for task: \(taskTitle)")
            ],
            temperature: 0.3,
            response_format: OpenAIRequest.ResponseFormat(type: "json_object")
        )

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 10 // Shorter timeout for icon selection

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiErrorWithMessage(statusCode: httpResponse.statusCode, message: message)
            }
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw OpenAIError.noContent
        }

        let iconResponse = try JSONDecoder().decode(IconResponse.self, from: contentData)
        return iconResponse
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    case apiErrorWithMessage(statusCode: Int, message: String)
    case noContent
    case invalidFormat
    case invalidFormatWithDetails(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please set it in environment variables."
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let statusCode):
            return "OpenAI API error: \(statusCode)"
        case .apiErrorWithMessage(let statusCode, let message):
            if statusCode == 429 {
                return "Rate limit exceeded. This usually means:\n• Free trial expired - Add payment method at platform.openai.com\n• No credits - Add credits to your account\n• Too many requests - Wait a few moments\n\nDetails: \(message)"
            }
            return "OpenAI API error \(statusCode): \(message)"
        case .noContent:
            return "No content in OpenAI response"
        case .invalidFormat:
            return "Invalid response format from OpenAI"
        case .invalidFormatWithDetails(let details):
            return "Invalid response format from OpenAI.\n\nDetails: \(details)"
        case .networkError(let message):
            return "🌐 Network Error\n\n\(message)\n\nTroubleshooting:\n• Check your WiFi/cellular connection\n• Try disabling VPN if you're using one\n• Make sure you're not on a restricted network (some schools/offices block AI services)\n• Try again in a few moments"
        }
    }
}
