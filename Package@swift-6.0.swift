// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let emailAddress: Self = "EmailAddress"
    static let favicon: Self = "Favicon"
    static let sitemap: Self = "Sitemap"
    static let swiftWeb: Self = "SwiftWeb"
    static let urlFormCoding: Self = "UrlFormCoding"
}

extension Target.Dependency {
    static var emailAddress: Self { .target(name: .emailAddress) }
    static var favicon: Self { .target(name: .favicon) }
    static var sitemap: Self { .target(name: .sitemap) }
    static var swiftWeb: Self { .target(name: .swiftWeb) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

extension Target.Dependency {
    static var appSecret: Self { .product(name: "AppSecret", package: "pointfree-web") }
    static var database: Self { .product(name: "DatabaseHelpers", package: "pointfree-web") }
    static var decodableRequest: Self { .product(name: "DecodableRequest", package: "pointfree-web") }
//    static var emailAddress: Self { .product(name: "EmailAddress", package: "pointfree-web") }
    static var foundationPrelude: Self { .product(name: "FoundationPrelude", package: "pointfree-web") }
    static var httpPipeline: Self { .product(name: "HttpPipeline", package: "pointfree-web") }
    static var nioDependencies: Self { .product(name: "NIODependencies", package: "pointfree-web") }
    static var urlFormEncoding: Self { .product(name: "UrlFormEncoding", package: "pointfree-web") }
    static var mediaType: Self { .product(name: "MediaType", package: "pointfree-web") }
    static var loggingDependencies: Self { .product(name: "LoggingDependencies", package: "pointfree-web") }
}
extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var either: Self { .product(name: "Either", package: "swift-prelude") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
    static var postgresKit: Self { .product(name: "PostgresKit", package: "postgres-kit") }
    static var optics: Self { .product(name: "Optics", package: "swift-prelude") }
    static var swiftHtml: Self { .product(name: "HTML", package: "swift-html") }
    static var prelude: Self { .product(name: "Prelude", package: "swift-prelude") }
    static var tagged: Self { .product(name: "Tagged", package: "swift-tagged") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
    static var swiftDate: Self { .product(name: "Date", package: "swift-date") }
//    static var pointfreeWeb: Self { .product(name: "PointfreeWeb", package: "pointfree-web") }
}

extension [Package.Dependency] {
    static var `default`: Self {
        [
            .package(url: "https://github.com/coenttb/swift-html", branch: "main"),
            .package(url: "https://github.com/coenttb/swift-date", branch: "main"),
            .package(url: "https://github.com/coenttb/pointfree-web", branch: "main"),
            .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
            .package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
            .package(url: "https://github.com/pointfreeco/swift-prelude.git", branch: "main"),
            .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0"),
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
        .library(name: .emailAddress, targets: [.emailAddress]),
        .library(name: .favicon, targets: [.favicon]),
        .library(name: .sitemap, targets: [.sitemap]),
        .library(name: .urlFormCoding, targets: [.urlFormCoding]),
    ],
    dependencies: .default,
    targets: [
        .target(
            name: .emailAddress,
            dependencies: [
            ]
        ),
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
                .urlFormEncoding,
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
                .swiftDate,
                .swiftHtml,
                .emailAddress,
                .favicon,
                .sitemap,
                .urlFormCoding,
                .appSecret,
                .database,
                .decodableRequest,
                .foundationPrelude,
                .httpPipeline,
                .nioDependencies,
                .urlFormEncoding,
                .mediaType,
                .loggingDependencies,
            ]
        ),
        .testTarget(
            name: .emailAddress + " Tests",
            dependencies: [
                .emailAddress
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
