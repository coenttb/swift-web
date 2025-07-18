//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Domain
import Foundation
import RFC_5321
import RFC_5322
import RFC_6531

/// An email address that can be represented according to different RFC standards
public struct EmailAddress: Hashable, Sendable {
    let rfc5321: RFC_5321.EmailAddress?
    let rfc5322: RFC_5322.EmailAddress?
    let rfc6531: RFC_6531.EmailAddress

    /// The display name associated with this email address, if any
    public let displayName: String?

    public var name: String? { displayName }
    public var address: String { self.rfc6531.addressValue }

    /// Initialize with an email address string
    public init(
        displayName: String? = nil,
        _ string: String
    ) throws {
        // RFC 6531 is required as it's our most permissive format
        let rfc6531Address = try RFC_6531.EmailAddress(string)

        // If a display name was provided, update the RFC6531 instance
        if let displayName = displayName {
            self.rfc6531 = RFC_6531.EmailAddress(
                displayName: displayName,
                localPart: rfc6531Address.localPart,
                domain: rfc6531Address.domain
            )
        } else {
            self.rfc6531 = rfc6531Address
        }

        // Try to initialize stricter formats if possible
        if rfc6531.isASCII {
            self.rfc5322 = try? RFC_5322.EmailAddress(
                displayName: displayName ?? rfc6531.displayName,
                localPart: .init(rfc6531.localPart.stringValue),
                domain: rfc6531.domain
            )

            self.rfc5321 = try? RFC_5321.EmailAddress(
                displayName: displayName ?? rfc6531.displayName,
                localPart: .init(rfc6531.localPart.stringValue),
                domain: rfc6531.domain
            )
        } else {
            self.rfc5322 = nil
            self.rfc5321 = nil
        }

        self.displayName = displayName ?? rfc6531.displayName
    }

    /// Initialize with components
    public init(displayName: String? = nil, localPart: String, domain: String) throws {
        try self.init(
            displayName: displayName,
            "\(localPart)@\(domain)"
        )
    }

    /// Initialize from RFC5321
    public init(rfc5321: RFC_5321.EmailAddress) throws {
        self.rfc5321 = rfc5321
        self.rfc5322 = try? RFC_5322.EmailAddress(
            displayName: rfc5321.displayName,
            localPart: .init(rfc5321.localPart.stringValue),
            domain: .init(rfc5321.domain.name)
        )
        self.rfc6531 = try {
            guard let email = try? RFC_6531.EmailAddress(
                displayName: rfc5321.displayName,
                localPart: .init(rfc5321.localPart.stringValue),
                domain: .init(rfc5321.domain.name)
            ) else {
                throw EmailAddressError.conversionFailure
            }
            return email
        }()
        self.displayName = rfc5321.displayName
    }

    /// Initialize from RFC5322
    public init(rfc5322: RFC_5322.EmailAddress) throws {
        self.rfc5321 = try? rfc5322.toRFC5321()
        self.rfc5322 = rfc5322
        self.rfc6531 = try {
            guard let email = try? RFC_6531.EmailAddress(
                displayName: rfc5322.displayName,
                localPart: .init(rfc5322.localPart.stringValue),
                domain: rfc5322.domain
            ) else {
                throw EmailAddressError.conversionFailure
            }
            return email
        }()
        self.displayName = rfc5322.displayName
    }

    /// Initialize from RFC6531
    public init(rfc6531: RFC_6531.EmailAddress) {
        self.rfc5321 = try? rfc6531.toRFC5321()
        self.rfc5322 = try? rfc6531.toRFC5322()
        self.rfc6531 = rfc6531
        self.displayName = rfc6531.displayName
    }
}

// MARK: - Properties
extension EmailAddress {
    /// The email address string, using the most specific format available
    public var stringValue: String {
        rfc5321?.stringValue ?? rfc5322?.stringValue ?? rfc6531.stringValue
    }

    /// The email address string without display name
    public var addressValue: String {
        rfc5321?.addressValue ?? rfc5322?.addressValue ?? rfc6531.addressValue
    }

    /// The local part (before @)
    public var localPart: String {
        rfc5321?.localPart.stringValue ??
        rfc5322?.localPart.stringValue ??
        rfc6531.localPart.stringValue
    }
}

public typealias DomainTypealias = Domain
extension EmailAddress {
    /// The domain part (after @)
    public var domain: _Domain {
        if let domain = rfc5321?.domain {
            return .init(rfc5321: domain)
        }
        if let domain = rfc5322?.domain {
            return try! .init(rfc1123: domain)
        }
        return try! .init(rfc1123: rfc6531.domain)
    }

    /// Returns true if this is an ASCII-only email address
    public var isASCII: Bool {
        rfc5321 != nil || rfc5322 != nil
    }

    /// Returns true if this is an internationalized email address
    public var isInternationalized: Bool {
        !isASCII
    }
}

// MARK: - Email Operations
extension EmailAddress {
    /// Returns a normalized version of the email address
    /// - For ASCII addresses, uses the most restrictive format available (5321 > 5322 > 6531)
    /// - For international addresses, uses RFC 6531
    public func normalized() -> EmailAddress {
        // Already normalized if we only have RFC 6531
        guard isASCII else { return self }

        // Use most restrictive format available
        if let rfc5321 = self.rfc5321 {
            return try! EmailAddress(rfc5321: rfc5321)
        }
        if let rfc5322 = self.rfc5322 {
            return try! EmailAddress(rfc5322: rfc5322)
        }
        return self
    }

    /// Returns true if this email address matches another under the same RFC
    /// - Attempts to compare using the most restrictive common format
    /// - Display names are not considered in the match
    public func matches(_ other: EmailAddress) -> Bool {
        if let myRFC5321 = rfc5321, let otherRFC5321 = other.rfc5321 {
            return myRFC5321.addressValue.lowercased() == otherRFC5321.addressValue.lowercased()
        }
        if let myRFC5322 = rfc5322, let otherRFC5322 = other.rfc5322 {
            return myRFC5322.addressValue.lowercased() == otherRFC5322.addressValue.lowercased()
        }
        return rfc6531.addressValue.lowercased() == other.rfc6531.addressValue.lowercased()
    }
}

// MARK: - Errors
extension EmailAddress {
    public enum EmailAddressError: Error, Equatable, LocalizedError {
        case conversionFailure
        case invalidFormat(description: String)

        public var errorDescription: String? {
            switch self {
            case .conversionFailure:
                return "Failed to convert between email address formats"
            case .invalidFormat(let description):
                return "Invalid email format: \(description)"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension EmailAddress: CustomStringConvertible {
    public var description: String { stringValue }
}

extension EmailAddress: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension EmailAddress: RawRepresentable {
    public var rawValue: String { stringValue }
    public init?(rawValue: String) { try? self.init(rawValue) }
}

// MARK: - Convenience Extensions
extension String {
    /// Attempts to parse the string as an email address
    public func asEmailAddress() throws -> EmailAddress {
        try EmailAddress(self)
    }
}

// Could add convenience initializer for common case
extension EmailAddress {
    public static func ascii(_ string: String) throws -> Self {
        let email = try Self(string)
        guard email.isASCII else {
            throw EmailAddressError.invalidFormat(description: "Must be ASCII-only")
        }
        return email
    }
}
