import Foundation
import SwiftUI

public enum FeedbackMode {
    case feedback    // Star rating + text
    case bugReport   // Text only
}

public final class UserFeedbackService: ObservableObject {
    // MARK: - Published State
    @Published public var isPromptPresented = false
    @Published public var currentMode: FeedbackMode = .feedback
    @Published public var rating: Int = 0
    @Published public var feedbackText: String = ""

    // MARK: - Configuration
    public let config: UserFeedbackConfig
    public let theme: UserFeedbackTheme

    // MARK: - Storage Keys
    private var completionCountKey: String { "\(config.storageKeyPrefix)_completion_count" }
    private var pendingPromptKey: String { "\(config.storageKeyPrefix)_pending_prompt" }

    // MARK: - Initialization

    public init(config: UserFeedbackConfig, theme: UserFeedbackTheme = DefaultFeedbackTheme()) {
        self.config = config
        self.theme = theme
    }

    // MARK: - Auto-Prompt Triggers

    /// Call this after a key action (e.g., completing an analysis, finishing a session)
    public func recordCompletion() {
        let count = completionCount + 1
        completionCount = count

        print("🔍 [UserFeedbackKit] recordCompletion: count=\(count), triggerCounts=\(config.triggerCounts)")

        #if DEBUG
        print("🔍 [UserFeedbackKit] DEBUG mode - setting pendingPrompt=true")
        pendingPrompt = true
        #else
        if config.triggerCounts.contains(count) {
            print("🔍 [UserFeedbackKit] RELEASE mode - count in triggerCounts, setting pendingPrompt=true")
            pendingPrompt = true
        } else {
            print("🔍 [UserFeedbackKit] RELEASE mode - count NOT in triggerCounts")
        }
        #endif

        print("🔍 [UserFeedbackKit] recordCompletion done: pendingPrompt=\(pendingPrompt)")
    }

    /// Call this at an appropriate moment to show the auto-triggered prompt
    public func presentAutoPromptIfNeeded() {
        print("🔍 [UserFeedbackKit] presentAutoPromptIfNeeded: pendingPrompt=\(pendingPrompt)")
        guard pendingPrompt else {
            print("🔍 [UserFeedbackKit] pendingPrompt is false, returning early")
            return
        }
        pendingPrompt = false
        currentMode = .feedback
        isPromptPresented = true
        print("🔍 [UserFeedbackKit] Set isPromptPresented=true")
    }

    // MARK: - Manual Triggers (for Settings menu)

    /// Manually show the feedback prompt (with star rating)
    public func presentFeedback() {
        currentMode = .feedback
        isPromptPresented = true
    }

    /// Manually show the bug report prompt (no star rating)
    public func presentBugReport() {
        currentMode = .bugReport
        isPromptPresented = true
    }

    // MARK: - Actions

    public func dismiss() {
        isPromptPresented = false
        rating = 0
        feedbackText = ""
    }

    public func submit() {
        let type = currentMode == .feedback ? "Feedback" : "Bug"
        sendToGoogleForm(type: type, rating: currentMode == .feedback ? rating : nil, message: feedbackText)
        dismiss()
    }

    // MARK: - Private Storage

    private var completionCount: Int {
        get { UserDefaults.standard.integer(forKey: completionCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: completionCountKey) }
    }

    private var pendingPrompt: Bool {
        get { UserDefaults.standard.bool(forKey: pendingPromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: pendingPromptKey) }
    }

    // MARK: - Google Form Submission

    private func sendToGoogleForm(type: String, rating: Int?, message: String) {
        guard let url = URL(string: config.formURL) else { return }

        let systemVersion = "iOS-\(ProcessInfo.processInfo.operatingSystemVersionString)"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        var components = URLComponents()
        var queryItems = [
            URLQueryItem(name: config.entryType, value: type),
            URLQueryItem(name: config.entryMessage, value: message),
            URLQueryItem(name: config.entryEmail, value: ""),
            URLQueryItem(name: config.entrySystemVersion, value: systemVersion),
            URLQueryItem(name: config.entryAppIdentifier, value: config.appIdentifier),
            URLQueryItem(name: config.entryAppVersion, value: appVersion)
        ]

        // Only include rating for feedback (not bug reports)
        if let rating = rating {
            queryItems.insert(URLQueryItem(name: config.entryRating, value: "\(rating)"), at: 0)
        }

        components.queryItems = queryItems

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        URLSession.shared.dataTask(with: request).resume()
    }
}
