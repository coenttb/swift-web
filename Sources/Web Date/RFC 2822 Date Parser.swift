//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 03/02/2025.
//

import Foundation
import Parsing
import RFC_2822
import URLRouting

extension RFC_2822.Date {
    public struct Parser: ParserPrinter {

        public init() {}

        public var body: some ParserPrinter<Substring, Foundation.Date> {
            Parse(.string).map(RFC_2822.Date.Conversion())
        }
    }
}

extension RFC_2822.Date {
    struct Conversion: Parsing.Conversion {
        public typealias Input = String
        public typealias Output = Foundation.Date

        public func apply(_ input: String) throws -> Foundation.Date {

            guard let date = RFC_2822.Date.formatter.date(from: input) else {
                throw RFC_2822.Date.Conversion.Error.invalidDate(input)
            }
            return date
        }

        public func unapply(_ output: Foundation.Date) throws -> String {
            output.formatted(.rfc2822)
        }

        public enum Error: Swift.Error {
            case invalidDate(String)
        }
    }
}
