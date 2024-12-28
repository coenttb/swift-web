//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation

extension Domain {
    /// RFC 5321 compliant domain name, allowing both standard domains and address literals
    public struct RFC5321: Hashable, Sendable {
        /// The type of domain this represents
        private let storage: Storage
        
        /// Initialize with a standard domain name
        public init(domain: Domain.RFC1123) {
            self.storage = .standard(domain)
        }
        
        /// Initialize from a string that could be either a domain name or address literal
        public init(_ string: String) throws {
            if string.hasPrefix("[") && string.hasSuffix("]") {
                // Parse as address literal
                let literal = String(string.dropFirst().dropLast())
                try self.init(addressLiteral: literal)
            } else {
                // Parse as standard domain
                try self.init(domain: RFC1123(string))
            }
        }
        
        /// Initialize with an IP address literal
        public init(addressLiteral: String) throws {
            // Validate and parse the address literal
            guard !addressLiteral.isEmpty else {
                throw ValidationError.emptyAddressLiteral
            }
            
            if addressLiteral.contains(":") {
                // IPv6 address
                try self.init(ipv6Literal: addressLiteral)
            } else {
                // IPv4 address
                try self.init(ipv4Literal: addressLiteral)
            }
        }
        
        /// Initialize with an IPv4 address literal
        public init(ipv4Literal: String) throws {
            guard (try? Self.ipv4Regex.wholeMatch(in: ipv4Literal)) != nil else {
                throw ValidationError.invalidIPv4(ipv4Literal)
            }
            self.storage = .ipv4(ipv4Literal)
        }
        
        /// Initialize with an IPv6 address literal
        public init(ipv6Literal: String) throws {
            guard (try? Self.ipv6Regex.wholeMatch(in: ipv6Literal)) != nil else {
                throw ValidationError.invalidIPv6(ipv6Literal)
            }
            self.storage = .ipv6(ipv6Literal)
        }
    }
}

// MARK: - Storage
extension Domain.RFC5321 {
    /// The underlying storage type for the domain
    private enum Storage: Hashable {
        case standard(Domain.RFC1123)
        case ipv4(String)
        case ipv6(String)
    }
}

// MARK: - Properties
extension Domain.RFC5321 {
    /// Returns true if this is a standard domain name
    public var isStandardDomain: Bool {
        if case .standard = storage { return true }
        return false
    }
    
    /// Returns true if this is an IP address literal
    public var isAddressLiteral: Bool {
        if case .standard = storage { return false }
        return true
    }
    
    /// Returns the underlying standard domain if this is a standard domain
    public var standardDomain: Domain.RFC1123? {
        if case .standard(let domain) = storage { return domain }
        return nil
    }
    
    /// Returns the IP address literal if this is an address literal
    public var addressLiteral: String? {
        switch storage {
        case .ipv4(let addr), .ipv6(let addr):
            return addr
        case .standard:
            return nil
        }
    }
    
    /// The complete domain string, including brackets for address literals
    public var name: String {
        switch storage {
        case .standard(let domain):
            return domain.name
        case .ipv4(let addr):
            return "[\(addr)]"
        case .ipv6(let addr):
            return "[\(addr)]"
        }
    }
}

// MARK: - Validation
extension Domain.RFC5321 {
    /// Simple IPv4 regex for basic format validation
    nonisolated(unsafe) internal static let ipv4Regex = /(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/

    
    /// IPv6 regex for basic format validation
    nonisolated(unsafe) internal static let ipv6Regex = /(?:[0-9a-fA-F]{1,4}:){6}(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|::(?:[0-9a-fA-F]{1,4}:){5}(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:[0-9a-fA-F]{1,4})?::(?:[0-9a-fA-F]{1,4}:){4}(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:(?:[0-9a-fA-F]{1,4}:){0,1}[0-9a-fA-F]{1,4})?::(?:[0-9a-fA-F]{1,4}:){3}(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:(?:[0-9a-fA-F]{1,4}:){0,2}[0-9a-fA-F]{1,4})?::(?:[0-9a-fA-F]{1,4}:){2}(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:(?:[0-9a-fA-F]{1,4}:){0,3}[0-9a-fA-F]{1,4})?::(?:[0-9a-fA-F]{1,4}:)(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:(?:[0-9a-fA-F]{1,4}:){0,4}[0-9a-fA-F]{1,4})?::(?:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|(?:(?:[0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4})?::[0-9a-fA-F]{1,4}|(?:(?:[0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4})?::/
}

// MARK: - Errors
extension Domain.RFC5321 {
    public enum ValidationError: Error, Equatable, LocalizedError {
        case emptyAddressLiteral
        case invalidIPv4(_ address: String)
        case invalidIPv6(_ address: String)
        
        public var errorDescription: String? {
            switch self {
            case .emptyAddressLiteral:
                return "Address literal cannot be empty"
            case .invalidIPv4(let addr):
                return "Invalid IPv4 address literal '\(addr)'"
            case .invalidIPv6(let addr):
                return "Invalid IPv6 address literal '\(addr)'"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension Domain.RFC5321: CustomStringConvertible {
    public var description: String { name }
}

extension Domain.RFC5321: Codable {
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

extension Domain.RFC5321: RawRepresentable {
    public var rawValue: String { name }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
