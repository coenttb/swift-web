//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Testing
import Foundation
@testable import RFC2822

@Suite("RFC2822 Date Formatter Tests")
struct RFC2822DateFormatterTests {

    @Test("Formats a Date to RFC2822 String")
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 0)
        let expected = "Thu, 01 Jan 1970 00:00:00 +0000"

        #expect(Date.RFC2822.string(from: date) == expected)
    }

    @Test("Parses a valid RFC2822 string to Date")
    func testDateParsingValidString() {
        let dateString = "Thu, 01 Jan 1970 00:00:00 +0000"
        let expected = Date(timeIntervalSince1970: 0)

        let parsedDate = try? #require(Date.RFC2822.date(from: dateString))
        
        #expect(parsedDate == expected, "Parsed date does not match the expected date.")
    }

    @Test("Returns nil for an invalid RFC2822 string")
    func testDateParsingInvalidString() {
        let invalidDateString = "Invalid Date String"

        let parsedDate = Date.RFC2822.date(from: invalidDateString)
        #expect(parsedDate == nil)
    }

    @Test("Formats and parses correctly using FormatStyle.rfc2822")
    func testFormatStyleRFC2822() {
        let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970, 00:00:00 UTC
        let formatter = Date.FormatStyle.rfc2822
        let expectedString = "Thu, 01 Jan 1970 00:00:00 +0000"

        let formattedString = formatter.format(date)
        #expect(formattedString == expectedString)
        
        let parsedDate = Date.RFC2822.date(from: formattedString)
        #expect(parsedDate == date)
    }
}

