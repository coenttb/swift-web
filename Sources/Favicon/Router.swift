//
//  File.swift
//  
//
//  Created by Coen ten Thije Boonkkamp on 25/05/2024.
//

import Foundation
import URLRouting

extension FaviconRouter {
    public enum Route: String, Codable, Hashable, Sendable {
        case svg = "favicon.svg"
        case png = "favicon.png"
        case apple_touch_icon_png = "apple-touch-icon.png"
        case apple_touch_icon_precomposed_png = "apple-touch-icon-precomposed.png"
        case favicon_32x32_png = "favicon-32x32.png"
        case favicon_16x16_png = "favicon-16x16.png"
        case site_webmanifest = "site.webmanifest"
        case safari_pinned_tab_svg = "safari-pinned-tab.svg"
        case favicon_ico = "favicon.ico"
        case mstile_150x150_png = "mstile-150x150.png"
        case browserconfig_xml = "browserconfig.xml"
        case android_chrome_192x192_png = "android-chrome-192x192.png"
        case android_chrome_512x512_png = "android-chrome-512x512.png"
    }
}

public struct FaviconRouter: ParserPrinter {

    public init() {}

    public var body: some URLRouting.Router<Route> {
        OneOf {
            URLRouting.Route(.case(FaviconRouter.Route.svg)) {
                Path { FaviconRouter.Route.svg.rawValue }
            }

            URLRouting.Route(.case(.png)) {
                Path { FaviconRouter.Route.png.rawValue }
            }
            
            URLRouting.Route(.case(FaviconRouter.Route.apple_touch_icon_png)) {
                Path { FaviconRouter.Route.apple_touch_icon_png.rawValue }
            }

            URLRouting.Route(.case(.favicon_32x32_png)) {
                Path { FaviconRouter.Route.favicon_32x32_png.rawValue }
            }

            URLRouting.Route(.case(.favicon_16x16_png)) {
                Path { FaviconRouter.Route.favicon_16x16_png.rawValue }
            }

            URLRouting.Route(.case(.site_webmanifest)) {
                Path { FaviconRouter.Route.site_webmanifest.rawValue }
            }

            URLRouting.Route(.case(.safari_pinned_tab_svg)) {
                Path { FaviconRouter.Route.safari_pinned_tab_svg.rawValue }
            }

            URLRouting.Route(.case(.favicon_ico)) {
                Path { FaviconRouter.Route.favicon_ico.rawValue }
            }

            URLRouting.Route(.case(.mstile_150x150_png)) {
                Path { FaviconRouter.Route.mstile_150x150_png.rawValue }
            }

            URLRouting.Route(.case(.browserconfig_xml)) {
                Path { FaviconRouter.Route.browserconfig_xml.rawValue }
            }

            URLRouting.Route(.case(.android_chrome_192x192_png)) {
                Path { FaviconRouter.Route.android_chrome_192x192_png.rawValue }
            }

            URLRouting.Route(.case(.android_chrome_512x512_png)) {
                Path { FaviconRouter.Route.android_chrome_512x512_png.rawValue }
            }

            URLRouting.Route(.case(.apple_touch_icon_precomposed_png)) {
                Path { FaviconRouter.Route.apple_touch_icon_precomposed_png.rawValue }
            }
        }
    }
}
