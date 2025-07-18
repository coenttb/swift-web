//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//
import Foundation
import RFC_1035
import RFC_1123
import RFC_5321

/// A domain name that can be represented according to different RFC standards
public struct _Domain: Hashable, Sendable {
    let rfc1035: RFC_1035.Domain?
    let rfc1123: RFC_1123.Domain?
    let rfc5321: RFC_5321.Domain

    /// Initialize with a domain string
    public init(_ string: String) throws {
        // RFC 5321 is required as it's our most permissive format
        self.rfc5321 = try RFC_5321.Domain(string)

        // Try to initialize stricter formats if possible
        self.rfc1123 = try? RFC_1123.Domain(string)
        self.rfc1035 = try? RFC_1035.Domain(string)
    }

    /// Initialize with an array of labels
    public init(labels: [String]) throws {
        try self.init(labels.joined(separator: "."))
    }
}

public typealias Domain = _Domain

extension Domain {
    /// Initialize from RFC1035
    public init(rfc1035: RFC_1035.Domain) throws {
        self.rfc1035 = rfc1035
        self.rfc1123 = try {
            guard let domain = try? RFC_1123.Domain(rfc1035.name) else {
                throw DomainError.conversionFailure
            }
            return domain
        }()
        self.rfc5321 = try {
            guard let domain = try? RFC_5321.Domain(rfc1035.name) else {
                throw DomainError.conversionFailure
            }
            return domain
        }()
    }

    /// Initialize from RFC1123
    public init(rfc1123: RFC_1123.Domain) throws {
        self.rfc1035 = nil  // RFC1123 may not be RFC1035 compliant
        self.rfc1123 = rfc1123
        self.rfc5321 = try {
            guard let domain = try? RFC_5321.Domain(rfc1123.name) else {
                throw DomainError.conversionFailure
            }
            return domain
        }()
    }

    /// Initialize from RFC_5321.Domain
    public init(rfc5321: RFC_5321.Domain) {
        self.rfc1035 = nil  // RFC_5321.Domain may not be RFC1035 compliant
        self.rfc1123 = nil  // RFC_5321.Domain may not be RFC1123 compliant
        self.rfc5321 = rfc5321
    }
}

// MARK: - Properties
extension Domain {
    /// The domain string, using the most specific format available
    public var name: String {
        rfc1035?.name ?? rfc1123?.name ?? rfc5321.name
    }

    /// The top-level domain if available (only for RFC1035/1123 domains)
    public var tld: String? {
        rfc1035?.tld?.stringValue ?? rfc1123?.tld?.stringValue
    }

    /// The second-level domain if available (only for RFC1035/1123 domains)
    public var sld: String? {
        rfc1035?.sld?.stringValue ?? rfc1123?.sld?.stringValue
    }

    /// Returns true if this is a standard domain (not an IP address)
    public var isStandardDomain: Bool {
        rfc1123 != nil
    }

//    /// Returns true if this is an IP address literal
//    public var isAddressLiteral: Bool {
//        rfc5321.isAddressLiteral
//    }
}

// MARK: - Domain Operations
extension Domain {
    /// Returns true if this is a subdomain of the given domain
    public func isSubdomain(of parent: Domain) -> Bool {
        // Use the most specific format available for both domains
        if let myRFC1035 = rfc1035, let parentRFC1035 = parent.rfc1035 {
            return myRFC1035.isSubdomain(of: parentRFC1035)
        }
        if let myRFC1123 = rfc1123, let parentRFC1123 = parent.rfc1123 {
            return myRFC1123.isSubdomain(of: parentRFC1123)
        }
        return false  // Can't determine subdomain relationship for RFC_5321.Domain address literals
    }

    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: String...) throws -> Domain {
        // Use the most specific format available
        if let domain = rfc1035 {
            return try Domain(rfc1035: domain.addingSubdomain(components))
        }
        if let domain = rfc1123 {
            return try Domain(rfc1123: domain.addingSubdomain(components))
        }
        throw DomainError.cannotCreateSubdomain
    }

    /// Returns the parent domain by removing the leftmost label
    public func parent() throws -> Domain? {
        // Use the most specific format available
        if let domain = rfc1035, let parent = try domain.parent() {
            return try Domain(rfc1035: parent)
        }
        if let domain = rfc1123, let parent = try domain.parent() {
            return try Domain(rfc1123: parent)
        }
        return nil
    }
}

// MARK: - Errors
extension Domain {
    public enum DomainError: Error, Equatable, LocalizedError {
        case cannotCreateSubdomain
        case conversionFailure
        case invalidFormat(description: String)

        public var errorDescription: String? {
            switch self {
            case .cannotCreateSubdomain:
                return "Cannot create subdomain for IP address literals"
            case .conversionFailure:
                return "Failed to convert"
            case .invalidFormat(description: let description):
                return "Invalid format: \(description)"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension Domain: CustomStringConvertible {
    public var description: String { name }
}

extension Domain: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }
}

extension Domain: RawRepresentable {
    public var rawValue: String { name }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
