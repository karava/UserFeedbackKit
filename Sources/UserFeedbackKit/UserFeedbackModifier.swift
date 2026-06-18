import SwiftUI

public struct UserFeedbackOverlayModifier: ViewModifier {
    @ObservedObject var service: UserFeedbackService

    public func body(content: Content) -> some View {
        ZStack {
            content

            if service.isPromptPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        service.dismiss()
                    }

                UserFeedbackPromptView(service: service)
                    .padding(.horizontal, 24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: service.isPromptPresented)
    }
}

public extension View {
    /// Adds a user feedback overlay that presents when triggered via the service
    func userFeedbackOverlay(service: UserFeedbackService) -> some View {
        modifier(UserFeedbackOverlayModifier(service: service))
    }
}
