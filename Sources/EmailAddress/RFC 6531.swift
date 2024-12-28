//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation
import RegexBuilder
import Domain

extension EmailAddress {
    /// RFC 6531 compliant email address (SMTPUTF8)
    public struct RFC6531: Hashable, Sendable {
        /// The display name, if present
        public let displayName: String?
        
        /// The local part (before @)
        public let localPart: LocalPart
        
        /// The domain part (after @)
        public let domain: Domain.RFC1123
        
        /// Initialize with components
        public init(displayName: String? = nil, localPart: LocalPart, domain: Domain.RFC1123) {
            self.displayName = displayName?.trimmingCharacters(in: .whitespaces)
            self.localPart = localPart
            self.domain = domain
        }
        
        /// Initialize from string representation ("Name <local@domain>" or "local@domain")
        public init(_ string: String) throws {
            // Address format regex with optional display name and proper space handling
            let displayNameCapture = /((?:\"(?:[^\"\\]|\\.)*\"|[^<]+?))\s*/
            
            let emailCapture = /<([^@]+)@([^>]+)>/
            
            let fullRegex = Regex {
                Optionally {
                    displayNameCapture
                }
                emailCapture
            }
            
            // Try matching the full address format first (with angle brackets)
            if let match = try? fullRegex.wholeMatch(in: string) {
                let captures = match.output
                
                // Extract display name if present and normalize spaces
                let displayName = captures.1.map { name in
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                        let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                        return withoutQuotes.replacingOccurrences(of: #"\""#, with: "\"")
                            .replacingOccurrences(of: #"\\"#, with: "\\")
                    }
                    return trimmedName
                }
                
                let localPart = String(captures.2)
                let domain = String(captures.3)
                
                try self.init(
                    displayName: displayName,
                    localPart: LocalPart(localPart),
                    domain: Domain.RFC1123(domain)
                )
            } else {
                // Try parsing as bare email address
                guard let atIndex = string.firstIndex(of: "@") else {
                    throw ValidationError.missingAtSign
                }
                
                let localString = String(string[..<atIndex])
                let domainString = String(string[string.index(after: atIndex)...])
                
                try self.init(
                    displayName: nil,
                    localPart: LocalPart(localString),
                    domain: Domain.RFC1123(domainString)
                )
            }
        }
    }
}



// MARK: - Local Part
extension EmailAddress.RFC6531 {
    /// RFC 6531 compliant local-part (UTF-8)
    public struct LocalPart: Hashable, Sendable {
        private let storage: Storage
        private let utf8Value: String
        
        /// Initialize with a string
        public init(_ string: String) throws {
            // Check overall length in UTF-8 bytes
            let utf8Bytes = string.utf8.count
            guard utf8Bytes <= Limits.maxUTF8Length else {
                throw ValidationError.localPartTooLong(utf8Bytes)
            }
            
            // Store UTF-8 value for consistent comparisons
            self.utf8Value = string
            
            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? EmailAddress.RFC6531.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle UTF8-dot-atom format
            else {
                // Check for consecutive dots
                guard !string.contains("..") else {
                    throw ValidationError.consecutiveDots
                }
                
                // Check for leading/trailing dots
                guard !string.hasPrefix(".") && !string.hasSuffix(".") else {
                    throw ValidationError.leadingOrTrailingDot
                }
                
                // Validate each atom between dots
                let atoms = string.split(separator: ".", omittingEmptySubsequences: true)
                for atom in atoms {
                    guard (try? EmailAddress.RFC6531.utf8AtomRegex.wholeMatch(in: String(atom))) != nil else {
                        throw ValidationError.invalidUTF8Atom(String(atom))
                    }
                }
                
                self.storage = .utf8DotAtom(string)
            }
        }
        
        /// The string representation
        public var stringValue: String {
            switch storage {
            case .utf8DotAtom(let string), .quoted(let string):
                return string
            }
        }
        
        private enum Storage: Hashable {
            case utf8DotAtom(String)  // UTF-8 unquoted format
            case quoted(String)       // Quoted string format
        }
    }
}

// MARK: - Constants and Validation
extension EmailAddress.RFC6531 {
    private enum Limits {
        static let maxUTF8Length = 64  // Max length in UTF-8 bytes
    }
    
    // Address format regex with optional display name
    nonisolated(unsafe) private static let addressRegex = /(?:((?:\"[^>]+\"|[^<]+)\s+))?<([^@]+)@([^>]+)>/
    
    // UTF-8 atom regex: allows Unicode letters and common symbols
    nonisolated(unsafe) private static let utf8AtomRegex = /[\p{L}\p{N}!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+/
    
    // Quoted string regex: allows any printable character except unescaped quotes
    // Also allows UTF-8 characters
    nonisolated(unsafe) private static let quotedRegex = /(?:[^"\\\r\n]|\\["\\]|\p{L}|\p{N}|\p{P}|\p{S})+/
}

extension EmailAddress.RFC6531 {
    /// The complete email address string, including display name if present
    public var stringValue: String {
        if let name = displayName {
            // Quote the display name if it contains special characters or non-ASCII
            let needsQuoting = name.contains(where: {
                !$0.isLetter && !$0.isNumber && !$0.isWhitespace ||
                $0.asciiValue == nil
            })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            return "\(quotedName) <\(localPart.stringValue)@\(domain.name)>" // Exactly one space before angle bracket
        }
        return "\(localPart.stringValue)@\(domain.name)"
    }
    
    /// Just the email address part without display name
    public var addressValue: String {
        "\(localPart.stringValue)@\(domain.name)"
    }
    
    /// Returns true if this is an ASCII-only email address
    public var isASCII: Bool {
        stringValue.utf8.allSatisfy { $0 < 128 }
    }
    
    /// Convert to RFC 5322 format if possible (only for ASCII addresses)
    public func toRFC5322() throws -> EmailAddress.RFC5322 {
        guard isASCII else {
            throw ConversionError.nonASCIICharacters
        }
        return try EmailAddress.RFC5322(
            displayName: displayName,
            localPart: .init(localPart.stringValue),
            domain: domain
        )
    }
    
    /// Convert to RFC 5321 format if possible (only for ASCII addresses)
    public func toRFC5321() throws -> EmailAddress.RFC5321 {
        guard isASCII else {
            throw ConversionError.nonASCIICharacters
        }
        return try EmailAddress.RFC5321(
            displayName: displayName,
            localPart: .init(localPart.stringValue),
            domain: .init(domain: domain)
        )
    }
}

// MARK: - Errors
extension EmailAddress.RFC6531 {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case missingAtSign
        case invalidUTF8Atom(_ atom: String)
        case invalidQuotedString
        case localPartTooLong(_ bytes: Int)
        case consecutiveDots
        case leadingOrTrailingDot
        
        public var errorDescription: String? {
            switch self {
            case .missingAtSign:
                return "Email address must contain @"
            case .invalidUTF8Atom(let atom):
                return "Invalid UTF-8 atom format: '\(atom)'"
            case .invalidQuotedString:
                return "Invalid quoted string format in local-part"
            case .localPartTooLong(let bytes):
                return "Local-part UTF-8 byte length \(bytes) exceeds maximum of \(Limits.maxUTF8Length)"
            case .consecutiveDots:
                return "Local-part cannot contain consecutive dots"
            case .leadingOrTrailingDot:
                return "Local-part cannot begin or end with a dot"
            }
        }
    }
    
    public enum ConversionError: Error, LocalizedError, Equatable {
        case nonASCIICharacters
        
        public var errorDescription: String? {
            switch self {
            case .nonASCIICharacters:
                return "Cannot convert internationalized email address to ASCII-only format"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension EmailAddress.RFC6531: CustomStringConvertible {
    public var description: String { stringValue }
}

extension EmailAddress.RFC6531: Codable {
    private enum CodingKeys: String, CodingKey {
        case address
        case displayName
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(addressValue, forKey: .address)
        try container.encodeIfPresent(displayName, forKey: .displayName)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .address)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        
        // Parse address part first
        guard let atIndex = address.firstIndex(of: "@") else {
            throw ValidationError.missingAtSign
        }
        
        let localString = String(address[..<atIndex])
        let domainString = String(address[address.index(after: atIndex)...])
        
        try self.init(
            displayName: displayName,
            localPart: LocalPart(localString),
            domain: Domain.RFC1123(domainString)
        )
    }
}

extension EmailAddress.RFC6531: RawRepresentable {
    public var rawValue: String { stringValue }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
