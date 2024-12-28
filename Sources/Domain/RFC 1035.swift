//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation

extension Domain {
    
    /// RFC 1035 compliant domain name
    public struct RFC1035: Hashable, Sendable {
        /// The labels that make up the domain name, from least significant to most significant
        private let labels: [Label]
        
        /// Initialize with an array of string labels, validating RFC 1035 rules
        public init(labels: [String]) throws {
            guard !labels.isEmpty else {
                throw ValidationError.empty
            }
            
            guard labels.count <= Limits.maxLabels else {
                throw ValidationError.tooManyLabels
            }
            
            // Validate and convert each label
            self.labels = try labels.map(Label.init)
            
            // Check total length including dots
            let totalLength = self.name.count
            guard totalLength <= Limits.maxLength else {
                throw ValidationError.tooLong(totalLength)
            }
        }
        
        /// Initialize from a string representation (e.g. "example.com")
        public init(_ string: String) throws {
            try self.init(labels: string.split(separator: ".", omittingEmptySubsequences: true).map(String.init))
        }
    }
}


extension Domain.RFC1035 {
    /// A type-safe domain label that enforces RFC 1035 rules
    public struct Label: Hashable, Sendable {
        private let value: String
        
        /// Initialize a label, validating RFC 1035 rules
        internal init(_ string: String) throws {
            guard !string.isEmpty, string.count <= Domain.RFC1035.Limits.maxLabelLength else {
                throw Domain.RFC1035.ValidationError.invalidLabel(string)
            }
            
            guard (try? Domain.RFC1035.labelRegex.wholeMatch(in: string)) != nil else {
                throw Domain.RFC1035.ValidationError.invalidLabel(string)
            }
            
            self.value = string
        }
        
        public var stringValue: String { value }
    }
}

extension Domain.RFC1035 {
    /// The complete domain name as a string
    public var name: String {
        labels.map(\.stringValue).joined(separator: ".")
    }
    
    /// The top-level domain (rightmost label)
    public var tld: Domain.RFC1035.Label? {
        labels.last
    }
    
    /// The second-level domain (second from right)
    public var sld: Domain.RFC1035.Label? {
        labels.dropLast().last
    }
    
    /// Returns true if this is a subdomain of the given domain
    public func isSubdomain(of parent: Domain.RFC1035) -> Bool {
        guard labels.count > parent.labels.count else { return false }
        return labels.suffix(parent.labels.count) == parent.labels
    }
    
    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: [String]) throws -> Domain.RFC1035 {
        try Domain.RFC1035(labels: components + labels.map(\.stringValue))
    }
    
    public func addingSubdomain(_ components: String...) throws -> Domain.RFC1035 {
        try self.addingSubdomain(components)
    }
    
    /// Returns the parent domain by removing the leftmost label
    public func parent() throws -> Domain.RFC1035? {
        guard labels.count > 1 else { return nil }
        return try Domain.RFC1035(labels: labels.dropFirst().map(\.stringValue))
    }
    
    /// Returns the root domain (tld + sld)
    public func root() throws -> Domain.RFC1035? {
        guard labels.count >= 2 else { return nil }
        return try Domain.RFC1035(labels: labels.suffix(2).map(\.stringValue))
    }
}

// MARK: - Constants and Validation
extension Domain.RFC1035 {
    internal enum Limits {
        static let maxLength = 255
        static let maxLabels = 127
        static let maxLabelLength = 63
    }
    
    // RFC 1035 label regex:
    // - Must begin with a letter
    // - Must end with a letter or digit
    // - May have hyphens in interior positions only
    nonisolated(unsafe) internal static let labelRegex = /[a-zA-Z](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?/
}

// MARK: - Errors
extension Domain.RFC1035 {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case empty
        case tooLong(_ length: Int)
        case tooManyLabels
        case invalidLabel(_ label: String)
        
        public var errorDescription: String? {
            switch self {
            case .empty:
                return "Domain name cannot be empty"
            case .tooLong(let length):
                return "Domain name length \(length) exceeds maximum of \(Limits.maxLength)"
            case .tooManyLabels:
                return "Domain name has too many labels (maximum \(Limits.maxLabels))"
            case .invalidLabel(let label):
                return "Invalid label '\(label)'. Must start with letter, end with letter/digit, and contain only letters/digits/hyphens"
            }
        }
    }
}

// MARK: - Convenience Initializers
extension Domain.RFC1035 {
    /// Creates a domain from root level components
    public static func root(_ sld: String, _ tld: String) throws -> Domain.RFC1035 {
        try Domain.RFC1035(labels: [sld, tld])
    }
    
    /// Creates a subdomain with components in most-to-least significant order
    public static func subdomain(_ components: String...) throws -> Domain.RFC1035 {
        try Domain.RFC1035(labels: components.reversed())
    }
}

// MARK: - Protocol Conformances
extension Domain.RFC1035: CustomStringConvertible {
    public var description: String { name }
}

extension Domain.RFC1035: Codable {
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

extension Domain.RFC1035: RawRepresentable {
    public var rawValue: String { name }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
