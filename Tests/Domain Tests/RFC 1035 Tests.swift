//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Domain
import Foundation
import Testing

@Suite("RFC 1035 Domain Tests")
struct RFC1035Tests {
    @Test("Successfully creates valid domain")
    func testValidDomain() throws {
        let domain = try Domain.RFC1035("example.com")
        #expect(domain.name == "example.com")
    }

    @Test("Successfully creates subdomain")
    func testValidSubdomain() throws {
        let domain = try Domain.RFC1035("sub.example.com")
        #expect(domain.name == "sub.example.com")
    }

    @Test("Successfully gets TLD")
    func testTLD() throws {
        let domain = try Domain.RFC1035("example.com")
        #expect(domain.tld?.stringValue == "com")
    }

    @Test("Successfully gets SLD")
    func testSLD() throws {
        let domain = try Domain.RFC1035("example.com")
        #expect(domain.sld?.stringValue == "example")
    }

    @Test("Fails with empty domain")
    func testEmptyDomain() throws {
        #expect(throws: Domain.RFC1035.ValidationError.empty) {
            _ = try Domain.RFC1035("")
        }
    }

    @Test("Fails with too many labels")
    func testTooManyLabels() throws {
        let longDomain = Array(repeating: "a", count: 128).joined(separator: ".")
        #expect(throws: Domain.RFC1035.ValidationError.tooManyLabels) {
            _ = try Domain.RFC1035(longDomain)
        }
    }

    @Test("Fails with too long domain")
    func testTooLongDomain() throws {
        let longLabel = String(repeating: "a", count: 63)
        let longDomain = Array(repeating: longLabel, count: 5).joined(separator: ".")
        #expect(throws: Domain.RFC1035.ValidationError.tooLong(319)) {
            _ = try Domain.RFC1035(longDomain)
        }
    }

    @Test("Fails with invalid label starting with hyphen")
    func testInvalidLabelStartingWithHyphen() throws {
        #expect(throws: Domain.RFC1035.ValidationError.invalidLabel("-example")) {
            _ = try Domain.RFC1035("-example.com")
        }
    }

    @Test("Fails with invalid label ending with hyphen")
    func testInvalidLabelEndingWithHyphen() throws {
        #expect(throws: Domain.RFC1035.ValidationError.invalidLabel("example-")) {
            _ = try Domain.RFC1035("example-.com")
        }
    }

    @Test("Successfully detects subdomain relationship")
    func testIsSubdomain() throws {
        let parent = try Domain.RFC1035("example.com")
        let child = try Domain.RFC1035("sub.example.com")
        #expect(child.isSubdomain(of: parent))
    }

    @Test("Successfully adds subdomain")
    func testAddSubdomain() throws {
        let domain = try Domain.RFC1035("example.com")
        let subdomain = try domain.addingSubdomain("sub")
        #expect(subdomain.name == "sub.example.com")
    }

    @Test("Successfully gets parent domain")
    func testParentDomain() throws {
        let domain = try Domain.RFC1035("sub.example.com")
        let parent = try domain.parent()
        #expect(parent?.name == "example.com")
    }

    @Test("Successfully gets root domain")
    func testRootDomain() throws {
        let domain = try Domain.RFC1035("sub.example.com")
        let root = try domain.root()
        #expect(root?.name == "example.com")
    }

    @Test("Successfully creates domain from root components")
    func testRootInitializer() throws {
        let domain = try Domain.RFC1035.root("example", "com")
        #expect(domain.name == "example.com")
    }

    @Test("Successfully creates domain from subdomain components")
    func testSubdomainInitializer() throws {
        let domain = try Domain.RFC1035.subdomain("com", "example", "sub")
        #expect(domain.name == "sub.example.com")
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try Domain.RFC1035("example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Domain.RFC1035.self, from: encoded)
        #expect(original == decoded)
    }
}
