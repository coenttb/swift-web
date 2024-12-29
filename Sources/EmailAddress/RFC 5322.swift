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
    /// RFC 5322 compliant email address (Internet Message Format)
    public struct RFC5322: Hashable, Sendable {
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
            // Define regex components using Regex builder for more robust parsing
            let displayNameCapture = /((?:\"(?:(?:\\[\"\\])|[^\"\\])+\"|[^<]+?))\s*/
            
            let emailCapture = Regex {
                "<"
                Capture {
                    // Local part
                    OneOrMore(.reluctant) {
                        NegativeLookahead { "@" }
                        CharacterClass.any
                    }
                }
                "@"
                Capture {
                    // Domain
                    OneOrMore(.reluctant) {
                        NegativeLookahead { ">" }
                        CharacterClass.any
                    }
                }
                ">"
            }
            
            let fullRegex = Regex {
                Optionally {
                    displayNameCapture
                }
                emailCapture
            }
            
            // Try matching the full address format first (with angle brackets)
            if let match = try? fullRegex.wholeMatch(in: string) {
                let displayName = match.output.1.map { name in
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                        // For quoted strings, we need to:
                        // 1. Remove the outer quotes
                        // 2. Handle escaped characters
                        let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                        return withoutQuotes.replacingOccurrences(of: #"\""#, with: "\"")
                            .replacingOccurrences(of: #"\\"#, with: "\\")
                    }
                    return trimmedName
                }
                
                let localPart = String(match.output.2)
                let domain = String(match.output.3)
                
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
extension EmailAddress.RFC5322 {
    /// RFC 5322 compliant local-part
    public struct LocalPart: Hashable, Sendable {
        private let storage: Storage
        
        /// Initialize with a string
        public init(_ string: String) throws {
            // Check overall length first
            guard string.count <= Limits.maxLength else {
                throw ValidationError.localPartTooLong(string.count)
            }
            
            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? EmailAddress.RFC5322.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle dot-atom format
            else {
                guard (try? EmailAddress.RFC5322.dotAtomRegex.wholeMatch(in: string)) != nil else {
                    throw ValidationError.invalidDotAtom
                }
                // Check for consecutive dots
                guard !string.contains("..") else {
                    throw ValidationError.consecutiveDots
                }
                // Check for leading/trailing dots
                guard !string.hasPrefix(".") && !string.hasSuffix(".") else {
                    throw ValidationError.leadingOrTrailingDot
                }
                self.storage = .dotAtom(string)
            }
        }
        
        /// The string representation
        public var stringValue: String {
            switch storage {
            case .dotAtom(let string), .quoted(let string):
                return string
            }
        }
        
        private enum Storage: Hashable {
            case dotAtom(String)  // Regular unquoted format
            case quoted(String)   // Quoted string format
        }
    }
}

// MARK: - Constants and Validation
extension EmailAddress.RFC5322 {
    private enum Limits {
        static let maxLength = 64  // Max length for local-part
    }
    
    // Address format regex with optional display name
    nonisolated(unsafe) private static let addressRegex = /(?:((?:\".*?\"|[^<]+)\s+))?<(.*?)@(.*?)>/
    
    // Dot-atom regex: series of atoms separated by dots
    // More restrictive than RFC 5321 - no "!" or "|" allowed
    nonisolated(unsafe) private static let dotAtomRegex = /[a-zA-Z0-9#$%&'\*\+\-\/=\?\^_`\{\}~]+(?:\.[a-zA-Z0-9#$%&'\*\+\-\/=\?\^_`\{\}~]+)*/
    
    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) private static let quotedRegex = /(?:[^"\\\r\n]|\\["\\])+/
}

extension EmailAddress.RFC5322 {
    /// The complete email address string, including display name if present
    public var stringValue: String {
        if let name = displayName {
            // Quote the display name if it contains special characters or non-ASCII
            let needsQuoting = name.contains(where: {
                !$0.isLetter && !$0.isNumber && !$0.isWhitespace ||
                $0.asciiValue == nil
            })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            return "\(quotedName) <\(localPart.stringValue)@\(domain.name)>"  // Exactly one space before angle bracket
        }
        return "\(localPart.stringValue)@\(domain.name)"
    }
    
    /// Just the email address part without display name
    public var addressValue: String {
        "\(localPart.stringValue)@\(domain.name)"
    }
    
    /// Convert to RFC 5321 format if possible
    public func toRFC5321() throws -> EmailAddress.RFC5321 {
        try EmailAddress.RFC5321(
            displayName: displayName,
            localPart: .init(localPart.stringValue),
            domain: .init(domain: domain)
        )
    }
}

// MARK: - Errors
extension EmailAddress.RFC5322 {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case missingAtSign
        case invalidDotAtom
        case invalidQuotedString
        case localPartTooLong(_ length: Int)
        case consecutiveDots
        case leadingOrTrailingDot
        
        public var errorDescription: String? {
            switch self {
            case .missingAtSign:
                return "Email address must contain @"
            case .invalidDotAtom:
                return "Invalid local-part format (before @)"
            case .invalidQuotedString:
                return "Invalid quoted string format in local-part"
            case .localPartTooLong(let length):
                return "Local-part length \(length) exceeds maximum of \(Limits.maxLength)"
            case .consecutiveDots:
                return "Local-part cannot contain consecutive dots"
            case .leadingOrTrailingDot:
                return "Local-part cannot begin or end with a dot"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension EmailAddress.RFC5322: CustomStringConvertible {
    public var description: String { stringValue }
}

extension EmailAddress.RFC5322: Codable {
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

extension EmailAddress.RFC5322: RawRepresentable {
    public var rawValue: String { stringValue }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
