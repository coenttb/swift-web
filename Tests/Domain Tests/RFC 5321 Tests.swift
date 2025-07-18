//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Domain
import Foundation
import Testing

@Suite("RFC 5321 Domain Tests")
struct RFC5321Tests {
    @Test("Successfully creates standard domain")
    func testStandardDomain() throws {
        let domain = try Domain.RFC5321("mail.example.com")
        #expect(domain.name == "mail.example.com")
        #expect(domain.isStandardDomain)
        #expect(!domain.isAddressLiteral)
    }

    @Test("Successfully creates IPv4 literal")
    func testIPv4Literal() throws {
        let domain = try Domain.RFC5321("[192.168.1.1]")
        #expect(domain.name == "[192.168.1.1]")
        #expect(!domain.isStandardDomain)
        #expect(domain.isAddressLiteral)
        #expect(domain.addressLiteral == "192.168.1.1")
    }

    @Test("Successfully creates IPv6 literal")
    func testIPv6Literal() throws {
        let domain = try Domain.RFC5321("[2001:db8:85a3:8d3:1319:8a2e:370:7348]")
        #expect(domain.name == "[2001:db8:85a3:8d3:1319:8a2e:370:7348]")
        #expect(!domain.isStandardDomain)
        #expect(domain.isAddressLiteral)
        #expect(domain.addressLiteral == "2001:db8:85a3:8d3:1319:8a2e:370:7348")
    }

    @Test("Fails with empty address literal")
    func testEmptyAddressLiteral() throws {
        #expect(throws: Domain.RFC5321.ValidationError.emptyAddressLiteral) {
            _ = try Domain.RFC5321("[]")
        }
    }

    @Test("Fails with invalid IPv4 format")
    func testInvalidIPv4Format() throws {
        #expect(throws: Domain.RFC5321.ValidationError.invalidIPv4("256.256.256.256")) {
            _ = try Domain.RFC5321("[256.256.256.256]")
        }
    }

    @Test("Fails with invalid IPv6 format")
    func testInvalidIPv6Format() throws {
        #expect(throws: Domain.RFC5321.ValidationError.invalidIPv6("not:valid:ipv6")) {
            _ = try Domain.RFC5321("[not:valid:ipv6]")
        }
    }

    @Test("Successfully gets standard domain")
    func testGetStandardDomain() throws {
        let domain = try Domain.RFC5321("mail.example.com")
        #expect(domain.standardDomain?.name == "mail.example.com")
    }

    @Test("Returns nil standard domain for address literal")
    func testNilStandardDomainForAddressLiteral() throws {
        let domain = try Domain.RFC5321("[192.168.1.1]")
        #expect(domain.standardDomain == nil)
    }

    @Test("Successfully creates from RFC1123")
    func testCreateFromRFC1123() throws {
        let rfc1123 = try Domain.RFC1123("mail.example.com")
        let domain = Domain.RFC5321(domain: rfc1123)
        #expect(domain.name == "mail.example.com")
        #expect(domain.isStandardDomain)
    }

    @Test("Successfully creates IPv4 literal directly")
    func testCreateIPv4Literal() throws {
        let domain = try Domain.RFC5321(ipv4Literal: "192.168.1.1")
        #expect(domain.name == "[192.168.1.1]")
        #expect(domain.addressLiteral == "192.168.1.1")
    }

    @Test("Successfully creates IPv6 literal directly")
    func testCreateIPv6Literal() throws {
        let ipv6 = "2001:db8:85a3:8d3:1319:8a2e:370:7348"
        let domain = try Domain.RFC5321(ipv6Literal: ipv6)
        #expect(domain.name == "[\(ipv6)]")
        #expect(domain.addressLiteral == ipv6)
    }

    @Test("Successfully encodes and decodes standard domain")
    func testCodableStandardDomain() throws {
        let original = try Domain.RFC5321("mail.example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Domain.RFC5321.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Successfully encodes and decodes IPv4 literal")
    func testCodableIPv4() throws {
        let original = try Domain.RFC5321("[192.168.1.1]")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Domain.RFC5321.self, from: encoded)
        #expect(original == decoded)
    }
}
