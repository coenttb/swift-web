import Foundation
import Parsing
@_exported import UrlFormEncoding

extension Conversion {
    @inlinable
    public static func form<Value>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) -> Self where Self == FormCoding<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }

    @inlinable
    public func form<Value>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) -> Conversions.Map<Self, FormCoding<Value>> {
        self.map(.form(type, decoder: decoder, encoder: encoder))
    }
}

public struct FormCoding<Value: Codable>: Conversion {
    public let decoder: UrlFormDecoder
    public let encoder: JSONEncoder
    
    @inlinable
    public init(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.decoder = decoder
        self.encoder = encoder
    }
    
    @inlinable
    public func apply(_ input: Data) throws -> Value {
        try decoder.decode(Value.self, from: input)
    }
    
    @inlinable
    public func unapply(_ output: Value) -> Data {
        Data(urlFormEncode(value: output, encoder: encoder).utf8)
    }
}

