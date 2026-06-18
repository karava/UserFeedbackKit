import Foundation
import SwiftUI

public enum FeedbackMode {
    case feedback    // Star rating + text
    case bugReport   // Text only
}

/// Feedback event for analytics callbacks
public enum FeedbackEvent {
    case shown(mode: FeedbackMode, trigger: FeedbackTrigger)
    case submitted(mode: FeedbackMode, rating: Int, hasMessage: Bool)
    case dismissed(mode: FeedbackMode)
}

public enum FeedbackTrigger {
    case auto
    case manual
}

public final class UserFeedbackService: ObservableObject {
    /// Which screen the prompt is showing.
    public enum Phase {
        case form       // collecting input
        case success    // "sent" confirmation, just before auto-dismiss
    }

    // MARK: - Published State
    @Published public var isPromptPresented = false
    @Published public var phase: Phase = .form
    @Published public var currentMode: FeedbackMode = .feedback
    @Published public var rating: Int = 0
    @Published public var feedbackText: String = ""
    @Published public var email: String = ""

    /// How long the success confirmation stays up before the prompt dismisses.
    public var successDisplayDuration: TimeInterval = 1.4

    // MARK: - Configuration
    public let config: UserFeedbackConfig
    public let theme: UserFeedbackTheme

    // MARK: - Analytics Callback
    public var onEvent: ((FeedbackEvent) -> Void)?

    /// Optional app-supplied support code (e.g. an anonymous user id), evaluated at
    /// submit time and sent silently with the form submission. Never shown in the UI.
    public var supportCodeProvider: (() -> String?)?

    // MARK: - Storage Keys
    private var completionCountKey: String { "\(config.storageKeyPrefix)_completion_count" }
    private var pendingPromptKey: String { "\(config.storageKeyPrefix)_pending_prompt" }
    private var cachedEmailKey: String { "\(config.storageKeyPrefix)_cached_email" }

    // MARK: - Initialization

    public init(config: UserFeedbackConfig, theme: UserFeedbackTheme = DefaultFeedbackTheme()) {
        self.config = config
        self.theme = theme
    }

    // MARK: - Email Helpers

    /// A very light sanity check — enough to gate `requireEmail`, not RFC-strict.
    public var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".")
    }

    /// Resets transient state and loads the cached email — call before presenting.
    private func prepareForPresentation() {
        phase = .form
        guard config.collectEmail else { return }
        email = UserDefaults.standard.string(forKey: cachedEmailKey) ?? ""
    }

    // MARK: - Auto-Prompt Triggers

    /// Call this after a key action (e.g., completing an analysis, finishing a session)
    public func recordCompletion() {
        let count = completionCount + 1
        completionCount = count

        #if DEBUG
        pendingPrompt = true
        #else
        if config.triggerCounts.contains(count) {
            pendingPrompt = true
        }
        #endif
    }

    /// Call this at an appropriate moment to show the auto-triggered prompt
    public func presentAutoPromptIfNeeded() {
        guard pendingPrompt else { return }
        pendingPrompt = false
        prepareForPresentation()
        currentMode = .feedback
        isPromptPresented = true
        onEvent?(.shown(mode: .feedback, trigger: .auto))
    }

    // MARK: - Manual Triggers (for Settings menu)

    /// Manually show the feedback prompt (with star rating)
    public func presentFeedback() {
        prepareForPresentation()
        currentMode = .feedback
        isPromptPresented = true
        onEvent?(.shown(mode: .feedback, trigger: .manual))
    }

    /// Manually show the bug report prompt (no star rating)
    public func presentBugReport() {
        prepareForPresentation()
        currentMode = .bugReport
        isPromptPresented = true
        onEvent?(.shown(mode: .bugReport, trigger: .manual))
    }

    // MARK: - Actions

    public func dismiss() {
        onEvent?(.dismissed(mode: currentMode))
        isPromptPresented = false
        rating = 0
        feedbackText = ""
        email = ""
        phase = .form
    }

    public func submit() {
        let mode = currentMode
        let ratingValue = rating
        let hasMessage = !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        onEvent?(.submitted(mode: mode, rating: ratingValue, hasMessage: hasMessage))

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if config.collectEmail, !trimmedEmail.isEmpty {
            // Remember the email so repeat reporters don't have to retype it.
            UserDefaults.standard.set(trimmedEmail, forKey: cachedEmailKey)
        }

        let type = mode == .feedback ? "Feedback" : "Bug"
        sendToGoogleForm(
            type: type,
            rating: mode == .feedback ? ratingValue : nil,
            message: feedbackText,
            email: trimmedEmail,
            supportCode: supportCodeProvider?()?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        // Show the "sent" confirmation, then auto-dismiss so it doesn't feel abrupt.
        phase = .success
        DispatchQueue.main.asyncAfter(deadline: .now() + successDisplayDuration) { [weak self] in
            guard let self, self.phase == .success else { return }
            // Dismiss while the checkmark is still showing...
            self.isPromptPresented = false
            // ...then clear state once the card has animated out, so the form
            // doesn't flash back in mid-dismiss.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.resetForm()
            }
        }
    }

    /// Clears transient input after the prompt has been dismissed.
    private func resetForm() {
        phase = .form
        rating = 0
        feedbackText = ""
        email = ""
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

    private func sendToGoogleForm(type: String, rating: Int?, message: String, email: String, supportCode: String?) {
        guard let url = URL(string: config.formURL) else { return }

        let systemVersion = "iOS-\(ProcessInfo.processInfo.operatingSystemVersionString)"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        var components = URLComponents()
        var queryItems = [
            URLQueryItem(name: config.entryType, value: type),
            URLQueryItem(name: config.entryMessage, value: message),
            URLQueryItem(name: config.entryEmail, value: email),
            URLQueryItem(name: config.entrySystemVersion, value: systemVersion),
            URLQueryItem(name: config.entryAppIdentifier, value: config.appIdentifier),
            URLQueryItem(name: config.entryAppVersion, value: appVersion)
        ]

        // Silently attach the app-supplied support code when configured and available.
        if !config.entrySupportCode.isEmpty, let supportCode, !supportCode.isEmpty {
            queryItems.append(URLQueryItem(name: config.entrySupportCode, value: supportCode))
        }

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
