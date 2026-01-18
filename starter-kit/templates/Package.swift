// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MyAppLib", targets: ["MyAppLib"])
    ],
    targets: [
        // Uncomment if using external xcframework:
        // .binaryTarget(
        //     name: "MyFramework",
        //     path: "Frameworks/MyFramework.xcframework"
        // ),
        .target(
            name: "MyAppLib",
            // dependencies: ["MyFramework"],
            path: "MyApp",
            resources: [.copy("Resources")]
        )
    ]
)
