# UserFeedbackKit

A reusable Swift Package for collecting user feedback and bug reports in iOS apps. Submits to Google Forms.

## Features

- **Feedback Mode**: Star rating (1-5) + text feedback
- **Bug Report Mode**: Text-only (no star rating)
- **Auto-prompts**: Trigger after N completions (configurable)
- **Manual triggers**: For Settings menu integration
- **Themeable**: Provide your own colors via `UserFeedbackTheme`
- **Customizable copy**: All strings are configurable

## Installation

### Swift Package Manager

Add to your Xcode project:
1. File → Add Package Dependencies
2. Enter: `https://github.com/YOUR_ORG/UserFeedbackKit` (or use local path)

Or add to `Package.swift`:
```swift
dependencies: [
    .package(path: "../UserFeedbackKit")  // Local path
    // OR
    .package(url: "https://github.com/YOUR_ORG/UserFeedbackKit", from: "1.0.0")
]
```

## Setup

### 1. Create Configuration

```swift
import UserFeedbackKit

let feedbackConfig = UserFeedbackConfig(
    // Google Form configuration
    formURL: "https://docs.google.com/forms/d/e/YOUR_FORM_ID/formResponse",
    entryRating: "entry.1234567890",      // Rating field entry ID
    entryType: "entry.1234567891",        // Type field (Feedback/Bug Report)
    entryMessage: "entry.1234567892",     // Message field
    entryEmail: "entry.1234567893",       // Email field (optional)
    entrySystemVersion: "entry.1234567894",
    entryAppIdentifier: "entry.1234567895",
    entryAppVersion: "entry.1234567896",

    // Your app identifier
    appIdentifier: "my-app",

    // Auto-prompt after these completion counts
    triggerCounts: [1, 3, 5],

    // Customize copy (optional)
    feedbackTitle: "How's your experience?",
    bugReportTitle: "Report a Bug"
)
```

### 2. Create Theme (Optional)

```swift
struct MyAppTheme: UserFeedbackTheme {
    var primaryColor: Color { Color("Primary") }
    var backgroundColor: Color { Color("Background") }
    var surfaceColor: Color { Color("Surface") }
    var textColor: Color { Color("Text") }
    var secondaryTextColor: Color { Color("TextSecondary") }
    var borderColor: Color { Color("Border") }
    var shadowColor: Color { .black }
}
```

### 3. Initialize Service

```swift
// In your App or as a shared instance
let feedbackService = UserFeedbackService(
    config: feedbackConfig,
    theme: MyAppTheme()
)
```

## Usage

### Add Overlay to Root View

```swift
@main
struct MyApp: App {
    @StateObject private var feedbackService = UserFeedbackService(
        config: feedbackConfig,
        theme: MyAppTheme()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .userFeedbackOverlay(service: feedbackService)
                .environmentObject(feedbackService)
        }
    }
}
```

### Auto-Prompt After Actions

```swift
// After completing a key action (analysis, session, etc.)
feedbackService.recordCompletion()

// At an appropriate moment (e.g., showing results)
feedbackService.presentAutoPromptIfNeeded()
```

### Settings Menu Integration

```swift
struct SettingsView: View {
    @EnvironmentObject var feedbackService: UserFeedbackService

    var body: some View {
        List {
            Section("Support") {
                Button {
                    feedbackService.presentFeedback()
                } label: {
                    Label("Leave Feedback", systemImage: "star.bubble")
                }

                Button {
                    feedbackService.presentBugReport()
                } label: {
                    Label("Report a Bug", systemImage: "ladybug")
                }
            }
        }
    }
}
```

## Google Form Setup

1. Create a Google Form with fields for:
   - Rating (number 1-5)
   - Type (short text: "Feedback" or "Bug Report")
   - Message (paragraph text)
   - Email (optional, short text)
   - System Version (short text)
   - App Identifier (short text)
   - App Version (short text)

2. Get the form response URL and entry IDs:
   - Open form → Get pre-filled link
   - Fill in test values and generate link
   - Extract `entry.XXXXXXXXX` IDs from the URL

## License

MIT
