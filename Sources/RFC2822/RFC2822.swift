//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Foundation
import Parsing
import URLRouting


extension Date {
    public struct RFC2822 {
        
    }
}

extension Date.RFC2822 {
    public struct Parser: ParserPrinter {
        
        public init(){}
        
        public var body: some ParserPrinter<Substring, Date> {
            Parse(.string).map(Date.RFC2822.Conversion())
        }
    }
}



extension Date.RFC2822 {
    struct Conversion: Parsing.Conversion {
        public typealias Input = String
        public typealias Output = Date
        
        public func apply(_ input: String) throws -> Date {
            
            guard let date = Date.RFC2822.formatter.date(from: input) else {
                throw Date.RFC2822.Conversion.Error.invalidDate(input)
            }
            return date
        }
        
        public func unapply(_ output: Date) throws -> String {
            output.formatted(.rfc2822)
        }
        
        public enum Error: Swift.Error {
            case invalidDate(String)
        }
    }
}

@available(macOS 12.0, *)
extension Date.RFC2822 {
    public static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if #available(macOS 13, *) {
            formatter.timeZone = .gmt
        } else {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return formatter
    }()

    /// Format a `Date` into RFC2822-compliant string
    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    /// Parse an RFC2822-compliant string into a `Date`
    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}

@available(macOS 12.0, *)
extension FormatStyle where Self == Date.FormatStyle {
    public static var rfc2822: RFC2822DateStyle {
        RFC2822DateStyle()
    }
}

@available(macOS 12.0, *)
public struct RFC2822DateStyle: FormatStyle {
    public typealias FormatInput = Date
    public typealias FormatOutput = String

    public func format(_ value: Date) -> String {
        Date.RFC2822.formatter.string(from: value)
    }
}
