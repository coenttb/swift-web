// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let domain: Self = "Domain"
    static let emailAddress: Self = "EmailAddress"
    static let favicon: Self = "Favicon"
    static let rfc2822: Self = "RFC2822"
    static let unixEpoch: Self = "UnixEpoch"
    static let sitemap: Self = "Sitemap"
    static let swiftWeb: Self = "SwiftWeb"
    static let urlFormCoding: Self = "UrlFormCoding"
}

extension Target.Dependency {
    static var domain: Self { .target(name: .domain) }
    static var emailAddress: Self { .target(name: .emailAddress) }
    static var favicon: Self { .target(name: .favicon) }
    static var rfc2822: Self { .target(name: .rfc2822) }
    static var unixEpoch: Self { .target(name: .unixEpoch) }
    static var sitemap: Self { .target(name: .sitemap) }
    static var swiftWeb: Self { .target(name: .swiftWeb) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesTestSupport: Self { .product(name: "DependenciesTestSupport", package: "swift-dependencies") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
    static var mediaType: Self { .product(name: "MediaType", package: "pointfree-web") }
    static var parsing: Self { .product(name: "Parsing", package: "swift-parsing") }
    static var swiftDate: Self { .product(name: "Date", package: "swift-date") }
    static var swiftHtml: Self { .product(name: "HTML", package: "swift-html") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
    static var urlFormEncoding: Self { .product(name: "UrlFormEncoding", package: "pointfree-web") }
}

extension [Package.Dependency] {
    static var `default`: Self {
        [
            .package(url: "https://github.com/coenttb/swift-html", branch: "main"),
            .package(url: "https://github.com/coenttb/swift-date", branch: "main"),
            .package(url: "https://github.com/coenttb/pointfree-web", branch: "main"),
            .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
            .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0"),
            .package(url: "https://github.com/pointfreeco/swift-parsing.git", branch: "main"),
        ]
    }
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
                .domain,
                .rfc2822,
                .unixEpoch,
                .swiftWeb,
                .favicon,
                .sitemap,
                .urlFormCoding,
                .emailAddress,
            ]
        ),
        .library(name: .domain, targets: [.domain]),
        .library(name: .emailAddress, targets: [.emailAddress]),
        .library(name: .favicon, targets: [.favicon]),
        .library(name: .sitemap, targets: [.sitemap]),
        .library(name: .urlFormCoding, targets: [.urlFormCoding]),
        .library(name: .rfc2822, targets: [.rfc2822]),
        .library(name: .unixEpoch, targets: [.unixEpoch]),
    ],
    dependencies: .default,
    targets: [
        .target(
            name: .domain,
            dependencies: [
            ]
        ),
        .testTarget(
            name: .domain.tests,
            dependencies: [
                .domain
            ]
        ),
        .target(
            name: .emailAddress,
            dependencies: [
                .domain,
            ]
        ),
        .testTarget(
            name: .emailAddress.tests,
            dependencies: [
                .emailAddress
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
            name: .unixEpoch,
            dependencies: [
                .parsing,
                .urlRouting,
            ]
        ),
        .testTarget(
            name: .unixEpoch.tests,
            dependencies: [
                .unixEpoch
            ]
        ),
        .target(
            name: .rfc2822,
            dependencies: [
                .parsing,
                .urlRouting,
            ]
        ),
        .testTarget(
            name: .rfc2822.tests,
            dependencies: [
                .rfc2822
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
                .unixEpoch,
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self {
        self + " Tests"
    }
}
