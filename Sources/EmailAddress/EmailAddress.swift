import Foundation
import RegexBuilder

public struct EmailAddress: Codable, Hashable, Sendable {
    /// The display name portion of the email address (optional)
    public let name: String?
    
    /// The local part of the email address (before @)
    public let localPart: String
    
    /// The domain part of the email address (after @)
    public let domain: String
    
    /// Initialize with separate components
    public init(name: String? = nil, localPart: String, domain: String) throws {
        guard Self.isValidLocalPart(localPart) else {
            throw ValidationError.invalidLocalPart
        }
        guard Self.isValidDomain(domain) else {
            throw ValidationError.invalidDomain
        }
        
        self.name = name
        self.localPart = localPart
        self.domain = domain
    }
    
    /// Initialize from a string in format: "Display Name <local@domain>" or "local@domain"
    public init(_ string: String) throws {
        // First try name-addr format: "Name <email@domain>"
        if let match = try? Self.nameAddrRegex.wholeMatch(in: string) {
            let displayName: String?
            if let quotedName = match.output.1 {
                displayName = Self.unquoteString(String(quotedName))
            } else if let plainName = match.output.2 {
                displayName = String(plainName).trimmingCharacters(in: .whitespaces)
            } else {
                displayName = nil
            }
            try self.init(
                name: displayName,
                localPart: String(match.output.3),
                domain: String(match.output.4)
            )
        }
        // Then try addr-spec format: "email@domain"
        else if let match = try? Self.addrSpecRegex.wholeMatch(in: string) {
            try self.init(
                localPart: String(match.output.1),
                domain: String(match.output.2)
            )
        }
        else {
            throw ValidationError.invalidFormat
        }
    }
    
    /// The complete email address without display name
    public var address: String {
        "\(localPart)@\(domain)"
    }
}

// MARK: - Validation
extension EmailAddress {
    /// Maximum lengths according to RFC 5321
    private enum Limits {
        static let maxLocalPartLength = 64
        static let maxDomainLength = 255
        static let maxLabelLength = 63
    }
    
    private static func isValidLocalPart(_ localPart: String) -> Bool {
        guard !localPart.isEmpty,
              localPart.count <= Limits.maxLocalPartLength
        else { return false }
        
        // If quoted, validate according to quoted-string rules
        if localPart.hasPrefix("\"") && localPart.hasSuffix("\"") {
            let quoted = String(localPart.dropFirst().dropLast())
            return (try? quotedLocalPartRegex.wholeMatch(in: quoted)) != nil
        }
        
        // Otherwise validate as dot-atom
        return (try? dotAtomRegex.wholeMatch(in: localPart)) != nil
    }
    
    private static func isValidDomain(_ domain: String) -> Bool {
        guard !domain.isEmpty,
              domain.count <= Limits.maxDomainLength,
              !domain.hasPrefix("-"),
              !domain.hasSuffix("-")
        else { return false }
        
        // Match entire domain pattern
        return (try? domainRegex.wholeMatch(in: domain)) != nil
    }
    
    private static func unquoteString(_ str: String) -> String {
        if str.hasPrefix("\"") && str.hasSuffix("\"") {
            return String(str.dropFirst().dropLast())
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
        }
        return str
    }
}


// MARK: - Regular Expressions
extension EmailAddress {
    // Dot-atom regex: series of atoms separated by dots
    
    nonisolated(unsafe) private static let dotAtomRegex = /[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+)*/

    // Quoted local part regex: allows spaces and special characters
    nonisolated(unsafe) private static let quotedLocalPartRegex = /(?:[^"\\]|\\["\\])+/
    
    // Domain label regex: letters, digits, and hyphens (not at start/end)
    nonisolated(unsafe) private static let domainLabelRegex = /(?:[^\"\\]|\\[\"\\])+/
    
    // Complete domain regex: series of labels separated by dots
    nonisolated(unsafe) private static let domainRegex = /[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?)+/
    
    // Name-addr regex: "Name <local@domain>"
    nonisolated(unsafe) private static let nameAddrRegex = /(?:(?:\"((?:[^\"\\]|\\[\"\\])+)\"|([^<]+))?\s*)?<([a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+)*)@([a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?)+)>/
    
    // Addr-spec regex: "local@domain"
    nonisolated(unsafe) private static let addrSpecRegex = /([a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+)*)@([a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?)+)/
}

// MARK: - Errors
extension EmailAddress {
    public enum ValidationError: Error, LocalizedError {
        case invalidFormat
        case invalidLocalPart
        case invalidDomain
        
        public var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid email format. Expected 'Name <local@domain>' or 'local@domain'"
            case .invalidLocalPart:
                return "Invalid local part (before @)"
            case .invalidDomain:
                return "Invalid domain (after @)"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension EmailAddress: CustomStringConvertible {
    public var description: String {
        if let name = name {
            // Quote the name if it contains special characters
            let needsQuoting = name.contains { !$0.isLetter && !$0.isNumber && $0 != " " }
            let displayName = needsQuoting ? "\"\(name.replacingOccurrences(of: "\"", with: "\\\""))\"" : name
            return "\(displayName) <\(address)>"
        }
        return address
    }
}

extension EmailAddress: RawRepresentable {
    public var rawValue: String {
        description
    }
    
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

// MARK: - Convenience Initializers
extension EmailAddress {
    public static func unnamed(_ address: String) throws -> EmailAddress {
        try EmailAddress(address)
    }
    
    public static func named(_ name: String, _ address: String) throws -> EmailAddress {
        try EmailAddress("\(name) <\(address)>")
    }
}
