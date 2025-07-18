//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 22/12/2024.
//

@testable import EmailAddress
import Foundation
import Testing

@Suite("EmailAddress Tests")
struct EmailAddressTests {

    @Test("Successfully initializes with valid components")
    func testValidComponentsInitialization() throws {
        let email = try EmailAddress(
            displayName: "John Doe",
            "john.doe@example.com"
        )

        #expect(email.name == "John Doe")
        #expect(email.localPart == "john.doe")
        #expect(email.domain.name == "example.com")
        #expect(email.address == "john.doe@example.com")
    }

    @Test("Successfully initializes from valid string with name")
    func testValidStringWithNameInitialization() throws {
        let email = try EmailAddress("John Doe <john.doe@example.com>")

        #expect(email.name == "John Doe")
        #expect(email.localPart == "john.doe")
        #expect(email.domain.name == "example.com")
    }

    @Test("Successfully initializes from valid string without name")
    func testValidStringWithoutNameInitialization() throws {
        let email = try EmailAddress("john.doe@example.com")

        #expect(email.name == nil)
        #expect(email.localPart == "john.doe")
        #expect(email.domain.name == "example.com")
    }

    @Test("Successfully initializes with quoted name containing special characters")
    func testQuotedNameInitialization() throws {
        let email = try EmailAddress("\"Doe, John\" <john.doe@example.com>")

        #expect(email.name == "Doe, John")
        #expect(email.localPart == "john.doe")
        #expect(email.domain.name == "example.com")
    }

    @Test("Successfully handles quoted local part")
    func testQuotedLocalPart() throws {
        let email = try EmailAddress(
            localPart: "\"john.doe\"",
            domain: "example.com"
        )

        #expect(email.localPart == "\"john.doe\"")
        #expect(email.domain.name == "example.com")
    }

    @Test("Successfully creates from convenience initializers")
    func testConvenienceInitializers() throws {
        let unnamedEmail = try EmailAddress("john.doe@example.com")
        #expect(unnamedEmail.name == nil)
        #expect(unnamedEmail.address == "john.doe@example.com")

        let namedEmail = try EmailAddress(displayName: "John Doe", "john.doe@example.com")
        #expect(namedEmail.name == "John Doe")
        #expect(namedEmail.address == "john.doe@example.com")
    }

    @Test("Successfully converts to and from raw value")
    func testRawValueConversion() throws {
        let original = try EmailAddress("John Doe <john.doe@example.com>")
        let rawValue = original.rawValue
        let reconstructed = EmailAddress(rawValue: rawValue)

        #expect(reconstructed != nil)
        #expect(reconstructed?.name == "John Doe")
        #expect(reconstructed?.address == "john.doe@example.com")
    }

    @Test("Correctly formats description")
    func testDescription() throws {
        let plainEmail = try EmailAddress("john.doe@example.com")
        #expect(plainEmail.description == "john.doe@example.com")

        let namedEmail = try EmailAddress("John Doe <john.doe@example.com>")
        #expect(namedEmail.description == "John Doe <john.doe@example.com>")

        let specialNameEmail = try EmailAddress("\"Doe, John\" <john.doe@example.com>")
        #expect(specialNameEmail.description == "\"Doe, John\" <john.doe@example.com>")
    }

//    @Test("Throws error for invalid local part")
//    func testInvalidLocalPart() throws {
//        #expect(throws: EmailAddress.ValidationError.invalidLocalPart) {
//            try EmailAddress(localPart: "", domain: "example.com")
//        }
//        
//        let longLocalPart = String(repeating: "a", count: 65)
//        #expect(throws: EmailAddress.ValidationError.invalidLocalPart) {
//            try EmailAddress(localPart: longLocalPart, domain: "example.com")
//        }
//    }
//    
//    @Test("Throws error for invalid domain")
//    func testInvalidDomain() throws {
//        #expect(throws: EmailAddress.ValidationError.invalidDomain) {
//            try EmailAddress(localPart: "john", domain: "")
//        }
//        
//        #expect(throws: EmailAddress.ValidationError.invalidDomain) {
//            try EmailAddress(localPart: "john", domain: "-invalid.com")
//        }
//        
//        let longDomain = String(repeating: "a", count: 256)
//        #expect(throws: EmailAddress.ValidationError.invalidDomain) {
//            try EmailAddress(localPart: "john", domain: longDomain)
//        }
//    }
//    
//    @Test("Throws error for invalid format")
//    func testInvalidFormat() throws {
//        #expect(throws: EmailAddress.ValidationError.invalidFormat) {
//            try EmailAddress("invalid email format")
//        }
//        
//        #expect(throws: EmailAddress.ValidationError.invalidFormat) {
//            try EmailAddress("invalid@")
//        }
//    }

    @Test("Successfully handles special characters in local part")
    func testSpecialCharactersInLocalPart() throws {
        let specialChars = "!#$%&'*+-/=?^_`{|}~"
        let email = try EmailAddress(localPart: "test.\(specialChars)", domain: "example.com")

        #expect(email.localPart.contains(specialChars))
        #expect(email.address == "test.\(specialChars)@example.com")
    }

    @Test("Successfully handles subdomains")
    func testSubdomains() throws {
        let email = try EmailAddress("test@sub1.sub2.example.com")

        #expect(email.domain.name == "sub1.sub2.example.com")
    }

    @Test("Correctly implements Hashable")
    func testHashable() throws {
        let email1 = try EmailAddress("John Doe <john@example.com>")
        let email2 = try EmailAddress("John Doe <john@example.com>")
        let email3 = try EmailAddress("Jane Doe <jane@example.com>")

        var set = Set<EmailAddress>()
        set.insert(email1)
        set.insert(email2)
        set.insert(email3)

        #expect(set.count == 2)
    }
}
