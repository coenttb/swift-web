//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Testing
import Foundation
@testable import UnixEpoch

@Suite("UnixEpoch Date Tests")
struct UnixEpochDateFormatterTests {
    @Test("Parses a valid Unix epoch string to Date")
    func testDateParsingValidString() throws {
        let epochString = "0" // Represents 1970-01-01 00:00:00 UTC
        let expectedDate = Date(timeIntervalSince1970: 0)

        // Because Parser is defined as a ParserPrinter<Substring, Date>,
        // we need to convert the string to a Substring before parsing.
        let parsedDate = try Date.UnixEpoch.Parser().parse(epochString[...])
        
        #expect(parsedDate == expectedDate, "Parsed date does not match the expected date.")
    }

    @Test("Converts a Date to a Unix epoch string")
    func testDateFormatting() throws {
        let date = Date(timeIntervalSince1970: 0)
        let expectedEpochString = "0"

        // Printing is the inverse of parsing: Date -> String
        let epochString = try Date.UnixEpoch.Parser().print(date)
        
        #expect(epochString == expectedEpochString, "Formatted epoch string does not match expected.")
    }

    @Test("Returns nil or throws for an invalid Unix epoch string")
    func testDateParsingInvalidString() throws {
        let invalidEpochString = "InvalidEpoch"

        #expect(throws: Error.self) {
            let _ = try Date.UnixEpoch.Parser().parse(invalidEpochString[...])
        }
        
    }

    @Test("Parses and prints round trip correctly")
    func testRoundTrip() throws {
        let originalDate = Date(timeIntervalSince1970: 1672531200) // Some known timestamp
        let parser = Date.UnixEpoch.Parser()
        
        let epochString = try parser.print(originalDate)
        let roundTrippedDate = try parser.parse(epochString[...])

        #expect(roundTrippedDate == originalDate, "Date should round-trip correctly through UnixEpoch parser.")
    }
}
