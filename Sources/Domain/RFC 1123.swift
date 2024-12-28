//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation

/// RFC 1123 compliant host name
public struct RFC1123: Hashable, Sendable {
    /// The labels that make up the host name, from least significant to most significant
    private let labels: [Label]
    
    /// Initialize with an array of string labels, validating RFC 1123 rules
    public init(labels: [String]) throws {
        guard !labels.isEmpty else {
            throw ValidationError.empty
        }
        
        guard labels.count <= Limits.maxLabels else {
            throw ValidationError.tooManyLabels
        }
        
        // Validate TLD according to stricter RFC 1123 rules
        guard let tld = labels.last else {
            throw ValidationError.empty
        }
        
        // Convert and validate labels
        var validatedLabels = try labels.dropLast().map { label in
            try Label(label, validateAs: .label)
        }
        
        // Add TLD with stricter validation
        validatedLabels.append(try Label(tld, validateAs: .tld))
        
        self.labels = validatedLabels
        
        // Check total length including dots
        let totalLength = self.name.count
        guard totalLength <= Limits.maxLength else {
            throw ValidationError.tooLong(totalLength)
        }
    }
    
    /// Initialize from a string representation (e.g. "host.example.com")
    public init(_ string: String) throws {
        try self.init(labels: string.split(separator: ".", omittingEmptySubsequences: true).map(String.init))
    }
}

// MARK: - Label Type
extension RFC1123 {
    /// A type-safe host label that enforces RFC 1123 rules
    public struct Label: Hashable, Sendable {
        enum ValidationType {
            case label  // Regular label rules
            case tld    // Stricter TLD rules
        }
        
        private let value: String
        
        /// Initialize a label, validating RFC 1123 rules
        internal init(_ string: String, validateAs type: ValidationType) throws {
            guard !string.isEmpty, string.count <= RFC1123.Limits.maxLabelLength else {
                throw type == .tld ? RFC1123.ValidationError.invalidTLD(string) : RFC1123.ValidationError.invalidLabel(string)
            }
            
            let regex = type == .tld ? RFC1123.tldRegex : RFC1123.labelRegex
            guard (try? regex.wholeMatch(in: string)) != nil else {
                throw type == .tld ? RFC1123.ValidationError.invalidTLD(string) : RFC1123.ValidationError.invalidLabel(string)
            }
            
            self.value = string
        }
        
        public var stringValue: String { value }
    }
}

// MARK: - Constants and Validation
extension RFC1123 {
    internal enum Limits {
        static let maxLength = 255
        static let maxLabels = 127
        static let maxLabelLength = 63
    }
    
    /// RFC 1123 label regex:
    /// - Can begin with letter or digit
    /// - Can end with letter or digit
    /// - May have hyphens in interior positions only
    nonisolated(unsafe) internal static let labelRegex = /[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?/
    
    /// RFC 1123 TLD regex:
    /// - Must begin with a letter
    /// - Must end with a letter
    /// - May have hyphens in interior positions only
    nonisolated(unsafe) internal static let tldRegex = /[a-zA-Z](?:[a-zA-Z0-9\-]*[a-zA-Z])?/
}

// MARK: - Properties and Methods
extension RFC1123 {
    /// The complete host name as a string
    public var name: String {
        labels.map(\.stringValue).joined(separator: ".")
    }
    
    /// The top-level domain (rightmost label)
    public var tld: Label? {
        labels.last
    }
    
    /// The second-level domain (second from right)
    public var sld: Label? {
        labels.dropLast().last
    }
    
    /// Returns true if this is a subdomain of the given host
    public func isSubdomain(of parent: RFC1123) -> Bool {
        guard labels.count > parent.labels.count else { return false }
        return labels.suffix(parent.labels.count) == parent.labels
    }
    
    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: [String]) throws -> RFC1123 {
        try RFC1123(labels: components + labels.map(\.stringValue))
    }
    
    public func addingSubdomain(_ components: String...) throws -> RFC1123 {
        try self.addingSubdomain(components)
    }
    
    /// Returns the parent domain by removing the leftmost label
    public func parent() throws -> RFC1123? {
        guard labels.count > 1 else { return nil }
        return try RFC1123(labels: labels.dropFirst().map(\.stringValue))
    }
    
    /// Returns the root domain (tld + sld)
    public func root() throws -> RFC1123? {
        guard labels.count >= 2 else { return nil }
        return try RFC1123(labels: labels.suffix(2).map(\.stringValue))
    }
}

// MARK: - Errors
extension RFC1123 {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case empty
        case tooLong(_ length: Int)
        case tooManyLabels
        case invalidLabel(_ label: String)
        case invalidTLD(_ tld: String)
        
        public var errorDescription: String? {
            switch self {
            case .empty:
                return "Host name cannot be empty"
            case .tooLong(let length):
                return "Host name length \(length) exceeds maximum of \(Limits.maxLength)"
            case .tooManyLabels:
                return "Host name has too many labels (maximum \(Limits.maxLabels))"
            case .invalidLabel(let label):
                return "Invalid label '\(label)'. Must start and end with letter/digit, and contain only letters/digits/hyphens"
            case .invalidTLD(let tld):
                return "Invalid TLD '\(tld)'. Must start and end with letter, and contain only letters/digits/hyphens"
            }
        }
    }
}

// MARK: - Convenience Initializers
extension RFC1123 {
    /// Creates a host from root level components
    public static func root(_ sld: String, _ tld: String) throws -> RFC1123 {
        try RFC1123(labels: [sld, tld])
    }
    
    /// Creates a subdomain with components in most-to-least significant order
    public static func subdomain(_ components: String...) throws -> RFC1123 {
        try RFC1123(labels: components.reversed())
    }
}

// MARK: - Protocol Conformances
extension RFC1123: CustomStringConvertible {
    public var description: String { name }
}

extension RFC1123: Codable {
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

extension RFC1123: RawRepresentable {
    public var rawValue: String { name }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
