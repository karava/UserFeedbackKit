# UserFeedbackKit + App Store Review Implementation Guide

## Overview
Two separate systems for user feedback:
1. **UserFeedbackKit** - In-app feedback forms (star rating + text) triggered after specific completion counts
2. **RatingManager** - App Store review prompts triggered after paywall dismissal, with 30-day intervals

---

## 1. Add the Package
In Xcode: File → Add Package Dependencies → `https://github.com/karava/UserFeedbackKit`

---

## 2. Create FeedbackSetup.swift
Location: `Shared/Services/FeedbackSetup.swift`

```swift
import SwiftUI
import UserFeedbackKit

// MARK: - Theme (matches your app colors)
struct AppFeedbackTheme: UserFeedbackTheme {
    var primaryColor: Color { Colors.primary }
    var backgroundColor: Color { Colors.background }
    var surfaceColor: Color { Colors.surface }
    var textColor: Color { Colors.textPrimary }
    var secondaryTextColor: Color { Colors.textPrimary.opacity(0.6) }
    var borderColor: Color { Colors.textPrimary.opacity(0.1) }
    var shadowColor: Color { .black }
}

// MARK: - Configuration
extension UserFeedbackConfig {
    static let app = UserFeedbackConfig(
        formURL: "https://docs.google.com/forms/d/e/YOUR_FORM_ID/formResponse",
        entryRating: "entry.XXXXXXXXXX",
        entryType: "entry.XXXXXXXXXX",
        entryMessage: "entry.XXXXXXXXXX",
        entryEmail: "entry.XXXXXXXXXX",
        entrySystemVersion: "entry.XXXXXXXXXX",
        entryAppIdentifier: "entry.XXXXXXXXXX",
        entryAppVersion: "entry.XXXXXXXXXX",
        appIdentifier: "your-app-id",
        triggerCounts: [1, 3, 5],  // Shows on 1st, 3rd, 5th completion
        feedbackTitle: String(localized: "feedback_title"),
        feedbackPlaceholder: String(localized: "feedback_placeholder"),
        bugReportTitle: String(localized: "feedback_bug_title"),
        bugReportPlaceholder: String(localized: "feedback_bug_placeholder"),
        submitButtonText: String(localized: "feedback_submit"),
        cancelButtonText: String(localized: "feedback_cancel"),
        storageKeyPrefix: "your_app_feedback"
    )
}

// MARK: - Shared Instance
extension UserFeedbackService {
    static let shared = UserFeedbackService(
        config: .app,
        theme: AppFeedbackTheme()
    )
}
```

---

## 3. Create RatingManager.swift
Location: `Shared/Services/RatingManager.swift`

```swift
import StoreKit
import UIKit

final class RatingManager {
    static let shared = RatingManager()

    private let lastPromptKey = "ratings.lastPromptDate"
    private let promptCountKey = "ratings.promptCount"
    private let eventCountKey = "ratings.eventCount"
    private let minDaysBetweenPrompts = 30
    private let minEventsBeforePrompt = 1
    private let maxPromptCount = 3

    private init() {}

    func requestReviewIfAppropriate(reason: String) {
        let defaults = UserDefaults.standard
        let eventCount = defaults.integer(forKey: eventCountKey) + 1
        defaults.set(eventCount, forKey: eventCountKey)

        let promptCount = defaults.integer(forKey: promptCountKey)
        guard promptCount < maxPromptCount else { return }
        guard eventCount >= minEventsBeforePrompt else { return }

        if let lastPrompt = defaults.object(forKey: lastPromptKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard days >= minDaysBetweenPrompts else { return }
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        Analytics.shared.track(event: "review_requested", properties: [
            "reason": reason,
            "prompt_count": "\(promptCount + 1)"
        ])
        SKStoreReviewController.requestReview(in: scene)
        defaults.set(Date(), forKey: lastPromptKey)
        defaults.set(promptCount + 1, forKey: promptCountKey)
        defaults.set(0, forKey: eventCountKey)
    }
}
```

---

## 4. Add Overlay to App Root
In your main App file:

```swift
import UserFeedbackKit

var body: some Scene {
    WindowGroup {
        ContentView()
            .userFeedbackOverlay(service: .shared)
    }
}
```

---

## 5. Add Overlay to Full Screen Covers
Any `fullScreenCover` that might trigger feedback needs its own overlay:

```swift
import UserFeedbackKit

struct PlayerView: View {
    var body: some View {
        // ... view content
        .userFeedbackOverlay(service: .shared)
    }
}
```

---

## 6. Trigger Feedback After Completions
In your ViewModel after a successful completion:

```swift
import UserFeedbackKit

// Record completion and show prompt (with delay for UI)
UserFeedbackService.shared.recordCompletion()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    UserFeedbackService.shared.presentAutoPromptIfNeeded()
}
```

**Note:** In DEBUG builds, feedback shows on every completion. In Release, it respects `triggerCounts`.

---

## 7. Trigger App Store Review After Paywall
In your onboarding/paywall handler:

```swift
let handler = PaywallPresentationHandler()
handler.onDismiss { _, _ in
    RatingManager.shared.requestReviewIfAppropriate(reason: "paywall_dismissed")
}
Superwall.shared.register(placement: "your_placement", handler: handler)
```

---

## 8. Add Manual Feedback/Bug Report in Settings

```swift
import UserFeedbackKit

PreferenceRow(title: "Leave Feedback", icon: "bubble.left.and.bubble.right.fill")
    .onTapGesture {
        UserFeedbackService.shared.presentFeedback()
    }

PreferenceRow(title: "Report a Bug", icon: "ladybug.fill")
    .onTapGesture {
        UserFeedbackService.shared.presentBugReport()
    }
```

---

## 9. Localization Keys Needed
```
feedback_title = "How's your experience?"
feedback_placeholder = "Tell us what you liked or what we can improve..."
feedback_bug_title = "Report a Bug"
feedback_bug_placeholder = "Please describe the issue you encountered..."
feedback_submit = "Submit"
feedback_cancel = "Not Now"
leave_feedback = "Leave Feedback"
report_bug = "Report a Bug"
```

---

## Flow Summary

| Trigger | Action | System |
|---------|--------|--------|
| Task completion (1st, 3rd, 5th) | Feedback form | UserFeedbackKit |
| Settings → Leave Feedback | Feedback form | UserFeedbackKit |
| Settings → Report a Bug | Bug report form | UserFeedbackKit |
| Paywall dismissed | App Store review | RatingManager (30-day interval, max 3) |
