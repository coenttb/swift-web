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
    /// RFC 5321 compliant email address (basic SMTP format)
    public struct RFC5321: Hashable, Sendable {
        /// The display name, if present
        public let displayName: String?
        
        /// The local part (before @)
        public let localPart: LocalPart
        
        /// The domain part (after @)
        public let domain: Domain.RFC5321
        
        /// Initialize with components
        public init(displayName: String? = nil, localPart: LocalPart, domain: Domain.RFC5321) {
            self.displayName = displayName
            self.localPart = localPart
            self.domain = domain
        }
        
        /// Initialize from string representation ("Name <local@domain>" or "local@domain")
            public init(_ string: String) throws {
                // Define regex components using Regex builder for more robust parsing
                let displayNameCapture = Regex {
                    Capture {
                        // Either a quoted string or unquoted text not containing angle brackets
                        ChoiceOf {
                            Regex {
                                "\""
                                OneOrMore(.any, .reluctant)
                                "\""
                            }
                            OneOrMore {
                                NegativeLookahead { "<" }
                                CharacterClass.any
                            }
                        }
                        OneOrMore(.whitespace)
                    }
                    
                }
                
                let emailCapture = Regex {
                    "<"
                    Capture {
                        OneOrMore(.reluctant) {
                            NegativeLookahead { "@" }
                            CharacterClass.any
                        }
                    }
                    "@"
                    Capture {
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
                    let captures = match.output
                    
                    // Extract display name if present
                    let displayName = captures.1.map { name in
                        // Remove quotes if present
                        if name.hasPrefix("\"") && name.hasSuffix("\"") {
                            return String(name.dropFirst().dropLast())
                        }
                        return String(name)
                    }
                    
                    let localPart = String(captures.2)
                    let domain = String(captures.3)
                    
                    try self.init(
                        displayName: displayName,
                        localPart: LocalPart(localPart),
                        domain: Domain.RFC5321(domain)
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
                        domain: Domain.RFC5321(domainString)
                    )
                }
            }
    }
}


// MARK: - Local Part
extension EmailAddress.RFC5321 {
    /// RFC 5321 compliant local-part
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
                guard (try? EmailAddress.RFC5321.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle dot-atom format
            else {
                guard (try? EmailAddress.RFC5321.dotAtomRegex.wholeMatch(in: string)) != nil else {
                    throw ValidationError.invalidDotAtom
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
extension EmailAddress.RFC5321 {
    private enum Limits {
        static let maxLength = 64  // Max length for local-part
    }
    
    // Address format regex with optional display name
    nonisolated(unsafe) private static let addressRegex = /(?:(?:\"[^>]+\"|[^<]+)\s+)?<([^@]+)@([^>]+)>/
    
    // Dot-atom regex: series of atoms separated by dots
    nonisolated(unsafe) private static let dotAtomRegex = /[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+)*/
    
    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) private static let quotedRegex = /(?:[^"\\]|\\["\\])+/
}

// MARK: - Properties
extension EmailAddress.RFC5321 {
    /// The complete email address string, including display name if present
    public var stringValue: String {
        if let name = displayName {
            // Quote the display name if it contains special characters
            let needsQuoting = name.contains(where: { !$0.isLetter && !$0.isNumber && !$0.isWhitespace })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            return "\(quotedName) <\(localPart.stringValue)@\(domain.name)>"
        }
        return "\(localPart.stringValue)@\(domain.name)"
    }
    
    /// Just the email address part without display name
    public var addressValue: String {
        "\(localPart.stringValue)@\(domain.name)"
    }
}

// MARK: - Errors
extension EmailAddress.RFC5321 {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case missingAtSign
        case invalidDotAtom
        case invalidQuotedString
        case localPartTooLong(_ length: Int)
        
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
            }
        }
    }
}

// MARK: - Protocol Conformances
extension EmailAddress.RFC5321: CustomStringConvertible {
    public var description: String { stringValue }
}

extension EmailAddress.RFC5321: Codable {
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
            domain: Domain.RFC5321(domainString)
        )
    }
}

extension EmailAddress.RFC5321: RawRepresentable {
    public var rawValue: String { stringValue }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
