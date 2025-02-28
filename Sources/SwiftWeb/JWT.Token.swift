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
        
        public init(
            value: String
        ) {
            self.value = value
        }
        
        public enum CodingKeys: String, CodingKey {
            case value = "token"
        }
        
        public init(stringLiteral value: String) {
            self = .init(value: value)
        }
    }
}

extension JWT.Token {
    public var token: String { value }
}
extension JWT.Token: TestDependencyKey {
    public static let testValue: Self = .init(value: "test")
}
