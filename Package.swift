// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UserFeedbackKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "UserFeedbackKit",
            targets: ["UserFeedbackKit"]
        ),
    ],
    targets: [
        .target(
            name: "UserFeedbackKit"
        ),
    ]
)
