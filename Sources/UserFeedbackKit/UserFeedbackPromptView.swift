import SwiftUI

public struct UserFeedbackPromptView: View {
    @ObservedObject var service: UserFeedbackService

    public init(service: UserFeedbackService) {
        self.service = service
    }

    private var theme: UserFeedbackTheme { service.theme }
    private var config: UserFeedbackConfig { service.config }

    private var title: String {
        service.currentMode == .feedback ? config.feedbackTitle : config.bugReportTitle
    }

    private var placeholder: String {
        service.currentMode == .feedback ? config.feedbackPlaceholder : config.bugReportPlaceholder
    }

    private var canSubmit: Bool {
        if service.currentMode == .bugReport {
            return !service.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return service.rating > 0 || !service.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(theme.textColor)

            // Star rating (only for feedback mode)
            if service.currentMode == .feedback {
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            service.rating = star
                        } label: {
                            Image(systemName: star <= service.rating ? "star.fill" : "star")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(theme.primaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Text input
            ZStack(alignment: .topLeading) {
                if service.feedbackText.isEmpty {
                    Text(placeholder)
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                }

                TextEditor(text: $service.feedbackText)
                    .foregroundColor(theme.textColor)
                    .padding(8)
                    .frame(height: 140)
                    .scrollContentBackground(.hidden)
                    .background(theme.surfaceColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.borderColor.opacity(0.6), lineWidth: 1)
                    )
            }

            // Buttons
            HStack(spacing: 12) {
                Button(config.cancelButtonText) {
                    service.dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.secondaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.surfaceColor)
                .cornerRadius(12)

                Button(config.submitButtonText) {
                    service.submit()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.backgroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canSubmit ? theme.primaryColor : theme.primaryColor.opacity(0.5))
                .cornerRadius(12)
                .disabled(!canSubmit)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(theme.backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.borderColor.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
