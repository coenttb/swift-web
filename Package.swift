// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let favicon: Self = "Favicon"
    static let webDate: Self = "Web Date"
    static let unixEpoch: Self = "UnixEpoch"
    static let sitemap: Self = "Sitemap"
    static let swiftWeb: Self = "Swift Web"
    static let urlFormCoding: Self = "UrlFormCoding"
}

extension Target.Dependency {
    static var favicon: Self { .target(name: .favicon) }
    static var webDate: Self { .target(name: .webDate) }
    static var unixEpoch: Self { .target(name: .unixEpoch) }
    static var sitemap: Self { .target(name: .sitemap) }
    static var swiftWeb: Self { .target(name: .swiftWeb) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

extension Target.Dependency {
    static var emailAddress: Self { .product(name: "EmailAddress", package: "swift-emailaddress-type") }
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesTestSupport: Self { .product(name: "DependenciesTestSupport", package: "swift-dependencies") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
    static var mediaType: Self { .product(name: "MediaType", package: "pointfree-web") }
    static var parsing: Self { .product(name: "Parsing", package: "swift-parsing") }
    static var swiftDate: Self { .product(name: "Date", package: "swift-date") }
    static var swiftHtml: Self { .product(name: "HTML", package: "swift-html") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
    static var urlFormEncoding: Self { .product(name: "UrlFormEncoding", package: "pointfree-web") }
    static var rfc2822: Self { .product(name: "RFC 2822", package: "swift-web-standards") }
    static var rfc5322: Self { .product(name: "RFC 5322", package: "swift-web-standards") }
}

let package = Package(
    name: "swift-web",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: .swiftWeb,
            targets: [
                .webDate,
                .unixEpoch,
                .swiftWeb,
                .favicon,
                .sitemap,
                .urlFormCoding,
            ]
        ),
        .library(name: .favicon, targets: [.favicon]),
        .library(name: .sitemap, targets: [.sitemap]),
        .library(name: .urlFormCoding, targets: [.urlFormCoding]),
        .library(name: .webDate, targets: [.webDate]),
        .library(name: .unixEpoch, targets: [.unixEpoch])
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-html", branch: "main"),
        .package(url: "https://github.com/coenttb/swift-date", branch: "main"),
        .package(url: "https://github.com/coenttb/pointfree-web", branch: "main"),
        .package(url: "https://github.com/coenttb/swift-web-standards", branch: "main"),
        .package(url: "https://github.com/coenttb/swift-emailaddress-type", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
        .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", branch: "main")
    ],
    targets: [
        .target(
            name: .favicon,
            dependencies: [
                .urlRouting,
                .swiftHtml
            ]
        ),
        .target(
            name: .unixEpoch,
            dependencies: [
                .parsing,
                .urlRouting
            ]
        ),
        .testTarget(
            name: .unixEpoch.tests,
            dependencies: [
                .unixEpoch
            ]
        ),
        .target(
            name: .webDate,
            dependencies: [
                .rfc2822,
                .rfc5322,
                .parsing,
                .urlRouting
            ]
        ),
        .testTarget(
            name: .webDate.tests,
            dependencies: [
                .webDate
            ]
        ),
        .target(
            name: .urlFormCoding,
            dependencies: [
                .dependencies,
                .urlRouting,
                .urlFormEncoding
            ]
        ),
        .testTarget(
            name: .urlFormCoding.tests,
            dependencies: [
                .urlFormCoding,
                .dependenciesTestSupport
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
                .mediaType,
                .unixEpoch
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }
