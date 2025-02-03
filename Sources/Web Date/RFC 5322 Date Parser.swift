//
//  File.swift
//  swift-web-standards
//
//  Created by Coen ten Thije Boonkkamp on 03/02/2025.
//

import Foundation
import Parsing
import URLRouting
@_exported import RFC_5322

extension RFC_5322.Date {
    public struct Parser: ParserPrinter {
        public init() {}
        
        public var body: some ParserPrinter<Substring, Foundation.Date> {
            Parse(.string).map(Conversion())
        }
    }
    
    struct Conversion: Parsing.Conversion {
        public typealias Input = String
        public typealias Output = Foundation.Date
        
        public func apply(_ input: String) throws -> Foundation.Date {
            try RFC_5322.Date.date(from: input)
        }
        
        public func unapply(_ output: Foundation.Date) throws -> String {
            output.formatted(.rfc5322)
        }
    }
}
