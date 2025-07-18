//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Domain
import Foundation
import Testing

@Suite("RFC 1123 Host Tests")
struct RFC1123Tests {
    @Test("Successfully creates valid host")
    func testValidHost() throws {
        let host = try Domain.RFC1123("host.example.com")
        #expect(host.name == "host.example.com")
    }

    @Test("Successfully creates host with numeric labels")
    func testNumericLabels() throws {
        let host = try Domain.RFC1123("123.example.com")
        #expect(host.name == "123.example.com")
    }

    @Test("Successfully creates host with mixed alphanumeric labels")
    func testMixedLabels() throws {
        let host = try Domain.RFC1123("host123.example456.com")
        #expect(host.name == "host123.example456.com")
    }

    @Test("Fails with empty host")
    func testEmptyHost() throws {
        #expect(throws: Domain.RFC1123.ValidationError.empty) {
            _ = try Domain.RFC1123("")
        }
    }

    @Test("Fails with invalid TLD starting with number")
    func testInvalidTLDStartingWithNumber() throws {
        #expect(throws: Domain.RFC1123.ValidationError.invalidTLD("123com")) {
            _ = try Domain.RFC1123("example.123com")
        }
    }

    @Test("Fails with invalid TLD ending with number")
    func testInvalidTLDEndingWithNumber() throws {
        #expect(throws: Domain.RFC1123.ValidationError.invalidTLD("com123")) {
            _ = try Domain.RFC1123("example.com123")
        }
    }

    @Test("Fails with invalid label containing special characters")
    func testInvalidLabelSpecialChars() throws {
        #expect(throws: Domain.RFC1123.ValidationError.invalidLabel("host@name")) {
            _ = try Domain.RFC1123("host@name.com")
        }
    }

    @Test("Successfully gets TLD")
    func testTLD() throws {
        let host = try Domain.RFC1123("example.com")
        #expect(host.tld?.stringValue == "com")
    }

    @Test("Successfully gets SLD")
    func testSLD() throws {
        let host = try Domain.RFC1123("example.com")
        #expect(host.sld?.stringValue == "example")
    }

    @Test("Successfully detects subdomain relationship")
    func testIsSubdomain() throws {
        let parent = try Domain.RFC1123("example.com")
        let child = try Domain.RFC1123("host.example.com")
        #expect(child.isSubdomain(of: parent))
    }

    @Test("Successfully adds subdomain")
    func testAddSubdomain() throws {
        let host = try Domain.RFC1123("example.com")
        let subdomain = try host.addingSubdomain("host")
        #expect(subdomain.name == "host.example.com")
    }

    @Test("Successfully gets parent domain")
    func testParentDomain() throws {
        let host = try Domain.RFC1123("host.example.com")
        let parent = try host.parent()
        #expect(parent?.name == "example.com")
    }

    @Test("Successfully gets root domain")
    func testRootDomain() throws {
        let host = try Domain.RFC1123("host.example.com")
        let root = try host.root()
        #expect(root?.name == "example.com")
    }

    @Test("Successfully creates host from root components")
    func testRootInitializer() throws {
        let host = try Domain.RFC1123.root("example", "com")
        #expect(host.name == "example.com")
    }

    @Test("Successfully creates host from subdomain components")
    func testSubdomainInitializer() throws {
        let host = try Domain.RFC1123.subdomain("com", "example", "host")
        #expect(host.name == "host.example.com")
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try Domain.RFC1123("example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Domain.RFC1123.self, from: encoded)
        #expect(original == decoded)
    }
}
