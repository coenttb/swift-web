//
//  File.swift
//
//
//  Created by Coen ten Thije Boonkkamp on 07-01-2024.
//

import Foundation

public struct SiteMap {
    public let urls: [SiteMap.URL]

    public init(urls: [SiteMap.URL]) {
        self.urls = urls
    }
}

extension SiteMap {
    public var xml: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        \(urls.map(\.xml).joined(separator: "\n"))
        </urlset>
        """
    }
}

extension SiteMap {
    public struct URL {
        public let location: Foundation.URL
        public let metadata: MetaData

        public struct MetaData: Sendable {
            public let lastModification: Date?
            public let changeFrequency: SiteMap.URL.ChangeFrequency?
            public let priority: Float?

            public  init(
                lastModification: Date? = nil,
                changeFrequency: SiteMap.URL.ChangeFrequency? = nil,
                priority: Float? = nil
            ) {
                self.lastModification = lastModification
                self.changeFrequency = changeFrequency
                self.priority = priority
            }

            public static let empty: Self = .init(lastModification: nil, changeFrequency: nil, priority: nil)
        }

        public init(
            location: Foundation.URL,
            lastModification: Date? = nil,
            changeFrequency: SiteMap.URL.ChangeFrequency? = nil,
            priority: Float? = nil
        ) {
            self.location = location
            self.metadata = .init(
                lastModification: lastModification,
                changeFrequency: changeFrequency,
                priority: priority
            )
        }
    }
}

extension SiteMap.URL {
    public var xml: String {
        var elements = [
            "<loc>\(location.absoluteString)</loc>"
        ]

        if let lastModification = metadata.lastModification {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            elements.append("<lastmod>\(formatter.string(from: lastModification))</lastmod>")
        }
        if let changeFrequency = metadata.changeFrequency {
            elements.append("<changefreq>\(changeFrequency.rawValue)</changefreq>")
        }
        if let priority = metadata.priority {
            elements.append("<priority>\(priority)</priority>")
        }

        return "<url>\n\(elements.joined(separator: "\n"))\n</url>"
    }
}

extension SiteMap.URL {
    public enum ChangeFrequency: String, Codable, Hashable, Sendable {
        case always = "always"
        case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        case never = "never"
    }
}

extension [SiteMap.URL] {
    public init<Page>(
        router: (_ page: Page) -> URL,
        _ dictionary: [Page: SiteMap.URL.MetaData]
    ) {

        self = dictionary.map { (page, metadata) in
            let location = router(page)

            return SiteMap.URL(
                location: location,
                lastModification: metadata.lastModification,
                changeFrequency: metadata.changeFrequency,
                priority: metadata.priority
            )
        }
    }
}

// extension SiteMap {
//    init(
//        _ dictionary: [SiteRoute.Page.Page : SiteMap.URL.MetaData]
//    ){
//        self = .init(urls: .init(dictionary))
//    }
// }
//
//
