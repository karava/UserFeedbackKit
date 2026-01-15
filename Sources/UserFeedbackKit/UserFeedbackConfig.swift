import Foundation

public struct UserFeedbackConfig {
    // MARK: - Google Form Configuration
    public let formURL: String
    public let entryRating: String
    public let entryType: String       // "Feedback" or "Bug Report"
    public let entryMessage: String
    public let entryEmail: String      // Optional user email field
    public let entrySystemVersion: String
    public let entryAppIdentifier: String
    public let entryAppVersion: String

    // MARK: - App Identification
    public let appIdentifier: String

    // MARK: - Auto-Prompt Triggers
    public let triggerCounts: [Int]    // e.g., [1, 3, 5] — prompt after these completion counts

    // MARK: - Customizable Copy
    public let feedbackTitle: String
    public let feedbackPlaceholder: String
    public let bugReportTitle: String
    public let bugReportPlaceholder: String
    public let submitButtonText: String
    public let cancelButtonText: String

    // MARK: - UserDefaults Keys (namespaced per app)
    public let storageKeyPrefix: String

    public init(
        formURL: String,
        entryRating: String,
        entryType: String,
        entryMessage: String,
        entryEmail: String,
        entrySystemVersion: String,
        entryAppIdentifier: String,
        entryAppVersion: String,
        appIdentifier: String,
        triggerCounts: [Int] = [1, 3, 5],
        feedbackTitle: String = "How's your experience?",
        feedbackPlaceholder: String = "Tell us what you liked or what we can improve...",
        bugReportTitle: String = "Report a Bug",
        bugReportPlaceholder: String = "Please describe the issue you encountered...",
        submitButtonText: String = "Submit",
        cancelButtonText: String = "Not Now",
        storageKeyPrefix: String = "user_feedback"
    ) {
        self.formURL = formURL
        self.entryRating = entryRating
        self.entryType = entryType
        self.entryMessage = entryMessage
        self.entryEmail = entryEmail
        self.entrySystemVersion = entrySystemVersion
        self.entryAppIdentifier = entryAppIdentifier
        self.entryAppVersion = entryAppVersion
        self.appIdentifier = appIdentifier
        self.triggerCounts = triggerCounts
        self.feedbackTitle = feedbackTitle
        self.feedbackPlaceholder = feedbackPlaceholder
        self.bugReportTitle = bugReportTitle
        self.bugReportPlaceholder = bugReportPlaceholder
        self.submitButtonText = submitButtonText
        self.cancelButtonText = cancelButtonText
        self.storageKeyPrefix = storageKeyPrefix
    }
}
