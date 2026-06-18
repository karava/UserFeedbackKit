import SwiftUI

public struct UserFeedbackOverlayModifier: ViewModifier {
    @ObservedObject var service: UserFeedbackService

    public func body(content: Content) -> some View {
        ZStack {
            content

            if service.isPromptPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        service.dismiss()
                    }

                UserFeedbackPromptView(service: service)
                    .padding(.horizontal, 24)
                    // Ease in/out from a near-full scale so it glides rather than pops.
                    .transition(.scale(scale: 0.92, anchor: .center).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.92), value: service.isPromptPresented)
    }
}

public extension View {
    /// Adds a user feedback overlay that presents when triggered via the service
    func userFeedbackOverlay(service: UserFeedbackService) -> some View {
        modifier(UserFeedbackOverlayModifier(service: service))
    }
}
