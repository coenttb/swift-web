//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

@testable import Domain
import Foundation
import Testing

@Suite("Domain Tests")
struct DomainTests {
    @Test("Successfully creates domain from string")
    func testCreateFromString() throws {
        let domain = try Domain("example.com")
        #expect(domain.name == "example.com")
        #expect(domain.isStandardDomain)
        #expect(!domain.isAddressLiteral)
        #expect(domain.tld == "com")
        #expect(domain.sld == "example")
    }

    @Test("Successfully creates domain from labels")
    func testCreateFromLabels() throws {
        let domain = try Domain(labels: ["mail", "example", "com"])
        #expect(domain.name == "mail.example.com")
        #expect(domain.isStandardDomain)
        #expect(domain.tld == "com")
        #expect(domain.sld == "example")
    }

    @Test("Successfully creates domain from RFC1035")
    func testCreateFromRFC1035() throws {
        let rfc1035 = try Domain.RFC1035("example.com")
        let domain = try Domain(rfc1035: rfc1035)
        #expect(domain.name == "example.com")
        #expect(domain.rfc1035?.name == "example.com")
        #expect(domain.rfc1123?.name == "example.com")
        #expect(domain.rfc5321.name == "example.com")
    }

    @Test("Successfully creates domain from RFC1123")
    func testCreateFromRFC1123() throws {
        let rfc1123 = try Domain.RFC1123("example.com")
        let domain = try Domain(rfc1123: rfc1123)
        #expect(domain.rfc1035 == nil)
        #expect(domain.rfc1123?.name == "example.com")
        #expect(domain.rfc5321.name == "example.com")
    }

    @Test("Successfully creates domain from RFC5321")
    func testCreateFromRFC5321() throws {
        let rfc5321 = try Domain.RFC5321("[192.168.1.1]")
        let domain = Domain(rfc5321: rfc5321)
        #expect(domain.rfc1035 == nil)
        #expect(domain.rfc1123 == nil)
        #expect(domain.rfc5321.name == "[192.168.1.1]")
        #expect(domain.isAddressLiteral)
    }

    @Test("Successfully handles subdomain relationship")
    func testSubdomainRelationship() throws {
        let parent = try Domain("example.com")
        let child = try Domain("mail.example.com")
        let unrelated = try Domain("other.com")

        #expect(child.isSubdomain(of: parent))
        #expect(!parent.isSubdomain(of: child))
        #expect(!child.isSubdomain(of: unrelated))
    }

    @Test("Successfully adds subdomain")
    func testAddSubdomain() throws {
        let domain = try Domain("example.com")
        let subdomain = try domain.addingSubdomain("mail")
        #expect(subdomain.name == "mail.example.com")
        #expect(subdomain.isSubdomain(of: domain))
    }

    @Test("Fails to add subdomain to IP address literal")
    func testAddSubdomainToIPLiteral() throws {
        let domain = try Domain("[192.168.1.1]")
        #expect(throws: Domain.DomainError.cannotCreateSubdomain) {
            _ = try domain.addingSubdomain("mail")
        }
    }

    @Test("Successfully gets parent domain")
    func testParentDomain() throws {
        let domain = try Domain("mail.example.com")
        let parent = try domain.parent()
        #expect(parent?.name == "example.com")
    }

    @Test("Returns nil parent for top-level domain")
    func testNilParentForTopLevel() throws {
        let domain = try Domain("example.com")
        let parent = try domain.parent()
        #expect(parent?.name == "com")
        let topLevel = try parent?.parent()
        #expect(topLevel == nil)
    }

    @Test("Successfully handles different RFC format capabilities")
    func testRFCFormatCapabilities() throws {
        // RFC1035-compliant domain should work with all formats
        let rfc1035Domain = try Domain("example.com")
        #expect(rfc1035Domain.rfc1035 != nil)
        #expect(rfc1035Domain.rfc1123 != nil)
        #expect(rfc1035Domain.rfc5321.isStandardDomain)

        // Numeric label should work with RFC1123 and RFC5321 only
        let numericLabel = try Domain("123.example.com")
        #expect(numericLabel.rfc1035 == nil)
        #expect(numericLabel.rfc1123 != nil)
        #expect(numericLabel.rfc5321.isStandardDomain)

        // IP address should work with RFC5321 only
        let ipAddress = try Domain("[192.168.1.1]")
        #expect(ipAddress.rfc1035 == nil)
        #expect(ipAddress.rfc1123 == nil)
        #expect(ipAddress.rfc5321.isAddressLiteral)
    }

    @Test("Successfully encodes and decodes domain")
    func testCodable() throws {
        let original = try Domain("mail.example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Domain.self, from: encoded)
        #expect(original == decoded)
        #expect(decoded.name == "mail.example.com")
    }

    @Test("Successfully uses RawRepresentable")
    func testRawRepresentable() throws {
        let domain = try Domain("example.com")
        #expect(domain.rawValue == "example.com")
        let fromRaw = Domain(rawValue: "example.com")
        #expect(fromRaw != nil)
        #expect(fromRaw?.name == "example.com")
    }
}
