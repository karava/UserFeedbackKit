import SwiftUI

public struct UserFeedbackPromptView: View {
    @ObservedObject var service: UserFeedbackService
    @FocusState private var messageFocused: Bool

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
        if config.requireEmail && !service.isEmailValid {
            return false
        }
        if service.currentMode == .bugReport {
            return !service.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return service.rating > 0 || !service.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public var body: some View {
        Group {
            switch service.phase {
            case .form:    formContent.transition(.opacity)
            case .success: successContent.transition(.opacity)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: service.phase)
    }

    // MARK: - Success Confirmation

    private var successContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundColor(theme.primaryColor)
                .transition(.scale.combined(with: .opacity))
            Text(config.successTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Form

    private var formContent: some View {
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
                    .focused($messageFocused)
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

            // Email (optional unless requireEmail is set) — lets us follow up.
            if config.collectEmail {
                TextField("", text: $service.email, prompt:
                    Text(config.emailPlaceholder).foregroundColor(theme.secondaryTextColor)
                )
                .foregroundColor(theme.textColor)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
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
        .onAppear {
            // Bug reports are message-first — pop the keyboard straight into the field.
            guard service.currentMode == .bugReport else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                messageFocused = true
            }
        }
    }
}
