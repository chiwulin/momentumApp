# Momentum - AI-Powered Todo App

A native iOS todo app built with SwiftUI featuring AI task breakdown, voice input, and beautiful animations.

## Features

### Core Features
- **AI Task Breakdown**: Long press (800ms) on any main task to automatically break it down into 2-4 smaller subtasks using OpenAI GPT-3.5-turbo
- **Voice Input**: Long press (500ms) on the bottom circular button to record voice and add tasks (supports Traditional Chinese)
- **Task Completion**: Tap the checkbox on subtask cards to mark as complete with visual feedback
- **Task Deletion**: Swipe left on main task cards to delete, or use the context menu
- **Vertical Subtask Layout**: Subtasks are displayed vertically below their parent task for easy viewing
- **Data Persistence**: All tasks are saved locally using SwiftData

### Design Highlights
- iOS-native aesthetic with glassmorphism effects
- SF Pro and SF Pro Rounded fonts throughout
- Smooth animations with spring physics
- Haptic feedback on all interactions
- Light and dark mode support
- Responsive layout for all iPhone sizes
- Full VoiceOver accessibility support

### Animations
- Cell division animation when AI breakdown completes
- Completion animation with subtask reordering
- Progress bar during long press actions
- Scale feedback on all interactive elements

## Setup

### 1. Clone the Repository
```bash
git clone https://github.com/chiwulin/momentumApp.git
cd momentumApp
```

### 2. Configure OpenAI API Key

**IMPORTANT**: Never commit your API key to git!

The app requires an OpenAI API key to use the AI task breakdown feature. Set it up in Xcode:

1. Open `momentum.xcodeproj` in Xcode
2. Select the **momentum** scheme (top bar, next to your device)
3. Click **Edit Scheme...**
4. Select **Run** > **Arguments**
5. Under **Environment Variables**, find `OPENAI_API_KEY`
6. Paste your OpenAI API key in the **Value** field
7. Click **Close**

Your API key will be stored locally in your Xcode user data (not in git).

**Get an OpenAI API Key:**
- Visit https://platform.openai.com/api-keys
- Create a new secret key
- Copy and paste it into Xcode as described above

### 3. Build and Run
- Open the project in Xcode 16.4+
- Select an iOS 18.5+ simulator or device
- Press ⌘R to build and run

## Requirements

- iOS 18.5+
- Xcode 16.4+
- OpenAI API key (for task breakdown feature)

## Setup

### 1. Clone the Repository

```bash
cd /path/to/your/projects
# The project is already in /Users/chiwulin/Documents/momentum
```

### 2. Set Up OpenAI API Key

You have several options for setting up your OpenAI API key:

#### Option A: Environment Variable (Recommended for Development)
```bash
export OPENAI_API_KEY="your-api-key-here"
```

Then run the app from Xcode.

#### Option B: In Code (Not Recommended for Production)
Edit `momentum/Services/OpenAIService.swift` and modify the init method:

```swift
init(apiKey: String = "your-api-key-here") {
    self.apiKey = apiKey.isEmpty ? ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "" : apiKey
}
```

#### Option C: Secure Storage (Recommended for Production)
For production apps, store the API key in Keychain or use a secure backend service.

### 3. Grant Permissions

When you first run the app, you'll be prompted to grant:
- **Microphone Access**: Required for voice input
- **Speech Recognition**: Required for transcribing voice to text

These permissions can be managed in Settings > Privacy & Security.

### 4. Build and Run

```bash
# Open in Xcode
open momentum.xcodeproj

# Or build from command line
xcodebuild -project momentum.xcodeproj -scheme momentum -configuration Debug -sdk iphonesimulator build
```

## Usage

### Adding Tasks

**Manual Entry:**
1. Tap the blue "+" button at the bottom
2. Enter your task title
3. Tap "Add"

**Voice Input:**
1. Long press (500ms) the blue microphone button at the bottom
2. Speak your task (supports Traditional Chinese and English)
3. Release to add the task

### Breaking Down Tasks

1. Long press (800ms) on any main task card
2. Wait for the AI to analyze and break down the task
3. Subtasks will appear below the main task with estimated durations

### Completing Subtasks

1. Long press (1000ms) on a subtask card
2. Watch the progress bar fill from left to right
3. Release when complete - the subtask will turn green and move to the bottom

### Deleting Tasks

1. Tap the trash icon on the right side of any main task card
2. The task and all its subtasks will be deleted

## Project Structure

```
momentum/
├── Models/
│   └── TaskItem.swift              # SwiftData model
├── Services/
│   ├── OpenAIService.swift         # AI task breakdown
│   └── SpeechRecognitionService.swift  # Voice recognition
├── Views/
│   ├── MainTaskCard.swift          # Main task UI component
│   ├── SubtaskCard.swift           # Subtask UI component
│   └── VoiceInputButton.swift      # Voice input button
├── Utilities/
│   └── HapticManager.swift         # Haptic feedback helper
├── ContentView.swift               # Main app view
└── momentumApp.swift               # App entry point
```

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

- **Models**: SwiftData models for data persistence
- **Views**: SwiftUI views with reusable components
- **Services**: Business logic for AI and speech recognition
- **Utilities**: Helper classes for haptics and other shared functionality

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's persistence framework
- **Speech Framework**: Native speech recognition
- **OpenAI API**: GPT-3.5-turbo for task breakdown
- **Combine**: Reactive programming for state management

## Customization

### Adjusting Long Press Durations

Edit the long press durations in:
- **Voice Input**: `VoiceInputButton.swift` - line with `LongPressGesture(minimumDuration: 0.5)`
- **Task Breakdown**: `MainTaskCard.swift` - line with `LongPressGesture(minimumDuration: 0.8)`
- **Task Completion**: `SubtaskCard.swift` - line with `LongPressGesture(minimumDuration: 1.0)`

### Changing Animation Parameters

Animations use spring physics. Adjust in `ContentView.swift`:
```swift
withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
    // Animation code
}
```

### Customizing Subtask Width

Edit the `cardWidth` computed property in `SubtaskCard.swift`:
```swift
private var cardWidth: CGFloat {
    switch subtask.estimatedMinutes {
    case ..<10: return 180   // 5 mins
    case 10..<20: return 240 // 10 mins
    case 20..<30: return 300 // 15 mins
    default: return 360      // 30+ mins
    }
}
```

## Troubleshooting

### OpenAI API Errors

**Error: "OpenAI API key is missing"**
- Make sure you've set the `OPENAI_API_KEY` environment variable
- Or hardcode it in `OpenAIService.swift` for testing

**Error: "OpenAI API error: 401"**
- Your API key is invalid
- Check your OpenAI account and generate a new key

### Speech Recognition Issues

**Error: "Speech recognition authorization denied"**
- Go to Settings > Privacy & Security > Speech Recognition
- Enable speech recognition for the Momentum app

**Error: "Microphone permission denied"**
- Go to Settings > Privacy & Security > Microphone
- Enable microphone access for the Momentum app

### Build Errors

**Error: "Multiple commands produce Info.plist"**
- This has been fixed by removing the manual Info.plist
- Privacy permissions are now in the project build settings

## Privacy

- All task data is stored locally on your device using SwiftData
- Voice recordings are processed by Apple's Speech Recognition API
- Task breakdowns are sent to OpenAI's API (requires internet connection)
- No task data is stored on remote servers (except for the brief API call to OpenAI)

## License

This project is for demonstration purposes. Feel free to use and modify as needed.

## Credits

Built with SwiftUI and powered by:
- OpenAI GPT-3.5-turbo
- Apple's Speech Recognition Framework
- SF Pro and SF Pro Rounded fonts
