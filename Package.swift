// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Elliotable",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "Elliotable",
            targets: ["Elliotable"]
        ),
    ],
    targets: [
        .target(
            name: "Elliotable",
            path: "Elliotable"
        )
    ]
)
