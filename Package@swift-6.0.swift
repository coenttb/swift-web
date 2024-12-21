// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let favicon: Self = "Favicon"
    static let sitemap: Self = "Sitemap"
    static let swiftWeb: Self = "SwiftWeb"
    static let urlFormCoding: Self = "UrlFormCoding"
}

extension Target.Dependency {
    static var favicon: Self { .target(name: .favicon) }
    static var sitemap: Self { .target(name: .sitemap) }
    static var swiftWeb: Self { .target(name: .swiftWeb) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesMacros: Self { .product(name: "DependenciesMacros", package: "swift-dependencies") }
    static var either: Self { .product(name: "Either", package: "swift-prelude") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
    static var postgresKit: Self { .product(name: "PostgresKit", package: "postgres-kit") }
    static var optics: Self { .product(name: "Optics", package: "swift-prelude") }
    static var swiftHtml: Self { .product(name: "HTML", package: "swift-html") }
    static var prelude: Self { .product(name: "Prelude", package: "swift-prelude") }
    static var tagged: Self { .product(name: "Tagged", package: "swift-tagged") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
    static var pointfreeWeb: Self { .product(name: "PointfreeWeb", package: "pointfree-web") }
    
}

extension [Package.Dependency] {
    static var `default`: Self {
        [
            .package(url: "https://github.com/coenttb/swift-html", branch: "main"),
            .package(url: "https://github.com/coenttb/pointfree-web", branch: "main"),
            .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
            .package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
            .package(url: "https://github.com/pointfreeco/swift-prelude.git", branch: "main"),
            .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0"),
            .package(url: "https://github.com/swift-server/async-http-client", from: "1.19.0"),
            .package(url: "https://github.com/vapor/postgres-kit", from: "2.12.0"),
        ]
    }
}

let package = Package(
    name: "swift-web",
    platforms: [
        .macOS(.v14),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: .swiftWeb,
            targets: [
                .swiftWeb,
                .favicon,
                .sitemap,
                .urlFormCoding,
            ]
        ),
        .library(name: .favicon, targets: [.favicon]),
        .library(name: .sitemap, targets: [.sitemap]),
        .library(name: .urlFormCoding, targets: [.urlFormCoding]),
    ],
    dependencies: .default,
    targets: [
        .target(
            name: .favicon,
            dependencies: [
                .urlRouting,
                .swiftHtml
            ]
        ),
        .target(
            name: .urlFormCoding,
            dependencies: [
                .dependencies,
                .pointfreeWeb,
                .urlRouting
            ]
        ),
        .target(
            name: .sitemap,
            dependencies: [
            ]
        ),
        .target(
            name: .swiftWeb,
            dependencies: [
                .swiftHtml,
                .pointfreeWeb,
                .favicon,
                .sitemap,
                .urlFormCoding,
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
