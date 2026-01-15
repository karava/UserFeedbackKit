import SwiftUI

public protocol UserFeedbackTheme {
    var primaryColor: Color { get }
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }
    var borderColor: Color { get }
    var shadowColor: Color { get }
}

// MARK: - Default Theme

public struct DefaultFeedbackTheme: UserFeedbackTheme {
    public var primaryColor: Color { .blue }
    public var backgroundColor: Color { Color(.systemBackground) }
    public var surfaceColor: Color { Color(.secondarySystemBackground) }
    public var textColor: Color { Color(.label) }
    public var secondaryTextColor: Color { Color(.secondaryLabel) }
    public var borderColor: Color { Color(.separator) }
    public var shadowColor: Color { .black }

    public init() {}
}
