//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 07/01/2025.
//

import Foundation
import Parsing
import URLRouting

extension Date {
    public struct UnixEpoch { }
}

extension Date.UnixEpoch {
    public struct Parser: ParserPrinter {

        public init() { }

        public var body: some ParserPrinter<Substring, Date> {
            Parse(.string)
                .map(Date.UnixEpoch.Conversion())
        }
    }
}

extension Date.UnixEpoch {
    struct Conversion: Parsing.Conversion {
        public typealias Input = String
        public typealias Output = Date

        public func apply(_ input: String) throws -> Date {
            guard let seconds = TimeInterval(input) else {
                throw Date.UnixEpoch.Conversion.Error.invalidEpoch(input)
            }
            return Date(timeIntervalSince1970: seconds)
        }

        public func unapply(_ output: Date) throws -> String {
            // Convert timeIntervalSince1970 to an integer and then to a string
            String(Int(output.timeIntervalSince1970))
        }

        public enum Error: Swift.Error {
            case invalidEpoch(String)
        }
    }
}
