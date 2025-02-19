//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 19/02/2025.
//

import Foundation

public enum JWT {}

extension JWT {
    public struct Token: Codable, Hashable, Sendable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        public let value: String
        public let type: String?
        public let expiresIn: TimeInterval?
        
        public init(
            value: String,
            type: String? = "Bearer",
            expiresIn: TimeInterval?
        ) {
            self.value = value
            self.type = type
            self.expiresIn = expiresIn
        }
        
        public enum CodingKeys: String, CodingKey {
            case value = "token"
            case type
            case expiresIn = "exp"
        }
        
        public init(stringLiteral value: String) {
            self = .init(value: value, expiresIn: nil)
        }
    }
}

extension JWT.Token: TestDependencyKey {
    public static let testValue: Self = .init(value: "test", expiresIn: 100)
}
